# Telegram Bot Architectures

When designing production-ready Telegram bots, a structured architecture is critical to avoid "spaghetti code" inside a single event loop. Based on projects like `football-bot-tg` (Java) and `chat-naturalov-bot` (Python/Aiogram), here are the key architectural patterns:

## 1. Update Routing (Dispatcher)
Instead of handling all incoming messages in one place, use a centralized Dispatcher.
- Every `Update` (message, callback query) is intercepted by the Dispatcher.
- The Dispatcher checks the user's current context (e.g., from an In-Memory Cache or Redis).
- If the user is in an `IDLE` state, the update is parsed as a Command (e.g., `/start`, `/help`) and routed to the corresponding Command Handler.
- If the user is in an active state, the update is routed to the State Handler.

## 2. Finite State Machine (FSM)
For complex, multi-step dialogs (e.g., registering a team, answering a questionnaire), FSM is mandatory.
- **States:** Define specific steps (e.g., `WAITING_FOR_NAME`, `WAITING_FOR_PHOTO`).
- **Storage:** Use memory storage for small bots, but Redis for distributed or highly available bots.
- **Flow:** When a step completes, the state transitions, and the data is accumulated in the FSM context. At the final step, a batch insert to the Database occurs.

## 3. Middleware Pattern
Middlewares intercept updates before they reach the handlers. This is essential for:
- **Anti-Spam/Rate Limiting:** Dropping updates if a user sends >5 messages per second (preventing bot crashes).
- **Database Sessions:** Automatically opening and closing DB connections (or sessions) for each update.
- **Authentication/Authorization:** Verifying if a user is an Admin or has a Premium subscription before allowing the command to execute.

## 4. Storage and Caching
- **Database:** SQLite is sufficient for single-chat or small bots (<10k users) as it eliminates network latency. For scalable, high-load bots with relational mechanics (RPG, Gacha, Economics), PostgreSQL is required.
- **Connection Pools:** Use HikariCP or similar tools to manage DB connections efficiently.
