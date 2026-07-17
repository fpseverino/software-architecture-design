import Kiln

/// The main entry point for the StickerStar documentation site.
let site = KilnSite(
    name: "StickerStar",
    url: "https://fpseverino.github.io",
    author: "Francesco Paolo Severino",
    description: "Documentation for the StickerStar microservice-based application, a project for the Software Architecture Design course at the University of Naples Federico II.",
    repository: .init(
        name: "SAD GitHub",
        url: "https://github.com/fpseverino/software-architecture-design"
    ),
    docc: DocCSite(
        packages: [
            APIPackage(
                "StickerStarDocs",
                group: "Overview",
                versions: [
                    .single(
                        ref: "main", 
                        modules: [
                            Module(
                                "StickerStarDocs",
                                title: "StickerStar",
                                description: "The documentation for the StickerStar application."
                            )
                        ]
                    )
                ]
            ),
            APIPackage(
                "StickerStarAPI",
                group: "Microservices",
                versions: [
                    .single(
                        ref: "main", 
                        modules: [Module("StickerStarAPI", description: "The API Gateway for the StickerStar application.")]
                    )
                ]
            ),
            APIPackage(
                "StickerStarUsers",
                group: "Microservices",
                versions: [
                    .single(
                        ref: "main",
                        modules: [Module("StickerStarUsers", description: "The Users microservice for the StickerStar application.")]
                    )
                ]
            ),
            APIPackage(
                "StickerStarStickers",
                group: "Microservices",
                versions: [
                    .single(
                        ref: "main",
                        modules: [Module("StickerStarStickers", description: "The Stickers microservice for the StickerStar application.")]
                    )
                ]
            ),
        ]
    )
)

try await Kiln.build(site, contentDirectory: "Content", outputDirectory: "site")
