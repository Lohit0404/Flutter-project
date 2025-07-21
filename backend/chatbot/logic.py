import requests

def get_bot_response(message: str) -> str:
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "llama3.1",  #
                "prompt": message,
                "stream": False
            }
        )
        data = response.json()
        return data.get("response", "Sorry, I didn't get that.")
    except Exception as e:
        print("Error contacting LLaMA:", e)
        return "Oops! Something went wrong talking to the AI model."
