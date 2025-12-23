#!/usr/bin/env bash

set -e

# Script zur Migration von Jekyll zu Hugo
# Konvertiert Front Matter und Syntax-Highlighting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSTS_DIR="${SCRIPT_DIR}/hugo/quickstart/content/posts"

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Jekyll zu Hugo Migration ===${NC}"
echo "Posts Verzeichnis: ${POSTS_DIR}"
echo ""

# Zähler
total_files=0
migrated_files=0
skipped_files=0

# Funktion zum Migrieren einer einzelnen Datei
migrate_file() {
    local file="$1"
    local filename=$(basename "$file")

    echo -e "${YELLOW}Verarbeite: ${filename}${NC}"

    # Prüfe ob Datei Jekyll Front Matter hat
    if ! grep -q "^layout: post" "$file"; then
        echo "  ⚠️  Übersprungen (kein Jekyll Front Matter gefunden)"
        ((skipped_files++))
        return
    fi

    # Backup erstellen
    cp "$file" "${file}.jekyll-backup"

    # Temporäre Datei für die Konvertierung
    local temp_file="${file}.tmp"

    # Front Matter konvertieren
    awk '
    BEGIN {
        in_frontmatter = 0
        frontmatter_count = 0
        title = ""
        subtitle = ""
        date = ""
        updated = ""
        categories = ""
        published = ""
    }

    /^---$/ {
        frontmatter_count++
        if (frontmatter_count == 1) {
            in_frontmatter = 1
            next
        }
        if (frontmatter_count == 2) {
            in_frontmatter = 0
            # Hugo Front Matter ausgeben
            print "---"
            if (title != "") {
                # Title in Anführungszeichen setzen
                gsub(/^title: /, "", title)
                print "title: \"" title "\""
            }
            if (subtitle != "" && subtitle != "subtitle:") {
                gsub(/^subtitle: /, "", subtitle)
                print "subtitle: \"" subtitle "\""
            }
            if (date != "") {
                # Datum konvertieren: "2016-01-07 13:23:07 UTC" -> "2016-01-07T13:23:07Z"
                gsub(/^date: /, "", date)
                gsub(/ UTC$/, "Z", date)
                gsub(/ /, "T", date)
                print "date: " date
            }
            if (updated != "") {
                gsub(/^updated: /, "", updated)
                gsub(/ UTC$/, "Z", updated)
                gsub(/ /, "T", updated)
                print "lastmod: " updated
            }
            # Draft Status
            if (published == "false") {
                print "draft: true"
            } else {
                print "draft: false"
            }
            # Tags und Categories
            if (categories != "") {
                gsub(/^categories: /, "", categories)
                # Kategorien in Array-Format konvertieren
                split(categories, cats, " ")
                cat_array = "["
                for (i in cats) {
                    if (i > 1) cat_array = cat_array ", "
                    cat_array = cat_array "\"" cats[i] "\""
                }
                cat_array = cat_array "]"
                print "tags: " cat_array
                print "categories: " cat_array
            }
            print "---"
            next
        }
    }

    {
        if (in_frontmatter) {
            if ($0 ~ /^layout:/) next
            if ($0 ~ /^comments:/) next
            if ($0 ~ /^title:/) { title = $0; next }
            if ($0 ~ /^subtitle:/) { subtitle = $0; next }
            if ($0 ~ /^date:/) { date = $0; next }
            if ($0 ~ /^updated:/) { updated = $0; next }
            if ($0 ~ /^categories:/) { categories = $0; next }
            if ($0 ~ /^published:/) {
                gsub(/^published: /, "", $0)
                published = $0
                next
            }
        } else {
            print
        }
    }
    ' "$file" > "$temp_file"

    # Jekyll Syntax-Highlighting ersetzen
    sed -i.sed1 \
        -e 's/{% highlight xml %}/```xml/g' \
        -e 's/{% highlight bash%}/```bash/g' \
        -e 's/{% highlight bash %}/```bash/g' \
        -e 's/{% highlight yaml %}/```yaml/g' \
        -e 's/{% highlight java %}/```java/g' \
        -e 's/{% highlight javascript %}/```javascript/g' \
        -e 's/{% highlight python %}/```python/g' \
        -e 's/{% highlight ruby %}/```ruby/g' \
        -e 's/{% highlight shell %}/```shell/g' \
        -e 's/{% highlight sql %}/```sql/g' \
        -e 's/{% highlight json %}/```json/g' \
        -e 's/{% highlight html %}/```html/g' \
        -e 's/{% highlight css %}/```css/g' \
        -e 's/{% endhighlight %}/```/g' \
        "$temp_file"

    # HTML Figure Tags ersetzen
    sed -i.sed2 \
        -e 's|<figure>||g' \
        -e 's|</figure>||g' \
        -e 's|<figcaption>File: <tt>\(.*\)</tt></figcaption>|**File: `\1`**|g' \
        "$temp_file"

    # Leere Zeilen nach Front Matter bereinigen
    awk 'BEGIN {empty_lines=0; after_fm=0}
         /^---$/ && NR==1 {print; next}
         /^---$/ && !after_fm {print; after_fm=1; next}
         after_fm && /^$/ {empty_lines++; if(empty_lines<=2) print; next}
         after_fm {empty_lines=0}
         {print}' "$temp_file" > "${temp_file}.clean"

    # Migrierte Datei zurückschreiben
    mv "${temp_file}.clean" "$file"

    # Temporäre Dateien aufräumen
    rm -f "${temp_file}" "${temp_file}.sed1" "${temp_file}.sed2"

    echo "  ✅ Erfolgreich migriert"
    ((migrated_files++))
}

# Alle Markdown-Dateien verarbeiten
if [ ! -d "$POSTS_DIR" ]; then
    echo -e "${RED}Fehler: Posts-Verzeichnis nicht gefunden: ${POSTS_DIR}${NC}"
    exit 1
fi

echo "Suche nach Markdown-Dateien..."
echo ""

while IFS= read -r -d '' file; do
    ((total_files++))
    migrate_file "$file"
done < <(find "$POSTS_DIR" -name "*.md" -type f -print0)

echo ""
echo -e "${GREEN}=== Migration abgeschlossen ===${NC}"
echo "Gesamt: ${total_files} Dateien"
echo "Migriert: ${migrated_files} Dateien"
echo "Übersprungen: ${skipped_files} Dateien"
echo ""
echo "Backups wurden mit der Endung .jekyll-backup erstellt"
echo ""

# Optionale Bereinigung der Backups
read -p "Möchten Sie die Backup-Dateien löschen? (j/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    find "$POSTS_DIR" -name "*.jekyll-backup" -delete
    echo "Backups gelöscht"
else
    echo "Backups behalten"
fi

