#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="radicale"
QPKG_DIR=
QPKG_BASE=
PYTHON_27=/usr/bin/python2.7

RETVAL=0
RUNDIR=/var/run/$QPKG_NAME
PIDFILE=$RUNDIR/$QPKG_NAME.pid
SSL_KEY="/etc/ssl/private/myhost.key"
SSL_CERT="/etc/ssl/certs/myhost.crt"

RADICALE_OPTS="--daemon --pid $PIDFILE"

# :S Copy Paste from some other qpkg
find_base(){
    # Determine BASE installation location according to smb.conf
    publicdir=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`
    if [ ! -z $publicdir ] && [ -d $publicdir ];then
            publicdirp1=`/bin/echo $publicdir | /bin/cut -d "/" -f 2`
            publicdirp2=`/bin/echo $publicdir | /bin/cut -d "/" -f 3`
            publicdirp3=`/bin/echo $publicdir | /bin/cut -d "/" -f 4`
            if [ ! -z $publicdirp1 ] && [ ! -z $publicdirp2 ] && [ ! -z $publicdirp3 ]; then
                    [ -d "/${publicdirp1}/${publicdirp2}/Public" ] && QPKG_BASE="/${publicdirp1}/${publicdirp2}"
            fi
    fi

    # Determine BASE installation location by checking where the Public folder is.
    if [ -z $QPKG_BASE ]; then
            for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA /share/HDD_DATA /share/MD0_DATA /share/MD1_DATA; do
              [ -d $datadirtest/Public ] && QPKG_BASE="$datadirtest"
            done
    fi
    if [ -z $QPKG_BASE ] ; then
            echo "The Public share not found."
            exit 1
    fi
    QPKG_DIR=${QPKG_BASE}/.qpkg/${QPKG_NAME}
}

check_enabled() {

    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME is disabled."
        exit 1
    fi
}

setup() {

    [ -f $QPKG_DIR/config/radicale.conf ] || cp $QPKG_DIR/config/dist/radicale.conf.dist $QPKG_DIR/config/radicale.conf
    [ -f $QPKG_DIR/config/logging ] || cp $QPKG_DIR/config/dist/logging.dist $QPKG_DIR/config/logging
    [ -f $QPKG_DIR/config/rights ] || cp $QPKG_DIR/config/dist/rights.dist $QPKG_DIR/config/rights
    [ -f $QPKG_DIR/config/users ] || cp $QPKG_DIR/config/dist/users.dist $QPKG_DIR/config/users

    sed -i -e 's|{{QPKG_DIR}}|'"$QPKG_DIR"'|g' $QPKG_DIR/config/radicale.conf
    sed -i -e 's|{{SSL_KEY}}|'"$SSL_KEY"'|g' $QPKG_DIR/config/radicale.conf
    sed -i -e 's|{{SSL_CERT}}|'"$SSL_CERT"'|g' $QPKG_DIR/config/radicale.conf
    sed -i -e 's|{{QPKG_DIR}}|'"$QPKG_DIR"'|g' $QPKG_DIR/config/logging
}

start_radicale() {
    check_enabled
    echo "Starting $QPKG_NAME"
    find_base
    setup
    # Set Python Path
    export PYTHONPATH=$QPKG_DIR/lib/radicale
    [ -d $RUNDIR ] || mkdir -p $RUNDIR
    ${PYTHON_27} $QPKG_DIR/lib/radicale/bin/radicale $RADICALE_OPTS -C $QPKG_DIR/config/radicale.conf
    RETVAL=$?
}

start_web() {
    check_enabled
    # Set Python Path
    export PYTHONPATH=$QPKG_DIR/lib/bottle:$QPKG_DIR/lib/daemon
    ${PYTHON_27} $QPKG_DIR/web/app.py
    RETVAL=$?
}

stop_radicale() {
    if [ ! -f $PIDFILE ]; then
        echo "No PID file found"
        return
    fi
    echo "Shutting down ${QPKG_NAME}... "
    kill -9 $(cat $PIDFILE)
    rm $PIDFILE
    sleep 2
}

check_for_git(){ #clinton.hall Sickbeard
    /bin/echo -n " Checking for git..."
    if [ ! -f /Apps/bin/git ]; then
        if [ -x /etc/init.d/git.sh ]; then
            /bin/echo "  Starting git..."
            /etc/init.d/git.sh start
            sleep 2
        else #catch all
            /bin/echo "  No git qpkg found, please install it"
            /sbin/write_log "Failed to start $QPKG_NAME, no git found." 1
            exit 1
        fi
    else
        /bin/echo "  Found!"
    fi
}


case "$1" in
  start)
    start_radicale
    start_web
    ;;

  stop)
    stop_radicale
    ;;

  restart_radicale)
    stop_radicale
    start_radicale
    ;;

  restart)
    $0 stop
    $0 start
    RETVAL=$?
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $RETVAL
