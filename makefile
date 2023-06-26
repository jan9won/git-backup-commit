SRC_DIRS = $(shell find ./src -type d)
SRC_FILES = $(shell find ./src -type f -name '*')

./dist/archive.tar.gz: ./src $(SRC_DIRS) $(SRC_FILES)
	tar --no-xattrs -czf $@ -C $< .
	chmod 755 $<
