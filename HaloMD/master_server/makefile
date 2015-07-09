CARGO = cargo
RELEASE_ARGS = --release

release: target/release/master_server
debug: target/debug/master_server

target/release/master_server:
	$(CARGO) build $(RELEASE_ARGS)
target/debug/master_server:
	$(CARGO) build

clean:
	rm -rf target
