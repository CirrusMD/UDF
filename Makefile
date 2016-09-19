default: auto

purge:
	rm -rf ~/Library/Developer/Xcode/DerivedData

auto:
	swiftlint autocorrect

.PHONY: purge update
