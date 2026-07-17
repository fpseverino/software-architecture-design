import Kiln

/// The main entry point for the StickerStar documentation site.
let site = KilnSite(
    name: "StickerStar",
    url: "https://example.com",
    author: "Francesco Paolo Severino",
    description: "Documentation for the StickerStar microservice-based application.",
    theme: .default(palette: .autoLightDark(primary: .black, accent: .blue)),
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
