PROJECT     := TaskManager.xcodeproj
SCHEME      := TaskManager
# 手元にないシミュレータを使う場合は `make test SIMULATOR="iPhone 16"` のように上書きする
SIMULATOR   ?= iPhone 17
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)
SOURCES     := TaskManager TaskManagerUITests Packages/TaskManagerKit/Package.swift \
               Packages/TaskManagerKit/Sources Packages/TaskManagerKit/Tests

.PHONY: generate open lint format build test clean

generate:
	xcodegen generate

open: generate
	open $(PROJECT)

lint:
	swiftlint lint --strict
	swift format lint --recursive --strict $(SOURCES)

format:
	swift format --in-place --recursive $(SOURCES)
	swiftlint lint --fix

build: generate
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -quiet

test: generate
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -quiet

clean:
	rm -rf $(PROJECT) Packages/TaskManagerKit/.build
