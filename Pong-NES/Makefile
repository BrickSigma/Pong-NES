CC := ca65
LD := ld65
LDFLAGS := -t nes

Pong.nes : src/main.o src/handlers.o
	$(LD) $^ $(LDFLAGS) -o $@

src/main.o : src/main.asm
	$(CC) $^ -o $@

src/handlers.o : src/handlers.asm
	$(CC) $^ -o $@

clean:
	rm -f src/*.o
	rm -f *nes