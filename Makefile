.PHONY: gen
gen: ## Convert jsonnet to yaml
	./gen-yaml.sh

.PHONY: lint
lint:
	"./lint-hash.sh"
