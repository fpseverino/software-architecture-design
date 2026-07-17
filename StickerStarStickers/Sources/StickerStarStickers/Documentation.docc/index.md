# ``StickerStarStickers``

The Stickers microservice for the StickerStar application, built using Vapor. It manages sticker-related operations such as creation, retrieval, and trade.

## Overview

This microservice is built with [Vapor](https://vapor.codes) and keeps track of sticker information through the ``Sticker`` model, made with the [Fluent](https://github.com/vapor/fluent) ORM, and stores it in a **MySQL** database.
It offers endpoints to create new stickers, obtain information about existing ones and trade them with other users via the ``StickerController``.

It handles user authentication using the ``UserAuthMiddleware``, which validates the authentication token provided by the Users microservice for each request that requires authentication by sending a request to the Users microservice to verify the token.
The middleware gets the hostname of the Users microservice from the controller, which in turn gets it from the `AUTH_HOSTNAME` environment variable, which is set by Docker Compose when it starts the microservice.

The server gets the port to listen on from the `PORT` environment variable, which is set by Docker Compose when it starts the microservice.
By default, the server listens on port `8082` if the `PORT` environment variable is not set, so as to not conflict with the API Gateway, which listens on port `8080`, and the Users microservice, which listens on port `8081` by default.
It also gets MySQL connection information from environment variables, which are set by Docker Compose when it starts the microservice.

### Architecture Role

This microservice owns the sticker catalog bounded context and trade execution logic.
It is responsible for sticker lifecycle operations and ownership exchange between users.

In the global architecture, it collaborates with Users for authentication checks through ``UserAuthMiddleware``.

### Functional And Non-Functional Requirements

Functional requirements covered by this service:

- Create, read, update, and delete stickers.
- Query stickers owned by a specific user.
- Execute sticker-to-sticker trade transactions.
- Enforce authenticated access for state-changing operations.

Non-functional requirements supported:

- Data ownership isolation in a dedicated MySQL schema.
- Service-level authentication enforcement through middleware.
- Independent release and scaling profile.
- Clear API contracts with DTOs.

### Component Diagram

```text
[API Gateway / Clients]
			 |
			 | REST
			 v
 [StickerStarStickers]
		|           |
		| SQL       | REST auth check
		v           v
	[MySQL]   [StickerStarUsers /auth/authenticate]
```

### Package Diagram

```text
StickerStarStickers
├─ Controllers
│  └─ StickerController
├─ Models
│  ├─ Sticker
│  └─ CreateSticker
├─ DTOs
│  ├─ StickerDTO
│  ├─ StickerData
│  ├─ TradeData
│  ├─ User
│  └─ AuthenticateData
├─ Middlewares
│  └─ UserAuthMiddleware
├─ Migrations
├─ Entrypoint
├─ configure(_:)
└─ routes(_:)
```

### Logical Class View

- ``StickerController`` encapsulates sticker use cases and trade transaction flow.
- ``UserAuthMiddleware`` centralizes token validation by calling Users authentication API.
- ``Sticker`` represents persisted catalog entities.
- ``TradeData`` models ownership exchange requests.

### Runtime Components, Offered APIs, And Used APIs

Offered APIs (Stickers service -> callers):

- `GET /`
- `GET /:stickerID`
- `GET /user/:userID`
- `POST /` (authenticated)
- `PUT /:stickerID` (authenticated)
- `DELETE /:stickerID` (authenticated)
- `POST /trade` (authenticated)

Used APIs and dependencies:

- Users service endpoint `POST /auth/authenticate` for token validation.
- MySQL for sticker persistence.

#### Detailed Database Responsibilities

MySQL responsibilities:

- Primary source of truth for sticker entities and ownership relations.
- Stores sticker lifecycle state for create, read, update, and delete operations.
- Persists ownership updates executed by trade operations.

Data model boundary:

- The service stores the owner identifier (`userID`) on stickers but does not store or replicate full user profile data.
- User identity validation is delegated to the Users service through `UserAuthMiddleware`.

Why this split is important:

- Catalog consistency and trade logic remain local to the Stickers database.
- Authentication and token lifecycle remain centralized in the Users service (PostgreSQL + Redis).
- Service boundaries stay explicit, reducing cross-domain data coupling.

### Deployment With Docker Compose

Container deployment characteristics:

- Service default port: `8082`.
- Runtime configuration provided via environment variables (`PORT`, `AUTH_HOSTNAME`, MySQL settings).
- MySQL runs as a dedicated data container connected on the same Compose network.

This design keeps the service independently deployable while still enabling secure cross-service authentication.

#### Compose Integration

In the root `docker-compose.yml`, `sticker-star-stickers`:

- Is built from `StickerStarStickers/Dockerfile`.
- Depends on `mysql` and `sticker-star-users`.
- Receives environment variables:
	- `DATABASE_HOST=mysql`
	- `AUTH_HOSTNAME=sticker-star-users`
	- `PORT=8082`
	- `ENVIRONMENT=production`

This configuration enables database connectivity and cross-service authentication calls.

#### StickerStarStickers Dockerfile

The Stickers Dockerfile also uses two stages:

- Build stage compiles `StickerStarStickers` in release mode (static Swift stdlib, jemalloc enabled).
- Runtime stage runs with essential runtime libraries under non-root `vapor` user.

Startup behavior is defined with an ENTRYPOINT that waits briefly and then runs:

- `./StickerStarStickers serve --env production --hostname 0.0.0.0 --port $PORT`

The `sleep 20` delay is a pragmatic startup ordering safeguard while dependent services initialize.

## Topics

### Models

- ``Sticker``
- ``CreateSticker``

### DTOs

- ``StickerDTO``
- ``StickerData``
- ``TradeData``
- ``User``
- ``AuthenticateData``

### Controllers

- ``StickerController``

### Middleware

- ``UserAuthMiddleware``

### Application

- ``Entrypoint``
- ``configure(_:)``
- ``routes(_:)``
