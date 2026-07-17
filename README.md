# StickerStar

Architecture and technical documentation for the StickerStar microservice-based application.

> Project for the Software Architecture Design course at the University of Naples Federico II.

## Overview

StickerStar is designed as a REST microservice system deployed with containers.
The main domain capabilities are:

- Users management
- Sticker catalog management
- Sticker-to-sticker trades

The system is organized around one API Gateway and two domain microservices:

- [`StickerStarAPI`](#stickerstarapi): gateway and orchestration layer
- [`StickerStarUsers`](#stickerstarusers): users and authentication
- [`StickerStarStickers`](#stickerstarstickers): sticker catalog and trade execution

### User Stories And Agile Scope

The architecture supports iterative agile development, where each story can be delivered independently by service:

- As a user, I can register, authenticate, and obtain my profile.
- As a user, I can create and browse stickers.
- As a user, I can retrieve stickers owned by a given user.
- As a user, I can trade one of my stickers for another sticker.

### Functional And Non-Functional Requirements

Functional requirements:

- Expose REST APIs for users, stickers, and trades.
- Centralize client entry point through API Gateway.
- Enforce token-based authentication for protected operations.
- Persist user, sticker, and authentication state in dedicated data stores.

Non-functional requirements:

- Service separation and independent deployability.
- Containerized deployment with reproducible runtime environments.
- Horizontal scalability per service (not implemented).
- Clear API contracts through DTOs and [Swift DocC](https://www.swift.org/documentation/docc/) documentation.
- Fault isolation across service boundaries.

### Component Diagram

```text
	     +--------------------+
	     |    Web / Client    |
	     +---------+----------+
			 |
		   HTTPS REST
			 |
	     +---------v----------+
	     | StickerStarAPI     |
	     | API Gateway        |
	     +----+----------+----+
		   |          |
	   REST to Users   REST to Stickers
		   |          |
      +----------v--+    +--v----------------+
      | StickerStar |    | StickerStar       |
      | Users       |    | Stickers          |
      +------+------+
	      |              +---------+-------+
	      |                        |
      +------v------+          +------v------+
      | PostgreSQL  |          | MySQL       |
      +-------------+          +-------------+
	      |
      +------v------+
      | Redis       |
      +-------------+
```

### Package Diagram

```text
├─ docker-compose.yml
├─ StickerStarAPI
│  ├─ Controllers
│  ├─ DTOs
│  ├─ configure.swift
│  ├─ routes.swift
│  └─ entrypoint.swift
├─ StickerStarUsers
│  ├─ Controllers
│  ├─ Models
│  ├─ DTOs
│  ├─ Migrations
│  ├─ configure.swift
│  ├─ routes.swift
│  └─ entrypoint.swift
└─ StickerStarStickers
   ├─ Controllers
   ├─ Models
   ├─ DTOs
   ├─ Middlewares
   ├─ Migrations
   ├─ configure.swift
   ├─ routes.swift
   └─ entrypoint.swift
```

### Logical Class View

Key logical components and responsibilities:

- Gateway controllers route requests and orchestrate inter-service calls.
- Domain controllers implement business use cases in each microservice.
- Middleware enforces authentication at service boundaries.
- Models represent persisted domain entities.
- DTOs define stable request/response contracts.

### Runtime Components And APIs

Runtime components:

- Gateway runtime (Vapor) exposing public REST endpoints.
- Users runtime (Vapor + PostgreSQL + Redis).
- Stickers runtime (Vapor + MySQL, with remote authentication through Users).

API boundaries:

- Offered APIs: gateway public endpoints for clients, internal service endpoints per microservice.
- Used APIs: gateway invokes Users and Stickers; Stickers invokes Users authentication endpoint.

### Database Usage Across Microservices

The data layer is intentionally polyglot and each store has a clear bounded responsibility:

- PostgreSQL (Users service): system of record for user entities.
	- Stores persistent user profile and credential-related data.
	- Supports relational integrity and transactional updates for user domain operations.
- Redis (Users service): low-latency token store.
	- Stores generated authentication tokens for fast validation.
	- Used on login/authenticate paths to avoid expensive repeated checks against persistent relational data.
	- Works as an operational cache/session-like layer, not as the primary source of truth for user profiles.
- MySQL (Stickers service): system of record for sticker catalog and ownership.
	- Stores sticker metadata and owner identifier used by trade flows.
	- Supports ownership swaps during trade operations as transactional domain updates.

Separation rationale:

- User identity persistence is isolated from sticker catalog persistence.
- Authentication token lifecycle is optimized independently through Redis.
- Each microservice can evolve, scale, and tune its own storage without coupling schema decisions across domains.

### Deployment With Docker Compose

Docker Compose defines all containers, service networking, and environment variables:

- Each microservice runs in its own container.
- Data stores run in dedicated containers.
- Hostnames and ports are injected with environment variables.
- The gateway is exposed to clients and internally reaches domain services.

This setup provides deterministic local development, testability, and deployment parity.

#### Root docker-compose.yml Overview

The root `docker-compose.yml` defines six services:

- `postgres`: PostgreSQL database for `StickerStarUsers`.
- `mysql`: MySQL database for `StickerStarStickers`.
- `redis`: Redis cache/store for authentication tokens in `StickerStarUsers`.
- `sticker-star-users`: Users microservice container.
- `sticker-star-stickers`: Stickers microservice container.
- `sticker-star-api`: API Gateway container exposed on host port `8080`.

Compose dependencies (`depends_on`) define startup order:

- `sticker-star-users` depends on `postgres` and `redis`.
- `sticker-star-stickers` depends on `mysql` and `sticker-star-users`.
- `sticker-star-api` depends on both domain microservices.

Environment variable injection is central to runtime wiring:

- Users service: `DATABASE_HOST=postgres`, `REDIS_HOSTNAME=redis`, `PORT=8081`, `ENVIRONMENT=production`.
- Stickers service: `DATABASE_HOST=mysql`, `AUTH_HOSTNAME=sticker-star-users`, `PORT=8082`, `ENVIRONMENT=production`.
- API service: `USERS_HOSTNAME=sticker-star-users`, `STICKERS_HOSTNAME=sticker-star-stickers`, `PORT=8080`, `ENVIRONMENT=production`.

This means hostnames used in code map directly to Compose service names through the internal Docker network.

#### Microservice Dockerfiles Overview

Each microservice has its own Dockerfile and follows a multi-stage build strategy:

- Build stage (`swift:6.3-noble`): resolves packages, builds release binary, stages executable/resources.
- Runtime stage (`ubuntu:noble`): installs minimal runtime dependencies (`libjemalloc2`, certificates, timezone data), creates non-root `vapor` user, runs the executable.

Common technical choices:

- Static Swift stdlib linking in release build (`--static-swift-stdlib`).
- `jemalloc` for allocator performance (`-Xlinker -ljemalloc`).
- `SWIFT_BACKTRACE` environment for runtime crash diagnostics.

Service-specific startup commands:

- API Gateway Dockerfile starts with `ENTRYPOINT ["./StickerStarAPI"]` and `CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]`.
- Users and Stickers Dockerfiles start with a shell-style `ENTRYPOINT` including `sleep 20` and then launch with `--port $PORT`; this is a practical startup-delay approach to wait for dependent services.

Overall, the deployment architecture combines container isolation with environment-driven service discovery.

# StickerStarAPI

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

# StickerStarUsers

The Users microservice for the StickerStar application, built using Vapor. It manages user-related operations such as registration, authentication, and profile management.

## Overview

This microservice is built with [Vapor](https://vapor.codes) and keeps track of user information through the ``User`` model, made with the [Fluent](https://github.com/vapor/fluent) ORM, and stores it in a **PostgreSQL** database.
It offers endpoints to create new users and obtain information about existing users via the ``UserController``.

It handles user authentication using the ``AuthController``, which provides endpoints for login with basic auth and token-based authentication (see ``Token``).
The generated tokens are stored in **Redis** for quick validation in subsequent requests.

The server gets the port to listen on from the `PORT` environment variable, which is set by Docker Compose when it starts the microservice.
By default, the server listens on port `8081` if the `PORT` environment variable is not set, so as to not conflict with the API Gateway, which listens on port `8080`, and the Stickers microservice, which listens on port `8082` by default.
It also gets Postgres and Redis connection information from environment variables, which are set by Docker Compose when it starts the microservice.

### Architecture Role

This microservice owns the Users bounded context and the authentication subsystem.
In the overall architecture, it provides identity and token validation capabilities used by both the API Gateway and the Stickers service.

### Functional And Non-Functional Requirements

Functional requirements covered by this service:

- User registration and retrieval.
- Basic authentication login.
- Token issuance.
- Token validation endpoint for other services.

Non-functional requirements supported:

- Stateless HTTP processing with external state in PostgreSQL and Redis.
- Fast token checks through Redis lookup.
- Isolation of user data from other microservices.
- Independent deployment and scaling.

### Component Diagram

```text
[API Gateway / Other Services]
				 |
				 | REST
				 v
		[StickerStarUsers]
			|          |
			| SQL      | Key-Value
			v          v
	 [PostgreSQL]  [Redis]
```

### Package Diagram

```text
StickerStarUsers
├─ Controllers
│  ├─ UserController
│  └─ AuthController
├─ Models
│  ├─ User
│  └─ CreateUser
├─ DTOs
│  ├─ UserDTO
│  ├─ Token
│  └─ AuthenticateData
├─ Migrations
├─ Entrypoint
├─ configure(_:)
└─ routes(_:)
```

### Logical Class View

- ``UserController`` implements user CRUD-oriented read/create use cases.
- ``AuthController`` manages login and token-based authentication workflows.
- ``User`` is the persistence model and aggregate root for user data.
- ``Token`` and authentication DTOs define explicit integration contracts with external callers.

### Runtime Components, Offered APIs, And Used APIs

Offered APIs (Users service -> callers):

- `GET /users`
- `POST /users`
- `GET /users/:userID`
- `POST /auth/login`
- `POST /auth/authenticate`

Used runtime dependencies:

- PostgreSQL for persistent user entities.
- Redis for token caching and validation.
- No dependency on other application microservices for core operations.

#### Detailed Database Responsibilities

PostgreSQL responsibilities:

- Primary source of truth for user data.
- Stores user records created by `POST /users`.
- Supports retrieval queries used by `GET /users` and `GET /users/:userID`.
- Used during authentication completion to load user details after token verification.

Redis responsibilities:

- Stores authentication tokens generated by `POST /auth/login`.
- Provides low-latency token lookup in `POST /auth/authenticate`.
- Reduces repeated credential verification and minimizes load on the relational store for auth checks.

Why both stores are used:

- PostgreSQL is optimized for durable relational domain data (users).
- Redis is optimized for fast key-value access (token validation path).
- Combining them provides both consistency for core entities and performance for high-frequency auth operations.

### Deployment With Docker Compose

Container deployment characteristics:

- Service default port: `8081`.
- Runtime configuration provided via environment variables (`PORT`, database settings, Redis settings).
- Isolated data-layer containers (PostgreSQL and Redis) connected over Compose network.

This deployment enables portability, reproducibility, and clear runtime boundaries.

#### Compose Integration

In the root `docker-compose.yml`, `sticker-star-users`:

- Is built from `StickerStarUsers/Dockerfile`.
- Depends on `postgres` and `redis`.
- Receives environment variables:
	- `DATABASE_HOST=postgres`
	- `REDIS_HOSTNAME=redis`
	- `PORT=8081`
	- `ENVIRONMENT=production`

These values connect the service to its database and token store through Compose service names.

#### StickerStarUsers Dockerfile

The Users Dockerfile follows a multi-stage strategy:

- Build stage compiles `StickerStarUsers` in release mode using static Swift stdlib and jemalloc.
- Runtime stage installs minimal runtime packages and executes as non-root `vapor` user.

Startup behavior is defined with an ENTRYPOINT that introduces a short delay and then runs:

- `./StickerStarUsers serve --env production --hostname 0.0.0.0 --port $PORT`

The `sleep 20` in ENTRYPOINT is used as a simple dependency warm-up guard while databases and Redis become reachable.

# StickerStarStickers

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
