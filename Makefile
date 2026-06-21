TARGET := prog32

ASM_SRC := args32.asm
C_SRC   := main.c

ASM_OBJ := args32.o
C_OBJ   := main.o

NASM      := nasm
NASMFLAGS := -f elf32 -g

CC      := gcc
CFLAGS  := -m32 -Wall -Wextra -g -no-pie

.PHONY: all
all: $(TARGET)

$(TARGET): $(C_OBJ) $(ASM_OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(C_OBJ) $(ASM_OBJ)
	@echo "Build concluído: ./$(TARGET)"

$(C_OBJ): $(C_SRC)
	$(CC) $(CFLAGS) -c $(C_SRC) -o $(C_OBJ)

$(ASM_OBJ): $(ASM_SRC)
	$(NASM) $(NASMFLAGS) $(ASM_SRC) -o $(ASM_OBJ)

.PHONY: run
run: $(TARGET)
	./$(TARGET)

.PHONY: test
test: $(TARGET)
	bash tests/run_tests.sh

.PHONY: debug
debug: $(TARGET)
	gdb ./$(TARGET)

.PHONY: clean
clean:
	rm -f $(C_OBJ) $(ASM_OBJ) $(TARGET)
	@echo "Limpeza concluída."
