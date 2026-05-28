# Lesson 4 — Classes

!!! info "Runnable source file"
    **Path:** `Phase2_Intermediate_Python/04_classes.py`  
    **Phase:** Phase 2 — Intermediate Python  
    Copy this into a `.py` file (or clone the [companion repo](https://github.com/mail2raji/python-genai-agentic-handbook)) and run it locally.

```python
"""
Lesson 4: Classes & OOP
========================

📖 CONCEPT:
A class is a blueprint for creating objects that bundle data + behavior.
Every modern AI framework (LangChain, LlamaIndex, AutoGen) is class-based.

💡 REAL-WORLD ANALOGY:
A class is a cookie cutter, an object is the cookie.
All cookies share the same shape (methods) but can have different toppings (data).
"""

# --- A simple class ---
class ChatMessage:
    """Represents one message in a conversation."""

    def __init__(self, role: str, content: str):
        # __init__ runs when you create an object: ChatMessage(...)
        self.role = role
        self.content = content

    def __repr__(self):
        # How the object prints
        return f"<{self.role}: {self.content[:30]}>"


msg = ChatMessage("user", "What is RAG?")
print(msg)
print(msg.role, "→", msg.content)


# --- A bigger class: a simple Chatbot ---
class Chatbot:
    """A mock chatbot. In Phase 4 we'll connect it to a real LLM."""

    def __init__(self, name: str, system_prompt: str):
        self.name = name
        self.system_prompt = system_prompt
        self.history = [ChatMessage("system", system_prompt)]

    def ask(self, user_input: str) -> str:
        """Send a user message and get a (mocked) reply."""
        self.history.append(ChatMessage("user", user_input))
        reply = self._fake_llm(user_input)
        self.history.append(ChatMessage("assistant", reply))
        return reply

    def _fake_llm(self, prompt: str) -> str:
        # Leading underscore = "private" by convention
        return f"[{self.name}] I heard you say: '{prompt}'"

    def show_history(self):
        for m in self.history:
            print(m)


bot = Chatbot(name="ITBot", system_prompt="You are a helpful IT assistant.")
print(bot.ask("My laptop is slow."))
print(bot.ask("How do I reset my password?"))
print("\n--- History ---")
bot.show_history()


# --- Inheritance: build on top of an existing class ---
class LoggingChatbot(Chatbot):
    """A chatbot that also writes every conversation to a log."""

    def ask(self, user_input: str) -> str:
        print(f"📝 LOG: user said '{user_input}'")
        reply = super().ask(user_input)        # call parent's method
        print(f"📝 LOG: bot replied '{reply}'")
        return reply


smart_bot = LoggingChatbot("SmartBot", "You are a witty assistant.")
smart_bot.ask("Tell me a joke")


# ============================================================
# ✏️ EXERCISE:
# Create a class `Tool` representing an agent tool:
#   - attributes: name, description, function (a callable)
#   - method: `run(*args, **kwargs)` that calls the function
# Then create 2 tools (e.g., add_numbers, greet) and call them.
# ============================================================


# ✅ SOLUTION SKETCH:
# class Tool:
#     def __init__(self, name, description, function):
#         self.name = name
#         self.description = description
#         self.function = function
#     def run(self, *args, **kwargs):
#         return self.function(*args, **kwargs)
#
# add_tool = Tool("add", "Adds two numbers", lambda a, b: a + b)
# print(add_tool.run(3, 4))

```
