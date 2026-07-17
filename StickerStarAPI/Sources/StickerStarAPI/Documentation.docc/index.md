# ``StickerStarAPI``

The API Gateway for the StickerStar application, built using Vapor. It serves as a single entry point for clients, routing requests to the appropriate microservices (Users and Stickers) and aggregating responses.

## Overview

This microservice is built with [Vapor](https://vapor.codes) and acts as a gateway for the StickerStar application, routing requests to the appropriate microservices (Users and Stickers) and aggregating responses.

It handles user authentication by validating the authentication token provided by the Users microservice for each request that requires authentication by sending a request to the Users microservice to verify the token.

### Architecture Role

This service implements the API Gateway pattern for a REST microservices deployment in containers.
It decouples clients from internal service topology and provides a unified contract for:

- User operations
- Sticker catalog operations
- Trade execution between stickers
- Cross-service composition (for example, resolving sticker owner details)

### Functional And Non-Functional Requirements

Functional requirements covered by the gateway:

- Centralized public API endpoint.
- Routing of client requests to Users and Stickers services.
- Header and payload forwarding for authenticated commands.
- Response relay and simple orchestration logic.

Non-functional requirements supported:

- Separation of concerns between edge API and domain services.
- Independent scaling of gateway and backend microservices (not implemented).
- Technology and deployment isolation by container.
- Easier evolution through versioned gateway endpoints (currently possible, but not fully implemented).

### Component Diagram

```text
[Web Client]
		 |
		 | HTTPS REST /api/*
		 v
[StickerStarAPI Gateway]
	|                  |
	| REST             | REST
	v                  v
[StickerStarUsers] [StickerStarStickers]
```

### Package Diagram

```text
StickerStarAPI
├─ Controllers
│  ├─ UserController
│  └─ StickerController
├─ DTOs
│  ├─ CreateUserData
│  ├─ CreateStickerData
│  ├─ TradeData
│  └─ Sticker
├─ Entrypoint
├─ configure(_:)
└─ routes(_:)
```

### Logical Class View

The logical view is intentionally thin:

- ``UserController`` handles user-centric gateway routes and proxies calls to Users and Stickers.
- ``StickerController`` handles sticker-centric gateway routes and orchestrates Users + Stickers for composite operations.
- DTOs are boundary objects that stabilize the gateway contract with clients and downstream services.

### Runtime Components, Offered APIs, And Used APIs

Offered public APIs (Gateway -> Client):

- `GET /api/users`
- `GET /api/users/:userID`
- `POST /api/users`
- `POST /api/users/login`
- `GET /api/users/:userID/stickers`
- `GET /api/stickers`
- `GET /api/stickers/:stickerID`
- `POST /api/stickers`
- `PUT /api/stickers/:stickerID`
- `DELETE /api/stickers/:stickerID`
- `GET /api/stickers/:stickerID/user`
- `POST /api/stickers/trade`

Used internal APIs (Gateway -> Microservices):

- Users service: `/users`, `/users/:id`, `/auth/login`
- Stickers service: `/`, `/:id`, `/user/:userID`, `/trade`
- Users service is also queried by the gateway during owner resolution flows.

Database usage in this service:

- The API Gateway does not own a database and does not persist domain data locally.
- All persistent state is delegated to downstream services (Users -> PostgreSQL and Redis, Stickers -> MySQL).
- This keeps the gateway stateless and simplifies horizontal scaling, because requests can be routed to any gateway instance without session affinity.

### Deployment With Docker Compose

The gateway runs as a dedicated container and receives service discovery settings from environment variables:

- `USERS_HOSTNAME` for Users service discovery.
- `STICKERS_HOSTNAME` for Stickers service discovery.
- Default internal target ports: `8081` (Users), `8082` (Stickers).

Containerized deployment ensures reproducible networking and easy replacement of service instances.

#### Compose Integration

In the root `docker-compose.yml`, the `sticker-star-api` service:

- Is built from `StickerStarAPI/Dockerfile`.
- Depends on `sticker-star-users` and `sticker-star-stickers`.
- Publishes `8080:8080`, making the gateway the external entry point.
- Receives `USERS_HOSTNAME=sticker-star-users` and `STICKERS_HOSTNAME=sticker-star-stickers`, which are consumed by ``routes(_:)`` to build internal service URLs.

#### StickerStarAPI Dockerfile

The API Dockerfile is a two-stage image definition:

- Build stage (`swift:6.3-noble`): resolves Swift dependencies and builds `StickerStarAPI` in release mode with static Swift runtime and jemalloc.
- Runtime stage (`ubuntu:noble`): installs minimal runtime packages and runs as non-root user `vapor`.

Runtime command model:

- `ENTRYPOINT ["./StickerStarAPI"]`
- `CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]`

This split keeps runtime images lean while preserving deterministic build behavior.

## Topics

### DTOs

- ``CreateUserData``
- ``Sticker``
- ``CreateStickerData``
- ``TradeData``

### Controllers

- ``UserController``
- ``StickerController``

### Application

- ``Entrypoint``
- ``configure(_:)``
- ``routes(_:)``
