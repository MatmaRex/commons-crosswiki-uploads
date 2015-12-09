cat log_crosswiki.json | jq "[ .[] | .title ]" > log_crosswiki_titles.json
cat log_other.json | jq "[ .[] | .title ]" > log_other_titles.json