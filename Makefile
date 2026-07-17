.PHONY: docs docs-overview docs-api docs-stickers docs-users

ARCHIVES_DIR := $(CURDIR)/StickerStarDocs/Content/archives/default

docs: docs-overview docs-api docs-stickers docs-users

$(ARCHIVES_DIR):
	mkdir -p $(ARCHIVES_DIR)

docs-overview: $(ARCHIVES_DIR)
	cd StickerStarDocs && swift package --allow-writing-to-directory "$(ARCHIVES_DIR)" generate-documentation --target StickerStarDocs --output-path "$(ARCHIVES_DIR)/StickerStarDocs.doccarchive"

docs-api: $(ARCHIVES_DIR)
	cd StickerStarAPI && swift package --allow-writing-to-directory "$(ARCHIVES_DIR)" generate-documentation --target StickerStarAPI --output-path "$(ARCHIVES_DIR)/StickerStarAPI.doccarchive"

docs-stickers: $(ARCHIVES_DIR)
	cd StickerStarStickers && swift package --allow-writing-to-directory "$(ARCHIVES_DIR)" generate-documentation --target StickerStarStickers --output-path "$(ARCHIVES_DIR)/StickerStarStickers.doccarchive"

docs-users: $(ARCHIVES_DIR)
	cd StickerStarUsers && swift package --allow-writing-to-directory "$(ARCHIVES_DIR)" generate-documentation --target StickerStarUsers --output-path "$(ARCHIVES_DIR)/StickerStarUsers.doccarchive"
