# Legday — сборка и релиз

.PHONY: release build zip

# Полный релиз: сборка, zip (только .app), тег годмесяцденьчас, пуш тега, GitHub Release
release:
	@./scripts/do-release.sh

# Только сборка Release
build:
	xcodebuild -scheme Legday -configuration Release -derivedDataPath build clean build

# Только упаковать текущую сборку в zip (версия = годмесяцденьчас)
zip:
	@VERSION=$$(date +%Y%m%d%H); \
	rm -rf release/Legday.app release/Legday-macOS-*.zip; \
	mkdir -p release && cp -R build/Build/Products/Release/Legday.app release/; \
	cd release && zip -rq "Legday-macOS-$$VERSION.zip" Legday.app; \
	echo "Создан release/Legday-macOS-$$VERSION.zip"
