from bottle import Bottle, run, template, static_file, request
import daemon
import os
import ConfigParser
import subprocess, threading

WEB_DIR = os.path.dirname(os.path.realpath(__file__))
CONFIG_DIR = os.path.realpath(os.path.join(WEB_DIR, '../config'))
SHARED_DIR = os.path.realpath(os.path.join(WEB_DIR, '../'))

app = Bottle()


class Command(object):
    def __init__(self, cmd):
        self.cmd = cmd
        self.process = None

    def run(self, timeout):
        def target():
            print 'Thread started'
            self.process = subprocess.Popen(self.cmd, shell=True)
            self.process.communicate()
            print 'Thread finished'

        thread = threading.Thread(target=target)
        thread.start()

        thread.join(timeout)
        if thread.is_alive():
            print 'Terminating process'
            self.process.terminate()
            thread.join()
        print self.process.returncode


@app.route('/')
def index():
    messages = []

    config = ConfigParser.SafeConfigParser()
    files = config.read(os.path.join(CONFIG_DIR, 'radicale.conf'))

    if len(files) == 0:
        messages.append(('Configuration file could not be opened.', 'alert'))
        return template('error.html', messages=messages)

    return template('index.html', config=config, messages=messages)


@app.post('/')
def save():
    messages = []
    config = ConfigParser.SafeConfigParser()
    files = config.read(os.path.join(CONFIG_DIR, 'radicale.conf'))

    if len(files) == 0:
        messages.append(('Configuration file could not be opened.', 'alert'))
        return template('error.html', messages=messages)

    config.set('server', 'hosts', request.forms.get('radicale_server_hosts'))
    config.set('server', 'ssl', str(request.forms.get('radicale_server_ssl', False)))
    config.set('server', 'certificate', request.forms.get('radicale_server_certificate'))
    config.set('server', 'key', request.forms.get('radicale_server_key'))
    config.set('server', 'dns_lookup', str(request.forms.get('radicale_server_dns_lookup', False)))
    config.set('server', 'realm', request.forms.get('radicale_server_realm'))

    config.set('encoding', 'request', request.forms.get('radicale_server_encoding_request'))
    config.set('encoding', 'stock', request.forms.get('radicale_server_encoding_stock'))

    config.set('auth', 'htpasswd_filename', request.forms.get('radicale_auth_htpasswd_filename'))

    config.set('rights', 'file', request.forms.get('radicale_rights_file'))

    config.set('storage', 'filesystem_folder', request.forms.get('radicale_storage_filesystem_folder'))

    try:
        with open(os.path.join(CONFIG_DIR, 'radicale.conf'), 'wb') as configfile:
            config.write(configfile)
    except:
        messages.append(('Could not save the configuration file', 'alert'))

    # Restarting Radicale
    try:
        command = Command(os.path.join(SHARED_DIR, 'radicale.sh') + ' restart_radicale')
        command.run(5)
        messages.append(('Radicale restarted', 'success'))
    except:
        messages.append(('Restart Failed', 'alert'))

    return template('index.html', config=config, messages=messages)


def main():
    run(app, host='0.0.0.0', port=5000, debug=False, use_reloader=False)


@app.route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root=os.path.join(WEB_DIR, 'static'))


if __name__ == "__main__":
    # main()
    with daemon.DaemonContext(working_directory=WEB_DIR):
        main()
