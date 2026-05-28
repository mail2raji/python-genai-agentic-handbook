# Mini-Project — Weather Chatbot

!!! info "Runnable source file"
    **Path:** `Phase2_Intermediate_Python/mini_project_weather_chatbot.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
🏆 PHASE 2 MINI-PROJECT — Weather Chatbot
==========================================

A class-based "chatbot" that uses a real public API.
This is the architectural shape we'll later use for an LLM-powered bot.

📦 INSTALL:  pip install requests

Tries Open-Meteo (no API key needed). Falls back to mock data if offline.
"""

from __future__ import annotations
import requests
from dataclasses import dataclass, field


@dataclass
class WeatherTool:
    """A tool the chatbot can call."""
    base_url: str = "https://api.open-meteo.com/v1/forecast"

    def get_current(self, lat: float, lon: float) -> dict:
        try:
            r = requests.get(
                self.base_url,
                params={"latitude": lat, "longitude": lon, "current_weather": "true"},
                timeout=10,
            )
            r.raise_for_status()
            return r.json().get("current_weather", {})
        except requests.exceptions.RequestException as e:
            print(f"(offline mode — {e})")
            return {"temperature": 22.0, "windspeed": 5.0, "weathercode": 0}


# A tiny city → coordinates lookup
CITIES = {
    "london":   (51.5074, -0.1278),
    "redmond":  (47.6740, -122.1215),
    "mumbai":   (19.0760, 72.8777),
    "tokyo":    (35.6762, 139.6503),
    "sydney":   (-33.8688, 151.2093),
}


@dataclass
class WeatherChatbot:
    name: str = "WeatherBot"
    tool: WeatherTool = field(default_factory=WeatherTool)
    history: list[dict] = field(default_factory=list)

    def respond(self, user_input: str) -> str:
        self.history.append({"role": "user", "content": user_input})

        # Tiny "intent detection" — in Phase 4 an LLM will do this.
        city_key = next((c for c in CITIES if c in user_input.lower()), None)
        if not city_key:
            reply = (
                f"I can check weather for: {', '.join(CITIES)}.\n"
                "Try: 'What's the weather in London?'"
            )
        else:
            lat, lon = CITIES[city_key]
            data = self.tool.get_current(lat, lon)
            reply = (
                f"In {city_key.title()}: {data['temperature']}°C, "
                f"wind {data['windspeed']} km/h."
            )

        self.history.append({"role": "assistant", "content": reply})
        return reply


def main():
    bot = WeatherChatbot()
    print(f"🤖 {bot.name} ready. Type 'quit' to exit.\n")
    while True:
        try:
            user = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not user or user.lower() in {"quit", "exit"}:
            print(f"{bot.name}: Goodbye!")
            break
        print(f"{bot.name}: {bot.respond(user)}")


if __name__ == "__main__":
    main()


# ============================================================
# 🎓 EXTENSIONS:
#   1. Add more cities.
#   2. Add a CommandTool that lets the user say "history" to print past messages.
#   3. Save chat history to a JSON file on exit.
#   4. In Phase 4 — swap the rule-based intent detection for an LLM call.
# ============================================================

```
