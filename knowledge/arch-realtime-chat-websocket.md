# Real-Time Chat & WebSocket Architectures

Building a high-load chat server (like `ballon-dor-chat` or `chat-bot-backend`) requires moving beyond standard HTTP requests into full-duplex WebSocket connections and Pub/Sub pipelines.

## 1. The Message Pipeline
A scalable chat server is a data pipeline, not just a relay.
- **Ingress:** WebSockets handle incoming connections. 
- **Rate Limiting:** Implement Token Bucket algorithms at the entry point to prevent spam (e.g., shadow-ban if >3 msgs/sec).
- **Moderation:** Synchronous or asynchronous profanity filtering before a message is broadcast.
- **Broadcasting:** Messages are pushed to a Message Broker.

## 2. Pub/Sub and Brokers (STOMP)
- **Topics vs Queues:** Use `/topic` channels for public broadcasting (one-to-many, e.g., a match stream chat) and `/queue` channels for private, one-to-one messaging.
- **In-Memory vs External:** In-Memory brokers are fast but stateful. For horizontal scaling (multiple chat servers), an external broker like RabbitMQ or Redis Pub/Sub is mandatory to synchronize messages across nodes.

## 3. Database Persistence Strategy
Writing every chat message directly to a relational DB (PostgreSQL) in real-time will cause a bottleneck (DB murder).
- **Write-Behind Caching:** Cache incoming messages in memory or Redis.
- **Batch Inserts:** A background worker flushes messages to the DB in batches (e.g., every 5 seconds) using optimized `PreparedStatement` execution.

## 4. Observability and Asynchronous Logging
- Use asynchronous loggers (like Log4j2 with LMAX Disruptor) so that writing logs to disk (I/O) does not block the WebSocket Event Loop.
- Log connection drops, socket errors, and message metrics for analytics.
