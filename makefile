dist/archive.tar.gz: ./src
	tar czf $@ $<
	chmod 755 $@