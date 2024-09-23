import env
import random
import hashlib
from flask import Flask, session, url_for, redirect, Request, request, render_template, abort, send_file
from ucam_webauth.raven.flask_glue import AuthDecorator
from werkzeug.middleware.proxy_fix import ProxyFix
import time

DOMAIN = "raven.intgrah.com"

class R(Request):
    trusted_hosts = {'raven.intgrah.com'}

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_host=1)
app.request_class = R
app.secret_key = env.SECRET_KEY

raven = AuthDecorator(desc="Raven challenge")

@app.route('/')
@app.route('/index.html')
def index():
    return redirect(url_for('challenge'))

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.route('/challenge')
@raven
def challenge():
    challenge = request.args.get("s")

    if challenge is None or not challenge.isalnum():
        challenge = f"{random.randint(1, 999999):06d}"
        return redirect(url_for('challenge') + f'?s={challenge}')

    return render_template('challenge.html', challenge=challenge, answer=get_answer(challenge), link=f'https://{DOMAIN}/challenge?s={challenge}', crsid=raven.principal)

def get_answer(challenge: str):
    m = hashlib.sha256()
    m.update(bytes(challenge + env.CHALLENGE_KEY, 'utf-8'))
    h = m.hexdigest()
    answer = int(h, 16) % 1000000
    return f'{answer:06d}'

app.add_url_rule("/logout", "logout", raven.logout)
