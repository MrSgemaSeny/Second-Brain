# WebSockets STOMP Setup with JWT

## Overview
Real-time communication (chat, notifications) is implemented using WebSockets over the STOMP protocol, with SockJS as a fallback.

## Implementation Highlights
- **Connection Authentication**: The STOMP client passes the JWT during connection initialization for authentication.
- **Topic Isolation**: Users subscribe to specific channels (e.g., `/topic/chat/{userId}`). The backend enforces authorization at the topic level so users can only access their own channels, preventing eavesdropping.
- **Resource Management**: Subscriptions are established in the components that need real-time data and are actively cancelled when the component unmounts to prevent memory leaks.
