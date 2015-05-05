from bottle import Bottle, run, template, route, static_file
import daemon
import os

WEB_DIR = os.path.dirname(os.path.realpath(__file__))

app = Bottle()

@app.route('/')
def index():
    return template('index.html')

def main():
    run(app, host='0.0.0.0', port=5000, debug=True, use_reloader=True)

@app.route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root=os.path.join(WEB_DIR, 'static'))

if __name__ == "__main__":
    main()
    #with daemon.DaemonContext(working_directory=WEB_DIR):
    #    main()
