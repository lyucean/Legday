# Legday — сборка и релиз

.PHONY: release build zip install run

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

# Собрать и запустить приложение (удобно тестировать из Cursor)
run: build
	@open build/Build/Products/Release/Legday.app

# Собрать и поставить Legday.app в /Applications (заменяет старую версию)
install: build
	@echo "Установка в /Applications/Legday.app ..."
	@rm -rf /Applications/Legday.app
	@cp -R build/Build/Products/Release/Legday.app /Applications/
	@echo "Готово. Legday установлен в /Applications."
