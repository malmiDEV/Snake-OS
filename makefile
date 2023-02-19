ASM=nasm
VIRTUAL=qemu-system-i386

BUILD_DIR=build
SRC_DIR=src

# floppy image
snake_os: $(BUILD_DIR)/snake_os.iso

$(BUILD_DIR)/snake_os.iso: boot kernel
	dd if=/dev/zero of=$(BUILD_DIR)/snake_os.iso bs=512 count=2880
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/snake_os.iso conv=notrunc bs=512 seek=0 count=1
	dd if=$(BUILD_DIR)/kernel.bin of=$(BUILD_DIR)/snake_os.iso conv=notrunc bs=512 seek=1 count=2048 
    
# boorloader
boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: always
	$(ASM) $(SRC_DIR)/boot/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

# kernel
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

# always
always:	
	mkdir -p $(BUILD_DIR)

# clean
clean:
	rm -rf $(BUILD_DIR)/*

# run
run:
	$(VIRTUAL) -fda $(BUILD_DIR)/snake_os.iso
