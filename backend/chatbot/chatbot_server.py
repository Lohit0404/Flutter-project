from flask import Flask, request, jsonify
from logic import get_bot_response

app = Flask(__name__)

@app.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get('message', '')
    response = get_bot_response(user_message)
    return jsonify({'response': response})

if __name__ == '__main__':
    app.run(port=8000)
