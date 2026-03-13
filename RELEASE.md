# Как опубликовать релиз

1. Собрать приложение и архив:
   ```bash
   xcodebuild -scheme Legday -configuration Release -derivedDataPath build clean build
   mkdir -p release && cp -R build/Build/Products/Release/Legday.app release/
   cd release && zip -r Legday-macOS-1.0.0.zip Legday.app
   ```

2. На GitHub: [Releases](https://github.com/lyucean/Legday/releases) → создать или отредактировать релиз.

3. Выберите тег (например **v1.0.0**), заголовок «Release 1.0.0».

4. В блоке **Attach binaries** прикрепите файл **`release/Legday-macOS-1.0.0.zip`** — в нём только Legday.app. Имя специально другое, чтобы не путать с «Source code (zip)» от GitHub.

5. В описании релиза напишите: «Скачайте **Legday-macOS-1.0.0.zip** (в Assets). В архиве один файл — Legday.app. Перетащите в «Программы». Не скачивайте Source code — там исходники.»

6. Нажмите **Publish release**.
