SOURCE =main.asm
AS =naken430asm

out.hex: main.asm
	$(AS) $(SOURCE)

clean:
	rm *.hex


