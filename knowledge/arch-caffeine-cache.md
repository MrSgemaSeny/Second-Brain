# Caffeine Cache Per-Region Policy

## Overview
In-memory caching is implemented using `Caffeine` to reduce database load and improve response times for frequently accessed data.

## Implementation Details
- **Per-Region Caching**: Caches are divided into logical regions (e.g., `pipelines` for CRM, `documents` for templates). 
- **Configuration**: Each region (`CacheConfig`) defines its own rules for maximum size, expiration time (TTL), and eviction policies.
- **Benefits**: Caffeine provides high performance with low overhead and seamless Spring integration. Since the application currently operates as a single-instance deployment, this local caching strategy is preferred over distributed caches like Redis, eliminating serialization overhead and infrastructure complexity.
