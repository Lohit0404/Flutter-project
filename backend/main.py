# main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import openai
import os

app = FastAPI()

# CORS config to allow requests from mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow from any origin (change to specific IP for security)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = openai.OpenAI(api_key="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")

@app.post("/chat")
async def chat(request: Request):
    data = await request.json()
    message = data.get("message", "")

    if not message:
        return {"response": "No message received."}

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": message}],
        )
        bot_reply = response.choices[0].message.content
        return {"response": bot_reply}

    except Exception as e:
        return {"response": f"❌ Error: {str(e)}"}
