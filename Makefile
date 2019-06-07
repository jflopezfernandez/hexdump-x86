
vpath %.asm src
vpath %.inc include

OBJS    = main.o
LSTS    = $(patsubst %.o,%.lst,$(OBJS))

AS      = nasm
ASFLAGS = -Wall -felf -g -F stabs

LD      = ld
LDFLAGS = -nostdlib --reduce-memory-overheads --relax -m elf_i386
LIBS    = 

TARGET  = hexdump

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $^

listings: $(LSTS)

%.lst: %.asm
	$(AS) $(ASFLAGS) -l $@ $^

.PHONY: clean
clean:
	$(RM) $(OBJS) $(TARGET)

