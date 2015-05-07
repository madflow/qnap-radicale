from bottle import Bottle, run, template, static_file, request
import daemon
import os
import ConfigParser

WEB_DIR = os.path.dirname(os.path.realpath(__file__))
CONFIG_DIR = os.path.realpath(os.path.join(WEB_DIR,'../config')
                             )
app = Bottle()

config = ConfigParser.SafeConfigParser()
config.read(os.path.join(CONFIG_DIR, 'radicale.conf'))

@app.route('/')
def index():
    return template('index.html', config=config)

@app.post('/')
def save():
    config.set('server', 'hosts', request.forms.get('radicale_server_hosts'))
    config.set('server', 'ssl', str(request.forms.get('radicale_server_ssl')))
    config.set('server', 'certificate', request.forms.get('radicale_server_certificate'))
    config.set('server', 'key', request.forms.get('radicale_server_key'))
    config.set('server', 'dns_lookup', str(request.forms.get('radicale_server_dns_lookup')))
    config.set('server', 'realm', request.forms.get('radicale_server_realm'))

    config.set('encoding', 'request', request.forms.get('radicale_server_encoding_request'))
    config.set('encoding', 'stock', request.forms.get('radicale_server_encoding_stock'))

    with open(os.path.join(CONFIG_DIR, 'new.conf'), 'wb') as configfile:
        config.write(configfile)

    return template('index.html', config=config)

def main():
    run(app, host='0.0.0.0', port=5000, debug=True, use_reloader=True)

@app.route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root=os.path.join(WEB_DIR, 'static'))

if __name__ == "__main__":
    main()
    #with daemon.DaemonContext(working_directory=WEB_DIR):
    #    main()
