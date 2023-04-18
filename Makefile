all:
	swift package resolve

update:
	swift package update

run:
	swift run swana -h

build:
	swift build swana -c release --show-bin-path

format:
	swiftformat . --config .swiftformat
