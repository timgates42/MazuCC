TARGET = mzcc

CFLAGS = -Wall -Werror -std=gnu99 -g -I.

NAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
CFLAGS += -no-pie
endif

# Control the build verbosity
ifeq ("$(VERBOSE)","1")
    Q :=
    VECHO = @true
else
    Q := @
    VECHO = @printf
endif

OBJS = lexer.o codegen_x64.o parser.o verbose.o main.o
deps := $(OBJS:%.o=.%.o.d)

%.o: %.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) -c -MMD -MF .$@.d $<

$(TARGET): $(OBJS)
	$(VECHO) "  LD\t$@\n"
	$(Q)$(CC) $(CFLAGS) -o $@ $^

TESTS := $(patsubst %.c,%.bin,$(wildcard tests/*.c))
check: nqueen $(TESTS)
	@echo
	@for test in $(TESTS); do \
	    ./$$test;             \
	done
	tests/driver.sh

tests/%.s: tests/%.c $(TARGET)
	./mzcc < $< > $@

tests/%.bin: tests/%.s $(TARGET)
	$(CC) $(CFLAGS) -o $@ $<

nqueen: sample/nqueen.c $(TARGET)
	$(VECHO) "  MazuCC\t$<\n"
	$(Q)./mzcc < $< > ${<:.c=.s}
	$(VECHO) "  AS+LD\t\t$@\n"
	$(Q)$(CC) $(CFLAGS) -o sample/nqueen sample/nqueen.s

.PHONY: clean check
clean:
	$(RM) $(TARGET) $(TESTS) $(OBJS) $(deps)
	$(RM) sample/*.o sample/nqueen.s sample/nqueen

-include $(deps)