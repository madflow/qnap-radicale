from bottle import route, run, template

@route('/')
def index():
    return template('index.html')

run(host='0.0.0.0', port=5000)
