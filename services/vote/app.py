import os
import socket
import uuid
import json

from flask import Flask, render_template, request, make_response
import redis

app = Flask(__name__)

option_a = os.getenv("OPTION_A", "Cats")
option_b = os.getenv("OPTION_B", "Dogs")
hostname = socket.gethostname()

redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", "6379"))

r = redis.Redis(
    host=redis_host,
    port=redis_port,
    db=0,
    socket_connect_timeout=2,
    socket_timeout=2,
    decode_responses=True,
)


@app.route("/livez")
def livez():
    return "ok", 200


@app.route("/healthz")
def healthz():
    try:
        r.ping()
        return "ok", 200
    except Exception as e:
        return f"redis not ready: {e}", 503


@app.route("/", methods=["GET", "POST"])
def index():
    #  sStable unique id per browser via cookie
    voter_id = request.cookies.get("voter_id")
    if not voter_id:
        voter_id = str(uuid.uuid4())

    if request.method == "POST":
        vote = request.form.get("vote")
        if vote not in ("a", "b"):
            return make_response("invalid vote", 400)

        # IMPORTANT: the .NET worker expects JSON from Redis
        payload = json.dumps({"voter_id": voter_id, "vote": vote})

        try:
            r.rpush("votes", payload)
        except Exception as e:
            return make_response(f"error writing vote: {e}", 503)

        resp = make_response(render_template(
            "index.html",
            option_a=option_a,
            option_b=option_b,
            hostname=hostname,
            vote=vote
        ))
        resp.set_cookie("voter_id", voter_id)
        return resp

    resp = make_response(render_template(
        "index.html",
        option_a=option_a,
        option_b=option_b,
        hostname=hostname,
        vote=None
    ))
    resp.set_cookie("voter_id", voter_id)
    return resp


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
