.PHONY: build terminal ghostty btop zed firefox firefox-package clean

build: terminal ghostty btop zed firefox

terminal:
	swift terminal/convert.swift

ghostty:
	swift generate.swift ghostty/config.template ghostty/config

btop:
	swift generate.swift btop/ember.theme.template btop/ember.theme

zed:
	swift generate.swift zed/ember.json.template zed/ember.json

firefox:
	swift generate.swift firefox/ember/manifest.json.template firefox/ember/manifest.json

# Package the Firefox theme as .xpi for signing/distribution.
# Submit the .xpi at https://addons.mozilla.org/developers/ as "unlisted"
# to self-host, or "listed" to publish. Mozilla signs it and returns the
# signed .xpi, which Firefox will install persistently.
firefox-package: firefox
	cd firefox/ember && zip -r ../ember.xpi manifest.json
	@echo "→ firefox/ember.xpi ready to submit to addons.mozilla.org"


clean:
	rm -f terminal/Ember.terminal ghostty/config btop/ember.theme zed/ember.json firefox/ember/manifest.json firefox/ember.xpi
