# dream_snippets Makefile

.PHONY: test build format check check-snippets docs clean

# Run the tests with line coverage (fails below 100%)
test:
	@gleam test

# Build the package
build:
	@gleam build

# Format code
format:
	@gleam format src test

# Format check, build, tests, docs build and snippet check (what CI runs)
check:
	@gleam format --check src test
	@gleam build
	@gleam test
	@gleam docs build
	@gleam run -m dream_snippets

# Check that each code block in the docs matches a tested snippet
check-snippets:
	@gleam run -m dream_snippets

# Generate documentation
docs:
	@gleam docs build

# Clean build artifacts
clean:
	@gleam clean
	@rm -f erl_crash.dump
