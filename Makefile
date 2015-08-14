all: stack-build swarm-build postgres-dev vault-dev

stack-build: build/stack-build.marker
swarm-build: build/swarm-build.marker
postgres-dev: build/postgres-dev.marker
vault-dev: build/vault-dev.marker

.PHONY: clean
clean:
	rm -rf build

build/%.marker: %/Dockerfile
	@mkdir -p build
	@echo ========================== $(*F)
	@rm -f build/$(*F).log
	docker build -t sb/$(*F):$$(cat $(*F)/dockertag) $(*F) | tee build/$(*F).log
	docker build -t sb/$(*F):latest $(*F) >> build/$(*F).log
	touch build/$(*F).marker

build/stack-build.marker: stack-build/Dockerfile stack-build/entrypoint.sh stack-build/my_init stack-build/container_environment/*
build/swarm-build.marker: swarm-build/Dockerfile build/stack-build.marker
build/postgres-dev.marker: postgres-dev/Dockerfile postgres-dev/postgres-dev-init.sh
build/vault-dev.marker: vault-dev/Dockerfile vault-dev/vault.hcl vault-dev/vault-entrypoint


