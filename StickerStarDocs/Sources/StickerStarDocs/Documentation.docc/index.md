# ``StickerStarDocs``

Architecture and technical documentation for the StickerStar microservice-based application.

## Overview

StickerStar is designed as a REST microservice system deployed with containers.
The main domain capabilities are:

- Users management
- Sticker catalog management
- Sticker-to-sticker trades

The system is organized around one API Gateway and two domain microservices:

- `StickerStarAPI`: gateway and orchestration layer
- `StickerStarUsers`: users and authentication
- `StickerStarStickers`: sticker catalog and trade execution

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
StickerStarDocs
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

## Topics

### Documentation website

- ``site``
