
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 0c 17 f0       	mov    $0xf0170c50,%eax
f010004b:	2d 26 fd 16 f0       	sub    $0xf016fd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 fd 16 f0       	push   $0xf016fd26
f0100058:	e8 b7 41 00 00       	call   f0104214 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 46 10 f0       	push   $0xf01046c0
f010006f:	e8 78 2e 00 00       	call   f0102eec <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 f8 0f 00 00       	call   f0101071 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 c0 28 00 00       	call   f010293e <env_init>
	trap_init();
f010007e:	e8 da 2e 00 00       	call   f0102f5d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 53 2a 00 00       	call   f0102ae5 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 ff 16 f0    	pushl  0xf016ff84
f010009b:	e8 83 2d 00 00       	call   f0102e23 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 0c 17 f0 00 	cmpl   $0x0,0xf0170c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 0c 17 f0    	mov    %esi,0xf0170c40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 46 10 f0       	push   $0xf01046db
f01000ca:	e8 1d 2e 00 00       	call   f0102eec <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 ed 2d 00 00       	call   f0102ec6 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 74 56 10 f0 	movl   $0xf0105674,(%esp)
f01000e0:	e8 07 2e 00 00       	call   f0102eec <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 ff 06 00 00       	call   f01007f1 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 46 10 f0       	push   $0xf01046f3
f010010c:	e8 db 2d 00 00       	call   f0102eec <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 a9 2d 00 00       	call   f0102ec6 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 74 56 10 f0 	movl   $0xf0105674,(%esp)
f0100124:	e8 c3 2d 00 00       	call   f0102eec <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 ff 16 f0    	mov    0xf016ff64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 ff 16 f0    	mov    %edx,0xf016ff64
f010016e:	88 81 60 fd 16 f0    	mov    %al,-0xfe902a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 ff 16 f0 00 	movl   $0x0,0xf016ff64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 fd 16 f0 40 	orl    $0x40,0xf016fd40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 60 48 10 f0 	movzbl -0xfefb7a0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 fd 16 f0    	mov    %ecx,0xf016fd40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 60 48 10 f0 	movzbl -0xfefb7a0(%edx),%eax
f0100226:	0b 05 40 fd 16 f0    	or     0xf016fd40,%eax
f010022c:	0f b6 8a 60 47 10 f0 	movzbl -0xfefb8a0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 40 47 10 f0 	mov    -0xfefb8c0(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 0d 47 10 f0       	push   $0xf010470d
f0100282:	e8 65 2c 00 00       	call   f0102eec <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 ff 16 f0 	addw   $0x50,0xf016ff68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 ff 16 f0 	mov    %dx,0xf016ff68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 ff 16 f0 	cmpw   $0x7cf,0xf016ff68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c ff 16 f0       	mov    0xf016ff6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 2b 3e 00 00       	call   f0104261 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 ff 16 f0 	subw   $0x50,0xf016ff68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 ff 16 f0    	mov    0xf016ff70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 ff 16 f0 	movzwl 0xf016ff68,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 ff 16 f0 00 	cmpb   $0x0,0xf016ff74
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 ff 16 f0       	mov    0xf016ff60,%eax
f01004d8:	3b 05 64 ff 16 f0    	cmp    0xf016ff64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 ff 16 f0    	mov    %edx,0xf016ff60
f01004e9:	0f b6 88 60 fd 16 f0 	movzbl -0xfe902a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 ff 16 f0 00 	movl   $0x0,0xf016ff60
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 ff 16 f0 b4 	movl   $0x3b4,0xf016ff70
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 ff 16 f0 d4 	movl   $0x3d4,0xf016ff70
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 ff 16 f0    	mov    0xf016ff70,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c ff 16 f0    	mov    %esi,0xf016ff6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 ff 16 f0 	setne  0xf016ff74
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 19 47 10 f0       	push   $0xf0104719
f0100605:	e8 e2 28 00 00       	call   f0102eec <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:
	
};

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 60 49 10 f0       	push   $0xf0104960
f010064b:	68 7e 49 10 f0       	push   $0xf010497e
f0100650:	68 83 49 10 f0       	push   $0xf0104983
f0100655:	e8 92 28 00 00       	call   f0102eec <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 58 4a 10 f0       	push   $0xf0104a58
f0100662:	68 8c 49 10 f0       	push   $0xf010498c
f0100667:	68 83 49 10 f0       	push   $0xf0104983
f010066c:	e8 7b 28 00 00       	call   f0102eec <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 95 49 10 f0       	push   $0xf0104995
f0100679:	68 b2 49 10 f0       	push   $0xf01049b2
f010067e:	68 83 49 10 f0       	push   $0xf0104983
f0100683:	e8 64 28 00 00       	call   f0102eec <cprintf>
	return 0;
}
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100695:	68 bc 49 10 f0       	push   $0xf01049bc
f010069a:	e8 4d 28 00 00       	call   f0102eec <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 80 4a 10 f0       	push   $0xf0104a80
f01006ac:	e8 3b 28 00 00       	call   f0102eec <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 a8 4a 10 f0       	push   $0xf0104aa8
f01006c3:	e8 24 28 00 00       	call   f0102eec <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 a1 46 10 00       	push   $0x1046a1
f01006d0:	68 a1 46 10 f0       	push   $0xf01046a1
f01006d5:	68 cc 4a 10 f0       	push   $0xf0104acc
f01006da:	e8 0d 28 00 00       	call   f0102eec <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 fd 16 00       	push   $0x16fd26
f01006e7:	68 26 fd 16 f0       	push   $0xf016fd26
f01006ec:	68 f0 4a 10 f0       	push   $0xf0104af0
f01006f1:	e8 f6 27 00 00       	call   f0102eec <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 0c 17 00       	push   $0x170c50
f01006fe:	68 50 0c 17 f0       	push   $0xf0170c50
f0100703:	68 14 4b 10 f0       	push   $0xf0104b14
f0100708:	e8 df 27 00 00       	call   f0102eec <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 10 17 f0       	mov    $0xf017104f,%eax
f0100712:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100717:	83 c4 08             	add    $0x8,%esp
f010071a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010071f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100725:	85 c0                	test   %eax,%eax
f0100727:	0f 48 c2             	cmovs  %edx,%eax
f010072a:	c1 f8 0a             	sar    $0xa,%eax
f010072d:	50                   	push   %eax
f010072e:	68 38 4b 10 f0       	push   $0xf0104b38
f0100733:	e8 b4 27 00 00       	call   f0102eec <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100748:	89 ee                	mov    %ebp,%esi
	struct Eipdebuginfo info;
  uint32_t ebp = read_ebp(), eip = 0;
  uint32_t* ebpp;
  cprintf("Stack backtrace:");
f010074a:	68 d5 49 10 f0       	push   $0xf01049d5
f010074f:	e8 98 27 00 00       	call   f0102eec <cprintf>
  while(ebp){//if ebp is 0, we are back at the first caller
f0100754:	83 c4 10             	add    $0x10,%esp
f0100757:	eb 7a                	jmp    f01007d3 <mon_backtrace+0x94>
    ebpp = (uint32_t*) ebp;
f0100759:	89 75 c4             	mov    %esi,-0x3c(%ebp)
    eip = *(ebpp+1);
f010075c:	8b 7e 04             	mov    0x4(%esi),%edi
    cprintf("\n  ebp %08x eip %08x args ", ebp, eip);
f010075f:	83 ec 04             	sub    $0x4,%esp
f0100762:	57                   	push   %edi
f0100763:	56                   	push   %esi
f0100764:	68 e6 49 10 f0       	push   $0xf01049e6
f0100769:	e8 7e 27 00 00       	call   f0102eec <cprintf>
f010076e:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100771:	83 c6 1c             	add    $0x1c,%esi
f0100774:	83 c4 10             	add    $0x10,%esp

    int argno = 0;
    for(; argno < 5; argno++){
      cprintf("%08x ", *(ebpp+2+argno));
f0100777:	83 ec 08             	sub    $0x8,%esp
f010077a:	ff 33                	pushl  (%ebx)
f010077c:	68 01 4a 10 f0       	push   $0xf0104a01
f0100781:	e8 66 27 00 00       	call   f0102eec <cprintf>
f0100786:	83 c3 04             	add    $0x4,%ebx
    ebpp = (uint32_t*) ebp;
    eip = *(ebpp+1);
    cprintf("\n  ebp %08x eip %08x args ", ebp, eip);

    int argno = 0;
    for(; argno < 5; argno++){
f0100789:	83 c4 10             	add    $0x10,%esp
f010078c:	39 f3                	cmp    %esi,%ebx
f010078e:	75 e7                	jne    f0100777 <mon_backtrace+0x38>
      cprintf("%08x ", *(ebpp+2+argno));
    }
	if(debuginfo_eip(eip, &info) == 0){
f0100790:	83 ec 08             	sub    $0x8,%esp
f0100793:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100796:	50                   	push   %eax
f0100797:	57                   	push   %edi
f0100798:	e8 9f 30 00 00       	call   f010383c <debuginfo_eip>
f010079d:	83 c4 10             	add    $0x10,%esp
f01007a0:	85 c0                	test   %eax,%eax
f01007a2:	75 2a                	jne    f01007ce <mon_backtrace+0x8f>
      cprintf("\n\t%s:%d: ", info.eip_file, info.eip_line);
f01007a4:	83 ec 04             	sub    $0x4,%esp
f01007a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ad:	68 07 4a 10 f0       	push   $0xf0104a07
f01007b2:	e8 35 27 00 00       	call   f0102eec <cprintf>
      cprintf("%.*s+%d", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01007b7:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ba:	57                   	push   %edi
f01007bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01007be:	ff 75 dc             	pushl  -0x24(%ebp)
f01007c1:	68 11 4a 10 f0       	push   $0xf0104a11
f01007c6:	e8 21 27 00 00       	call   f0102eec <cprintf>
f01007cb:	83 c4 20             	add    $0x20,%esp
    }
    ebp = *ebpp;
f01007ce:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007d1:	8b 30                	mov    (%eax),%esi
{
	struct Eipdebuginfo info;
  uint32_t ebp = read_ebp(), eip = 0;
  uint32_t* ebpp;
  cprintf("Stack backtrace:");
  while(ebp){//if ebp is 0, we are back at the first caller
f01007d3:	85 f6                	test   %esi,%esi
f01007d5:	75 82                	jne    f0100759 <mon_backtrace+0x1a>
      cprintf("%.*s+%d", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
    }
    ebp = *ebpp;

  }
  cprintf("\n");
f01007d7:	83 ec 0c             	sub    $0xc,%esp
f01007da:	68 74 56 10 f0       	push   $0xf0105674
f01007df:	e8 08 27 00 00       	call   f0102eec <cprintf>
  return 0;	
}
f01007e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007ec:	5b                   	pop    %ebx
f01007ed:	5e                   	pop    %esi
f01007ee:	5f                   	pop    %edi
f01007ef:	5d                   	pop    %ebp
f01007f0:	c3                   	ret    

f01007f1 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f1:	55                   	push   %ebp
f01007f2:	89 e5                	mov    %esp,%ebp
f01007f4:	57                   	push   %edi
f01007f5:	56                   	push   %esi
f01007f6:	53                   	push   %ebx
f01007f7:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fa:	68 64 4b 10 f0       	push   $0xf0104b64
f01007ff:	e8 e8 26 00 00       	call   f0102eec <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100804:	c7 04 24 88 4b 10 f0 	movl   $0xf0104b88,(%esp)
f010080b:	e8 dc 26 00 00       	call   f0102eec <cprintf>

	if (tf != NULL)
f0100810:	83 c4 10             	add    $0x10,%esp
f0100813:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100817:	74 0e                	je     f0100827 <monitor+0x36>
		print_trapframe(tf);
f0100819:	83 ec 0c             	sub    $0xc,%esp
f010081c:	ff 75 08             	pushl  0x8(%ebp)
f010081f:	e8 02 2b 00 00       	call   f0103326 <print_trapframe>
f0100824:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100827:	83 ec 0c             	sub    $0xc,%esp
f010082a:	68 19 4a 10 f0       	push   $0xf0104a19
f010082f:	e8 89 37 00 00       	call   f0103fbd <readline>
f0100834:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100836:	83 c4 10             	add    $0x10,%esp
f0100839:	85 c0                	test   %eax,%eax
f010083b:	74 ea                	je     f0100827 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100844:	be 00 00 00 00       	mov    $0x0,%esi
f0100849:	eb 0a                	jmp    f0100855 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084b:	c6 03 00             	movb   $0x0,(%ebx)
f010084e:	89 f7                	mov    %esi,%edi
f0100850:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100853:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100855:	0f b6 03             	movzbl (%ebx),%eax
f0100858:	84 c0                	test   %al,%al
f010085a:	74 63                	je     f01008bf <monitor+0xce>
f010085c:	83 ec 08             	sub    $0x8,%esp
f010085f:	0f be c0             	movsbl %al,%eax
f0100862:	50                   	push   %eax
f0100863:	68 1d 4a 10 f0       	push   $0xf0104a1d
f0100868:	e8 6a 39 00 00       	call   f01041d7 <strchr>
f010086d:	83 c4 10             	add    $0x10,%esp
f0100870:	85 c0                	test   %eax,%eax
f0100872:	75 d7                	jne    f010084b <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100874:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100877:	74 46                	je     f01008bf <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100879:	83 fe 0f             	cmp    $0xf,%esi
f010087c:	75 14                	jne    f0100892 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010087e:	83 ec 08             	sub    $0x8,%esp
f0100881:	6a 10                	push   $0x10
f0100883:	68 22 4a 10 f0       	push   $0xf0104a22
f0100888:	e8 5f 26 00 00       	call   f0102eec <cprintf>
f010088d:	83 c4 10             	add    $0x10,%esp
f0100890:	eb 95                	jmp    f0100827 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100892:	8d 7e 01             	lea    0x1(%esi),%edi
f0100895:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100899:	eb 03                	jmp    f010089e <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010089b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089e:	0f b6 03             	movzbl (%ebx),%eax
f01008a1:	84 c0                	test   %al,%al
f01008a3:	74 ae                	je     f0100853 <monitor+0x62>
f01008a5:	83 ec 08             	sub    $0x8,%esp
f01008a8:	0f be c0             	movsbl %al,%eax
f01008ab:	50                   	push   %eax
f01008ac:	68 1d 4a 10 f0       	push   $0xf0104a1d
f01008b1:	e8 21 39 00 00       	call   f01041d7 <strchr>
f01008b6:	83 c4 10             	add    $0x10,%esp
f01008b9:	85 c0                	test   %eax,%eax
f01008bb:	74 de                	je     f010089b <monitor+0xaa>
f01008bd:	eb 94                	jmp    f0100853 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008bf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c7:	85 f6                	test   %esi,%esi
f01008c9:	0f 84 58 ff ff ff    	je     f0100827 <monitor+0x36>
f01008cf:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d4:	83 ec 08             	sub    $0x8,%esp
f01008d7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008da:	ff 34 85 c0 4b 10 f0 	pushl  -0xfefb440(,%eax,4)
f01008e1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e4:	e8 90 38 00 00       	call   f0104179 <strcmp>
f01008e9:	83 c4 10             	add    $0x10,%esp
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	75 21                	jne    f0100911 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008f0:	83 ec 04             	sub    $0x4,%esp
f01008f3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f6:	ff 75 08             	pushl  0x8(%ebp)
f01008f9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008fc:	52                   	push   %edx
f01008fd:	56                   	push   %esi
f01008fe:	ff 14 85 c8 4b 10 f0 	call   *-0xfefb438(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100905:	83 c4 10             	add    $0x10,%esp
f0100908:	85 c0                	test   %eax,%eax
f010090a:	78 25                	js     f0100931 <monitor+0x140>
f010090c:	e9 16 ff ff ff       	jmp    f0100827 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100911:	83 c3 01             	add    $0x1,%ebx
f0100914:	83 fb 03             	cmp    $0x3,%ebx
f0100917:	75 bb                	jne    f01008d4 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100919:	83 ec 08             	sub    $0x8,%esp
f010091c:	ff 75 a8             	pushl  -0x58(%ebp)
f010091f:	68 3f 4a 10 f0       	push   $0xf0104a3f
f0100924:	e8 c3 25 00 00       	call   f0102eec <cprintf>
f0100929:	83 c4 10             	add    $0x10,%esp
f010092c:	e9 f6 fe ff ff       	jmp    f0100827 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100931:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100934:	5b                   	pop    %ebx
f0100935:	5e                   	pop    %esi
f0100936:	5f                   	pop    %edi
f0100937:	5d                   	pop    %ebp
f0100938:	c3                   	ret    

f0100939 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100939:	55                   	push   %ebp
f010093a:	89 e5                	mov    %esp,%ebp
f010093c:	56                   	push   %esi
f010093d:	53                   	push   %ebx
f010093e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100940:	83 ec 0c             	sub    $0xc,%esp
f0100943:	50                   	push   %eax
f0100944:	e8 3c 25 00 00       	call   f0102e85 <mc146818_read>
f0100949:	89 c6                	mov    %eax,%esi
f010094b:	83 c3 01             	add    $0x1,%ebx
f010094e:	89 1c 24             	mov    %ebx,(%esp)
f0100951:	e8 2f 25 00 00       	call   f0102e85 <mc146818_read>
f0100956:	c1 e0 08             	shl    $0x8,%eax
f0100959:	09 f0                	or     %esi,%eax
}
f010095b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010095e:	5b                   	pop    %ebx
f010095f:	5e                   	pop    %esi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    

f0100962 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100962:	89 d1                	mov    %edx,%ecx
f0100964:	c1 e9 16             	shr    $0x16,%ecx
f0100967:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010096a:	a8 01                	test   $0x1,%al
f010096c:	74 52                	je     f01009c0 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010096e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100973:	89 c1                	mov    %eax,%ecx
f0100975:	c1 e9 0c             	shr    $0xc,%ecx
f0100978:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f010097e:	72 1b                	jb     f010099b <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100986:	50                   	push   %eax
f0100987:	68 e4 4b 10 f0       	push   $0xf0104be4
f010098c:	68 45 03 00 00       	push   $0x345
f0100991:	68 8d 53 10 f0       	push   $0xf010538d
f0100996:	e8 05 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010099b:	c1 ea 0c             	shr    $0xc,%edx
f010099e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009ab:	89 c2                	mov    %eax,%edx
f01009ad:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b5:	85 d2                	test   %edx,%edx
f01009b7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009bc:	0f 44 c2             	cmove  %edx,%eax
f01009bf:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009c5:	c3                   	ret    

f01009c6 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009c6:	55                   	push   %ebp
f01009c7:	89 e5                	mov    %esp,%ebp
f01009c9:	83 ec 08             	sub    $0x8,%esp
f01009cc:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) 
f01009ce:	83 3d 78 ff 16 f0 00 	cmpl   $0x0,0xf016ff78
f01009d5:	75 0f                	jne    f01009e6 <boot_alloc+0x20>
	{
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009d7:	b8 4f 1c 17 f0       	mov    $0xf0171c4f,%eax
f01009dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009e1:	a3 78 ff 16 f0       	mov    %eax,0xf016ff78
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here

	result=nextfree;
f01009e6:	a1 78 ff 16 f0       	mov    0xf016ff78,%eax

	if(n)
f01009eb:	85 d2                	test   %edx,%edx
f01009ed:	74 4f                	je     f0100a3e <boot_alloc+0x78>
	{

		nextfree = ROUNDUP(nextfree+n,PGSIZE);
f01009ef:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009f6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009fc:	89 15 78 ff 16 f0    	mov    %edx,0xf016ff78
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a02:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a08:	77 12                	ja     f0100a1c <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a0a:	52                   	push   %edx
f0100a0b:	68 08 4c 10 f0       	push   $0xf0104c08
f0100a10:	6a 73                	push   $0x73
f0100a12:	68 8d 53 10 f0       	push   $0xf010538d
f0100a17:	e8 84 f6 ff ff       	call   f01000a0 <_panic>
		
		if(PADDR(nextfree)>=PTSIZE)
f0100a1c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100a22:	81 fa ff ff 3f 00    	cmp    $0x3fffff,%edx
f0100a28:	76 14                	jbe    f0100a3e <boot_alloc+0x78>
		{
			panic("Trying to exceed the RAM.");
f0100a2a:	83 ec 04             	sub    $0x4,%esp
f0100a2d:	68 99 53 10 f0       	push   $0xf0105399
f0100a32:	6a 75                	push   $0x75
f0100a34:	68 8d 53 10 f0       	push   $0xf010538d
f0100a39:	e8 62 f6 ff ff       	call   f01000a0 <_panic>
		}
	}
	

	return result;
}
f0100a3e:	c9                   	leave  
f0100a3f:	c3                   	ret    

f0100a40 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
f0100a43:	57                   	push   %edi
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a49:	84 c0                	test   %al,%al
f0100a4b:	0f 85 81 02 00 00    	jne    f0100cd2 <check_page_free_list+0x292>
f0100a51:	e9 8e 02 00 00       	jmp    f0100ce4 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a56:	83 ec 04             	sub    $0x4,%esp
f0100a59:	68 2c 4c 10 f0       	push   $0xf0104c2c
f0100a5e:	68 7f 02 00 00       	push   $0x27f
f0100a63:	68 8d 53 10 f0       	push   $0xf010538d
f0100a68:	e8 33 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a6d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a70:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a73:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a76:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a79:	89 c2                	mov    %eax,%edx
f0100a7b:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0100a81:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a87:	0f 95 c2             	setne  %dl
f0100a8a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a8d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a91:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a93:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a97:	8b 00                	mov    (%eax),%eax
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	75 dc                	jne    f0100a79 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aac:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ab1:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab6:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abb:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
f0100ac1:	eb 53                	jmp    f0100b16 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ac3:	89 d8                	mov    %ebx,%eax
f0100ac5:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100acb:	c1 f8 03             	sar    $0x3,%eax
f0100ace:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ad1:	89 c2                	mov    %eax,%edx
f0100ad3:	c1 ea 16             	shr    $0x16,%edx
f0100ad6:	39 f2                	cmp    %esi,%edx
f0100ad8:	73 3a                	jae    f0100b14 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	c1 ea 0c             	shr    $0xc,%edx
f0100adf:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100ae5:	72 12                	jb     f0100af9 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae7:	50                   	push   %eax
f0100ae8:	68 e4 4b 10 f0       	push   $0xf0104be4
f0100aed:	6a 56                	push   $0x56
f0100aef:	68 b3 53 10 f0       	push   $0xf01053b3
f0100af4:	e8 a7 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100af9:	83 ec 04             	sub    $0x4,%esp
f0100afc:	68 80 00 00 00       	push   $0x80
f0100b01:	68 97 00 00 00       	push   $0x97
f0100b06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b0b:	50                   	push   %eax
f0100b0c:	e8 03 37 00 00       	call   f0104214 <memset>
f0100b11:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b14:	8b 1b                	mov    (%ebx),%ebx
f0100b16:	85 db                	test   %ebx,%ebx
f0100b18:	75 a9                	jne    f0100ac3 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b1f:	e8 a2 fe ff ff       	call   f01009c6 <boot_alloc>
f0100b24:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b27:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2d:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
		assert(pp < pages + npages);
f0100b33:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0100b38:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b3b:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b3e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b41:	be 00 00 00 00       	mov    $0x0,%esi
f0100b46:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b49:	e9 30 01 00 00       	jmp    f0100c7e <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4e:	39 ca                	cmp    %ecx,%edx
f0100b50:	73 19                	jae    f0100b6b <check_page_free_list+0x12b>
f0100b52:	68 c1 53 10 f0       	push   $0xf01053c1
f0100b57:	68 cd 53 10 f0       	push   $0xf01053cd
f0100b5c:	68 99 02 00 00       	push   $0x299
f0100b61:	68 8d 53 10 f0       	push   $0xf010538d
f0100b66:	e8 35 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b6b:	39 fa                	cmp    %edi,%edx
f0100b6d:	72 19                	jb     f0100b88 <check_page_free_list+0x148>
f0100b6f:	68 e2 53 10 f0       	push   $0xf01053e2
f0100b74:	68 cd 53 10 f0       	push   $0xf01053cd
f0100b79:	68 9a 02 00 00       	push   $0x29a
f0100b7e:	68 8d 53 10 f0       	push   $0xf010538d
f0100b83:	e8 18 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b88:	89 d0                	mov    %edx,%eax
f0100b8a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b8d:	a8 07                	test   $0x7,%al
f0100b8f:	74 19                	je     f0100baa <check_page_free_list+0x16a>
f0100b91:	68 50 4c 10 f0       	push   $0xf0104c50
f0100b96:	68 cd 53 10 f0       	push   $0xf01053cd
f0100b9b:	68 9b 02 00 00       	push   $0x29b
f0100ba0:	68 8d 53 10 f0       	push   $0xf010538d
f0100ba5:	e8 f6 f4 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100baa:	c1 f8 03             	sar    $0x3,%eax
f0100bad:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bb0:	85 c0                	test   %eax,%eax
f0100bb2:	75 19                	jne    f0100bcd <check_page_free_list+0x18d>
f0100bb4:	68 f6 53 10 f0       	push   $0xf01053f6
f0100bb9:	68 cd 53 10 f0       	push   $0xf01053cd
f0100bbe:	68 9e 02 00 00       	push   $0x29e
f0100bc3:	68 8d 53 10 f0       	push   $0xf010538d
f0100bc8:	e8 d3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bcd:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bd2:	75 19                	jne    f0100bed <check_page_free_list+0x1ad>
f0100bd4:	68 07 54 10 f0       	push   $0xf0105407
f0100bd9:	68 cd 53 10 f0       	push   $0xf01053cd
f0100bde:	68 9f 02 00 00       	push   $0x29f
f0100be3:	68 8d 53 10 f0       	push   $0xf010538d
f0100be8:	e8 b3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bed:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bf2:	75 19                	jne    f0100c0d <check_page_free_list+0x1cd>
f0100bf4:	68 84 4c 10 f0       	push   $0xf0104c84
f0100bf9:	68 cd 53 10 f0       	push   $0xf01053cd
f0100bfe:	68 a0 02 00 00       	push   $0x2a0
f0100c03:	68 8d 53 10 f0       	push   $0xf010538d
f0100c08:	e8 93 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c0d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c12:	75 19                	jne    f0100c2d <check_page_free_list+0x1ed>
f0100c14:	68 20 54 10 f0       	push   $0xf0105420
f0100c19:	68 cd 53 10 f0       	push   $0xf01053cd
f0100c1e:	68 a1 02 00 00       	push   $0x2a1
f0100c23:	68 8d 53 10 f0       	push   $0xf010538d
f0100c28:	e8 73 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c2d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c32:	76 3f                	jbe    f0100c73 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c34:	89 c3                	mov    %eax,%ebx
f0100c36:	c1 eb 0c             	shr    $0xc,%ebx
f0100c39:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c3c:	77 12                	ja     f0100c50 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3e:	50                   	push   %eax
f0100c3f:	68 e4 4b 10 f0       	push   $0xf0104be4
f0100c44:	6a 56                	push   $0x56
f0100c46:	68 b3 53 10 f0       	push   $0xf01053b3
f0100c4b:	e8 50 f4 ff ff       	call   f01000a0 <_panic>
f0100c50:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c55:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c58:	76 1e                	jbe    f0100c78 <check_page_free_list+0x238>
f0100c5a:	68 a8 4c 10 f0       	push   $0xf0104ca8
f0100c5f:	68 cd 53 10 f0       	push   $0xf01053cd
f0100c64:	68 a2 02 00 00       	push   $0x2a2
f0100c69:	68 8d 53 10 f0       	push   $0xf010538d
f0100c6e:	e8 2d f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c73:	83 c6 01             	add    $0x1,%esi
f0100c76:	eb 04                	jmp    f0100c7c <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c78:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7c:	8b 12                	mov    (%edx),%edx
f0100c7e:	85 d2                	test   %edx,%edx
f0100c80:	0f 85 c8 fe ff ff    	jne    f0100b4e <check_page_free_list+0x10e>
f0100c86:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c89:	85 f6                	test   %esi,%esi
f0100c8b:	7f 19                	jg     f0100ca6 <check_page_free_list+0x266>
f0100c8d:	68 3a 54 10 f0       	push   $0xf010543a
f0100c92:	68 cd 53 10 f0       	push   $0xf01053cd
f0100c97:	68 aa 02 00 00       	push   $0x2aa
f0100c9c:	68 8d 53 10 f0       	push   $0xf010538d
f0100ca1:	e8 fa f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100ca6:	85 db                	test   %ebx,%ebx
f0100ca8:	7f 19                	jg     f0100cc3 <check_page_free_list+0x283>
f0100caa:	68 4c 54 10 f0       	push   $0xf010544c
f0100caf:	68 cd 53 10 f0       	push   $0xf01053cd
f0100cb4:	68 ab 02 00 00       	push   $0x2ab
f0100cb9:	68 8d 53 10 f0       	push   $0xf010538d
f0100cbe:	e8 dd f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cc3:	83 ec 0c             	sub    $0xc,%esp
f0100cc6:	68 f0 4c 10 f0       	push   $0xf0104cf0
f0100ccb:	e8 1c 22 00 00       	call   f0102eec <cprintf>
}
f0100cd0:	eb 29                	jmp    f0100cfb <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cd2:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0100cd7:	85 c0                	test   %eax,%eax
f0100cd9:	0f 85 8e fd ff ff    	jne    f0100a6d <check_page_free_list+0x2d>
f0100cdf:	e9 72 fd ff ff       	jmp    f0100a56 <check_page_free_list+0x16>
f0100ce4:	83 3d 7c ff 16 f0 00 	cmpl   $0x0,0xf016ff7c
f0100ceb:	0f 84 65 fd ff ff    	je     f0100a56 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cf1:	be 00 04 00 00       	mov    $0x400,%esi
f0100cf6:	e9 c0 fd ff ff       	jmp    f0100abb <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cfe:	5b                   	pop    %ebx
f0100cff:	5e                   	pop    %esi
f0100d00:	5f                   	pop    %edi
f0100d01:	5d                   	pop    %ebp
f0100d02:	c3                   	ret    

f0100d03 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d03:	55                   	push   %ebp
f0100d04:	89 e5                	mov    %esp,%ebp
f0100d06:	56                   	push   %esi
f0100d07:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages -1; i >= 1; i--) 
f0100d08:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0100d0d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d10:	8d 34 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%esi
f0100d17:	eb 6e                	jmp    f0100d87 <page_init+0x84>
	{
		
		if((i >= PGNUM(IOPHYSMEM) && i < PGNUM(EXTPHYSMEM)) || (i >= PGNUM(EXTPHYSMEM) && i< PGNUM(PADDR(boot_alloc(0))))) 
f0100d19:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100d1f:	83 f8 5f             	cmp    $0x5f,%eax
f0100d22:	76 5d                	jbe    f0100d81 <page_init+0x7e>
f0100d24:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100d2a:	76 32                	jbe    f0100d5e <page_init+0x5b>
f0100d2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d31:	e8 90 fc ff ff       	call   f01009c6 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d36:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d3b:	77 15                	ja     f0100d52 <page_init+0x4f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d3d:	50                   	push   %eax
f0100d3e:	68 08 4c 10 f0       	push   $0xf0104c08
f0100d43:	68 32 01 00 00       	push   $0x132
f0100d48:	68 8d 53 10 f0       	push   $0xf010538d
f0100d4d:	e8 4e f3 ff ff       	call   f01000a0 <_panic>
f0100d52:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d57:	c1 e8 0c             	shr    $0xc,%eax
f0100d5a:	39 c3                	cmp    %eax,%ebx
f0100d5c:	72 23                	jb     f0100d81 <page_init+0x7e>
			continue;
		
		else
		{
			pages[i].pp_ref=0;
f0100d5e:	89 f0                	mov    %esi,%eax
f0100d60:	03 05 4c 0c 17 f0    	add    0xf0170c4c,%eax
f0100d66:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d6c:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
f0100d72:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d74:	89 f0                	mov    %esi,%eax
f0100d76:	03 05 4c 0c 17 f0    	add    0xf0170c4c,%eax
f0100d7c:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages -1; i >= 1; i--) 
f0100d81:	83 eb 01             	sub    $0x1,%ebx
f0100d84:	83 ee 08             	sub    $0x8,%esi
f0100d87:	85 db                	test   %ebx,%ebx
f0100d89:	75 8e                	jne    f0100d19 <page_init+0x16>
			pages[i].pp_ref=0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d8b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d8e:	5b                   	pop    %ebx
f0100d8f:	5e                   	pop    %esi
f0100d90:	5d                   	pop    %ebp
f0100d91:	c3                   	ret    

f0100d92 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d92:	55                   	push   %ebp
f0100d93:	89 e5                	mov    %esp,%ebp
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	
	if(!page_free_list)
f0100d99:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
f0100d9f:	85 db                	test   %ebx,%ebx
f0100da1:	74 58                	je     f0100dfb <page_alloc+0x69>
		return NULL;	

	struct PageInfo * pa_page = page_free_list;		

	page_free_list = pa_page->pp_link;
f0100da3:	8b 03                	mov    (%ebx),%eax
f0100da5:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c

	pa_page->pp_link = NULL;
f0100daa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100db0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100db4:	74 45                	je     f0100dfb <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db6:	89 d8                	mov    %ebx,%eax
f0100db8:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100dbe:	c1 f8 03             	sar    $0x3,%eax
f0100dc1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc4:	89 c2                	mov    %eax,%edx
f0100dc6:	c1 ea 0c             	shr    $0xc,%edx
f0100dc9:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100dcf:	72 12                	jb     f0100de3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd1:	50                   	push   %eax
f0100dd2:	68 e4 4b 10 f0       	push   $0xf0104be4
f0100dd7:	6a 56                	push   $0x56
f0100dd9:	68 b3 53 10 f0       	push   $0xf01053b3
f0100dde:	e8 bd f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(pa_page),'\0',PGSIZE);
f0100de3:	83 ec 04             	sub    $0x4,%esp
f0100de6:	68 00 10 00 00       	push   $0x1000
f0100deb:	6a 00                	push   $0x0
f0100ded:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100df2:	50                   	push   %eax
f0100df3:	e8 1c 34 00 00       	call   f0104214 <memset>
f0100df8:	83 c4 10             	add    $0x10,%esp
	}
	
	return pa_page;
}
f0100dfb:	89 d8                	mov    %ebx,%eax
f0100dfd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e00:	c9                   	leave  
f0100e01:	c3                   	ret    

f0100e02 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e02:	55                   	push   %ebp
f0100e03:	89 e5                	mov    %esp,%ebp
f0100e05:	83 ec 08             	sub    $0x8,%esp
f0100e08:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_link || pp->pp_ref)
f0100e0b:	83 38 00             	cmpl   $0x0,(%eax)
f0100e0e:	75 07                	jne    f0100e17 <page_free+0x15>
f0100e10:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e15:	74 17                	je     f0100e2e <page_free+0x2c>
		panic("Trying to free page in use!");
f0100e17:	83 ec 04             	sub    $0x4,%esp
f0100e1a:	68 5d 54 10 f0       	push   $0xf010545d
f0100e1f:	68 68 01 00 00       	push   $0x168
f0100e24:	68 8d 53 10 f0       	push   $0xf010538d
f0100e29:	e8 72 f2 ff ff       	call   f01000a0 <_panic>

	pp->pp_link=page_free_list;
f0100e2e:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
f0100e34:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100e36:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c

	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100e3b:	c9                   	leave  
f0100e3c:	c3                   	ret    

f0100e3d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e3d:	55                   	push   %ebp
f0100e3e:	89 e5                	mov    %esp,%ebp
f0100e40:	83 ec 08             	sub    $0x8,%esp
f0100e43:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e46:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e4a:	83 e8 01             	sub    $0x1,%eax
f0100e4d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e51:	66 85 c0             	test   %ax,%ax
f0100e54:	75 0c                	jne    f0100e62 <page_decref+0x25>
		page_free(pp);
f0100e56:	83 ec 0c             	sub    $0xc,%esp
f0100e59:	52                   	push   %edx
f0100e5a:	e8 a3 ff ff ff       	call   f0100e02 <page_free>
f0100e5f:	83 c4 10             	add    $0x10,%esp
}
f0100e62:	c9                   	leave  
f0100e63:	c3                   	ret    

f0100e64 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	56                   	push   %esi
f0100e68:	53                   	push   %ebx
f0100e69:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	
	pde_t *pde = &pgdir[PDX(va)];
f0100e6c:	89 f3                	mov    %esi,%ebx
f0100e6e:	c1 eb 16             	shr    $0x16,%ebx
f0100e71:	c1 e3 02             	shl    $0x2,%ebx
f0100e74:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pde & PTE_P))
f0100e77:	f6 03 01             	testb  $0x1,(%ebx)
f0100e7a:	75 2d                	jne    f0100ea9 <pgdir_walk+0x45>
	{
		if(!create)
f0100e7c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e80:	74 62                	je     f0100ee4 <pgdir_walk+0x80>
			return NULL;

		struct PageInfo *pp = page_alloc(ALLOC_ZERO);
f0100e82:	83 ec 0c             	sub    $0xc,%esp
f0100e85:	6a 01                	push   $0x1
f0100e87:	e8 06 ff ff ff       	call   f0100d92 <page_alloc>

		if(!pp)
f0100e8c:	83 c4 10             	add    $0x10,%esp
f0100e8f:	85 c0                	test   %eax,%eax
f0100e91:	74 58                	je     f0100eeb <pgdir_walk+0x87>
			return NULL;

		pp->pp_ref++;
f0100e93:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pde = page2pa(pp)|PTE_P|PTE_W|PTE_U;
f0100e98:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100e9e:	c1 f8 03             	sar    $0x3,%eax
f0100ea1:	c1 e0 0c             	shl    $0xc,%eax
f0100ea4:	83 c8 07             	or     $0x7,%eax
f0100ea7:	89 03                	mov    %eax,(%ebx)
	}

	pte_t *pte = KADDR(PTE_ADDR(*pde));
f0100ea9:	8b 03                	mov    (%ebx),%eax
f0100eab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb0:	89 c2                	mov    %eax,%edx
f0100eb2:	c1 ea 0c             	shr    $0xc,%edx
f0100eb5:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100ebb:	72 15                	jb     f0100ed2 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebd:	50                   	push   %eax
f0100ebe:	68 e4 4b 10 f0       	push   $0xf0104be4
f0100ec3:	68 a8 01 00 00       	push   $0x1a8
f0100ec8:	68 8d 53 10 f0       	push   $0xf010538d
f0100ecd:	e8 ce f1 ff ff       	call   f01000a0 <_panic>
	pte = &pte[PTX(va)];
f0100ed2:	c1 ee 0a             	shr    $0xa,%esi
f0100ed5:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	
	return pte;
f0100edb:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100ee2:	eb 0c                	jmp    f0100ef0 <pgdir_walk+0x8c>
	pde_t *pde = &pgdir[PDX(va)];

	if(!(*pde & PTE_P))
	{
		if(!create)
			return NULL;
f0100ee4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee9:	eb 05                	jmp    f0100ef0 <pgdir_walk+0x8c>

		struct PageInfo *pp = page_alloc(ALLOC_ZERO);

		if(!pp)
			return NULL;
f0100eeb:	b8 00 00 00 00       	mov    $0x0,%eax

	pte_t *pte = KADDR(PTE_ADDR(*pde));
	pte = &pte[PTX(va)];
	
	return pte;
}
f0100ef0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ef3:	5b                   	pop    %ebx
f0100ef4:	5e                   	pop    %esi
f0100ef5:	5d                   	pop    %ebp
f0100ef6:	c3                   	ret    

f0100ef7 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ef7:	55                   	push   %ebp
f0100ef8:	89 e5                	mov    %esp,%ebp
f0100efa:	57                   	push   %edi
f0100efb:	56                   	push   %esi
f0100efc:	53                   	push   %ebx
f0100efd:	83 ec 1c             	sub    $0x1c,%esp
f0100f00:	89 c7                	mov    %eax,%edi
f0100f02:	89 d6                	mov    %edx,%esi
f0100f04:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f07:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
		*pte = (pa+i)|perm|PTE_P;
f0100f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0f:	83 c8 01             	or     $0x1,%eax
f0100f12:	89 45 e0             	mov    %eax,-0x20(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f15:	eb 22                	jmp    f0100f39 <boot_map_region+0x42>
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
f0100f17:	83 ec 04             	sub    $0x4,%esp
f0100f1a:	6a 01                	push   $0x1
f0100f1c:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0100f1f:	50                   	push   %eax
f0100f20:	57                   	push   %edi
f0100f21:	e8 3e ff ff ff       	call   f0100e64 <pgdir_walk>
		*pte = (pa+i)|perm|PTE_P;
f0100f26:	89 da                	mov    %ebx,%edx
f0100f28:	03 55 08             	add    0x8(%ebp),%edx
f0100f2b:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f30:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f36:	83 c4 10             	add    $0x10,%esp
f0100f39:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f3c:	77 d9                	ja     f0100f17 <boot_map_region+0x20>
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
		*pte = (pa+i)|perm|PTE_P;
	}
}
f0100f3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f41:	5b                   	pop    %ebx
f0100f42:	5e                   	pop    %esi
f0100f43:	5f                   	pop    %edi
f0100f44:	5d                   	pop    %ebp
f0100f45:	c3                   	ret    

f0100f46 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f0100f4c:	6a 00                	push   $0x0
f0100f4e:	ff 75 0c             	pushl  0xc(%ebp)
f0100f51:	ff 75 08             	pushl  0x8(%ebp)
f0100f54:	e8 0b ff ff ff       	call   f0100e64 <pgdir_walk>

	if((!pte) || !(*pte & PTE_P))
f0100f59:	83 c4 10             	add    $0x10,%esp
f0100f5c:	85 c0                	test   %eax,%eax
f0100f5e:	74 30                	je     f0100f90 <page_lookup+0x4a>
f0100f60:	8b 00                	mov    (%eax),%eax
f0100f62:	a8 01                	test   $0x1,%al
f0100f64:	74 31                	je     f0100f97 <page_lookup+0x51>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f66:	c1 e8 0c             	shr    $0xc,%eax
f0100f69:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0100f6f:	72 14                	jb     f0100f85 <page_lookup+0x3f>
		panic("pa2page called with invalid pa");
f0100f71:	83 ec 04             	sub    $0x4,%esp
f0100f74:	68 14 4d 10 f0       	push   $0xf0104d14
f0100f79:	6a 4f                	push   $0x4f
f0100f7b:	68 b3 53 10 f0       	push   $0xf01053b3
f0100f80:	e8 1b f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f85:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
f0100f8b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		return NULL;

	if(pte_store)
		pte_store = &pte;	

	return pa2page(PTE_ADDR(*pte));
f0100f8e:	eb 0c                	jmp    f0100f9c <page_lookup+0x56>
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);

	if((!pte) || !(*pte & PTE_P))
		return NULL;
f0100f90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f95:	eb 05                	jmp    f0100f9c <page_lookup+0x56>
f0100f97:	b8 00 00 00 00       	mov    $0x0,%eax

	if(pte_store)
		pte_store = &pte;	

	return pa2page(PTE_ADDR(*pte));
}
f0100f9c:	c9                   	leave  
f0100f9d:	c3                   	ret    

f0100f9e <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f9e:	55                   	push   %ebp
f0100f9f:	89 e5                	mov    %esp,%ebp
f0100fa1:	56                   	push   %esi
f0100fa2:	53                   	push   %ebx
f0100fa3:	83 ec 14             	sub    $0x14,%esp
f0100fa6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fa9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f0100fac:	6a 00                	push   $0x0
f0100fae:	53                   	push   %ebx
f0100faf:	56                   	push   %esi
f0100fb0:	e8 af fe ff ff       	call   f0100e64 <pgdir_walk>
f0100fb5:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(*pte & PTE_P)
f0100fb8:	83 c4 10             	add    $0x10,%esp
f0100fbb:	f6 00 01             	testb  $0x1,(%eax)
f0100fbe:	74 25                	je     f0100fe5 <page_remove+0x47>
	{
		page_decref(page_lookup(pgdir,va,&pte));
f0100fc0:	83 ec 04             	sub    $0x4,%esp
f0100fc3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	53                   	push   %ebx
f0100fc8:	56                   	push   %esi
f0100fc9:	e8 78 ff ff ff       	call   f0100f46 <page_lookup>
f0100fce:	89 04 24             	mov    %eax,(%esp)
f0100fd1:	e8 67 fe ff ff       	call   f0100e3d <page_decref>
		*pte = 0;
f0100fd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fd9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fdf:	0f 01 3b             	invlpg (%ebx)
f0100fe2:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir,va);
	}
}
f0100fe5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fe8:	5b                   	pop    %ebx
f0100fe9:	5e                   	pop    %esi
f0100fea:	5d                   	pop    %ebp
f0100feb:	c3                   	ret    

f0100fec <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fec:	55                   	push   %ebp
f0100fed:	89 e5                	mov    %esp,%ebp
f0100fef:	57                   	push   %edi
f0100ff0:	56                   	push   %esi
f0100ff1:	53                   	push   %ebx
f0100ff2:	83 ec 10             	sub    $0x10,%esp
f0100ff5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,1);
f0100ffb:	6a 01                	push   $0x1
f0100ffd:	57                   	push   %edi
f0100ffe:	ff 75 08             	pushl  0x8(%ebp)
f0101001:	e8 5e fe ff ff       	call   f0100e64 <pgdir_walk>
	
	if(!pte)
f0101006:	83 c4 10             	add    $0x10,%esp
f0101009:	85 c0                	test   %eax,%eax
f010100b:	74 57                	je     f0101064 <page_insert+0x78>
f010100d:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	if(*pte & PTE_P)
f010100f:	8b 00                	mov    (%eax),%eax
f0101011:	a8 01                	test   $0x1,%al
f0101013:	74 2d                	je     f0101042 <page_insert+0x56>
	{
		if(PTE_ADDR(*pte) != page2pa(pp))
f0101015:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010101a:	89 da                	mov    %ebx,%edx
f010101c:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101022:	c1 fa 03             	sar    $0x3,%edx
f0101025:	c1 e2 0c             	shl    $0xc,%edx
f0101028:	39 d0                	cmp    %edx,%eax
f010102a:	74 11                	je     f010103d <page_insert+0x51>
			page_remove(pgdir,va);
f010102c:	83 ec 08             	sub    $0x8,%esp
f010102f:	57                   	push   %edi
f0101030:	ff 75 08             	pushl  0x8(%ebp)
f0101033:	e8 66 ff ff ff       	call   f0100f9e <page_remove>
f0101038:	83 c4 10             	add    $0x10,%esp
f010103b:	eb 05                	jmp    f0101042 <page_insert+0x56>
		else
			pp->pp_ref--;
f010103d:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
		
	}

	pp->pp_ref++;
f0101042:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

	*pte = page2pa(pp)|perm|PTE_P;	
f0101047:	2b 1d 4c 0c 17 f0    	sub    0xf0170c4c,%ebx
f010104d:	c1 fb 03             	sar    $0x3,%ebx
f0101050:	c1 e3 0c             	shl    $0xc,%ebx
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	83 c8 01             	or     $0x1,%eax
f0101059:	09 c3                	or     %eax,%ebx
f010105b:	89 1e                	mov    %ebx,(%esi)

	return 0;
f010105d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101062:	eb 05                	jmp    f0101069 <page_insert+0x7d>
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,1);
	
	if(!pte)
		return -E_NO_MEM;
f0101064:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;

	*pte = page2pa(pp)|perm|PTE_P;	

	return 0;
}
f0101069:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010106c:	5b                   	pop    %ebx
f010106d:	5e                   	pop    %esi
f010106e:	5f                   	pop    %edi
f010106f:	5d                   	pop    %ebp
f0101070:	c3                   	ret    

f0101071 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101071:	55                   	push   %ebp
f0101072:	89 e5                	mov    %esp,%ebp
f0101074:	57                   	push   %edi
f0101075:	56                   	push   %esi
f0101076:	53                   	push   %ebx
f0101077:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010107a:	b8 15 00 00 00       	mov    $0x15,%eax
f010107f:	e8 b5 f8 ff ff       	call   f0100939 <nvram_read>
f0101084:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101086:	b8 17 00 00 00       	mov    $0x17,%eax
f010108b:	e8 a9 f8 ff ff       	call   f0100939 <nvram_read>
f0101090:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101092:	b8 34 00 00 00       	mov    $0x34,%eax
f0101097:	e8 9d f8 ff ff       	call   f0100939 <nvram_read>
f010109c:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010109f:	85 c0                	test   %eax,%eax
f01010a1:	74 07                	je     f01010aa <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010a3:	05 00 40 00 00       	add    $0x4000,%eax
f01010a8:	eb 0b                	jmp    f01010b5 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010aa:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010b0:	85 f6                	test   %esi,%esi
f01010b2:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010b5:	89 c2                	mov    %eax,%edx
f01010b7:	c1 ea 02             	shr    $0x2,%edx
f01010ba:	89 15 44 0c 17 f0    	mov    %edx,0xf0170c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010c0:	89 c2                	mov    %eax,%edx
f01010c2:	29 da                	sub    %ebx,%edx
f01010c4:	52                   	push   %edx
f01010c5:	53                   	push   %ebx
f01010c6:	50                   	push   %eax
f01010c7:	68 34 4d 10 f0       	push   $0xf0104d34
f01010cc:	e8 1b 1e 00 00       	call   f0102eec <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010d1:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010d6:	e8 eb f8 ff ff       	call   f01009c6 <boot_alloc>
f01010db:	a3 48 0c 17 f0       	mov    %eax,0xf0170c48
	memset(kern_pgdir, 0, PGSIZE);
f01010e0:	83 c4 0c             	add    $0xc,%esp
f01010e3:	68 00 10 00 00       	push   $0x1000
f01010e8:	6a 00                	push   $0x0
f01010ea:	50                   	push   %eax
f01010eb:	e8 24 31 00 00       	call   f0104214 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010f0:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010f5:	83 c4 10             	add    $0x10,%esp
f01010f8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010fd:	77 15                	ja     f0101114 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010ff:	50                   	push   %eax
f0101100:	68 08 4c 10 f0       	push   $0xf0104c08
f0101105:	68 9f 00 00 00       	push   $0x9f
f010110a:	68 8d 53 10 f0       	push   $0xf010538d
f010110f:	e8 8c ef ff ff       	call   f01000a0 <_panic>
f0101114:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010111a:	83 ca 05             	or     $0x5,%edx
f010111d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages=(struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f0101123:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0101128:	c1 e0 03             	shl    $0x3,%eax
f010112b:	e8 96 f8 ff ff       	call   f01009c6 <boot_alloc>
f0101130:	a3 4c 0c 17 f0       	mov    %eax,0xf0170c4c

	memset(pages,0,npages*sizeof(struct PageInfo));
f0101135:	83 ec 04             	sub    $0x4,%esp
f0101138:	8b 3d 44 0c 17 f0    	mov    0xf0170c44,%edi
f010113e:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101145:	52                   	push   %edx
f0101146:	6a 00                	push   $0x0
f0101148:	50                   	push   %eax
f0101149:	e8 c6 30 00 00       	call   f0104214 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f010114e:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101153:	e8 6e f8 ff ff       	call   f01009c6 <boot_alloc>
f0101158:	a3 84 ff 16 f0       	mov    %eax,0xf016ff84
 
        memset(envs,0,NENV*sizeof(struct Env));
f010115d:	83 c4 0c             	add    $0xc,%esp
f0101160:	68 00 80 01 00       	push   $0x18000
f0101165:	6a 00                	push   $0x0
f0101167:	50                   	push   %eax
f0101168:	e8 a7 30 00 00       	call   f0104214 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010116d:	e8 91 fb ff ff       	call   f0100d03 <page_init>

	check_page_free_list(1);
f0101172:	b8 01 00 00 00       	mov    $0x1,%eax
f0101177:	e8 c4 f8 ff ff       	call   f0100a40 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010117c:	83 c4 10             	add    $0x10,%esp
f010117f:	83 3d 4c 0c 17 f0 00 	cmpl   $0x0,0xf0170c4c
f0101186:	75 17                	jne    f010119f <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f0101188:	83 ec 04             	sub    $0x4,%esp
f010118b:	68 79 54 10 f0       	push   $0xf0105479
f0101190:	68 be 02 00 00       	push   $0x2be
f0101195:	68 8d 53 10 f0       	push   $0xf010538d
f010119a:	e8 01 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010119f:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f01011a4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011a9:	eb 05                	jmp    f01011b0 <mem_init+0x13f>
		++nfree;
f01011ab:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011ae:	8b 00                	mov    (%eax),%eax
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	75 f7                	jne    f01011ab <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
//	cprintf("pagealloc(0):%p\n",page_alloc(0));
	assert((pp0 = page_alloc(0)));
f01011b4:	83 ec 0c             	sub    $0xc,%esp
f01011b7:	6a 00                	push   $0x0
f01011b9:	e8 d4 fb ff ff       	call   f0100d92 <page_alloc>
f01011be:	89 c7                	mov    %eax,%edi
f01011c0:	83 c4 10             	add    $0x10,%esp
f01011c3:	85 c0                	test   %eax,%eax
f01011c5:	75 19                	jne    f01011e0 <mem_init+0x16f>
f01011c7:	68 94 54 10 f0       	push   $0xf0105494
f01011cc:	68 cd 53 10 f0       	push   $0xf01053cd
f01011d1:	68 c7 02 00 00       	push   $0x2c7
f01011d6:	68 8d 53 10 f0       	push   $0xf010538d
f01011db:	e8 c0 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011e0:	83 ec 0c             	sub    $0xc,%esp
f01011e3:	6a 00                	push   $0x0
f01011e5:	e8 a8 fb ff ff       	call   f0100d92 <page_alloc>
f01011ea:	89 c6                	mov    %eax,%esi
f01011ec:	83 c4 10             	add    $0x10,%esp
f01011ef:	85 c0                	test   %eax,%eax
f01011f1:	75 19                	jne    f010120c <mem_init+0x19b>
f01011f3:	68 aa 54 10 f0       	push   $0xf01054aa
f01011f8:	68 cd 53 10 f0       	push   $0xf01053cd
f01011fd:	68 c8 02 00 00       	push   $0x2c8
f0101202:	68 8d 53 10 f0       	push   $0xf010538d
f0101207:	e8 94 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010120c:	83 ec 0c             	sub    $0xc,%esp
f010120f:	6a 00                	push   $0x0
f0101211:	e8 7c fb ff ff       	call   f0100d92 <page_alloc>
f0101216:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101219:	83 c4 10             	add    $0x10,%esp
f010121c:	85 c0                	test   %eax,%eax
f010121e:	75 19                	jne    f0101239 <mem_init+0x1c8>
f0101220:	68 c0 54 10 f0       	push   $0xf01054c0
f0101225:	68 cd 53 10 f0       	push   $0xf01053cd
f010122a:	68 c9 02 00 00       	push   $0x2c9
f010122f:	68 8d 53 10 f0       	push   $0xf010538d
f0101234:	e8 67 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101239:	39 f7                	cmp    %esi,%edi
f010123b:	75 19                	jne    f0101256 <mem_init+0x1e5>
f010123d:	68 d6 54 10 f0       	push   $0xf01054d6
f0101242:	68 cd 53 10 f0       	push   $0xf01053cd
f0101247:	68 cc 02 00 00       	push   $0x2cc
f010124c:	68 8d 53 10 f0       	push   $0xf010538d
f0101251:	e8 4a ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101256:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101259:	39 c6                	cmp    %eax,%esi
f010125b:	74 04                	je     f0101261 <mem_init+0x1f0>
f010125d:	39 c7                	cmp    %eax,%edi
f010125f:	75 19                	jne    f010127a <mem_init+0x209>
f0101261:	68 70 4d 10 f0       	push   $0xf0104d70
f0101266:	68 cd 53 10 f0       	push   $0xf01053cd
f010126b:	68 cd 02 00 00       	push   $0x2cd
f0101270:	68 8d 53 10 f0       	push   $0xf010538d
f0101275:	e8 26 ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010127a:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101280:	8b 15 44 0c 17 f0    	mov    0xf0170c44,%edx
f0101286:	c1 e2 0c             	shl    $0xc,%edx
f0101289:	89 f8                	mov    %edi,%eax
f010128b:	29 c8                	sub    %ecx,%eax
f010128d:	c1 f8 03             	sar    $0x3,%eax
f0101290:	c1 e0 0c             	shl    $0xc,%eax
f0101293:	39 d0                	cmp    %edx,%eax
f0101295:	72 19                	jb     f01012b0 <mem_init+0x23f>
f0101297:	68 e8 54 10 f0       	push   $0xf01054e8
f010129c:	68 cd 53 10 f0       	push   $0xf01053cd
f01012a1:	68 ce 02 00 00       	push   $0x2ce
f01012a6:	68 8d 53 10 f0       	push   $0xf010538d
f01012ab:	e8 f0 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012b0:	89 f0                	mov    %esi,%eax
f01012b2:	29 c8                	sub    %ecx,%eax
f01012b4:	c1 f8 03             	sar    $0x3,%eax
f01012b7:	c1 e0 0c             	shl    $0xc,%eax
f01012ba:	39 c2                	cmp    %eax,%edx
f01012bc:	77 19                	ja     f01012d7 <mem_init+0x266>
f01012be:	68 05 55 10 f0       	push   $0xf0105505
f01012c3:	68 cd 53 10 f0       	push   $0xf01053cd
f01012c8:	68 cf 02 00 00       	push   $0x2cf
f01012cd:	68 8d 53 10 f0       	push   $0xf010538d
f01012d2:	e8 c9 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012da:	29 c8                	sub    %ecx,%eax
f01012dc:	c1 f8 03             	sar    $0x3,%eax
f01012df:	c1 e0 0c             	shl    $0xc,%eax
f01012e2:	39 c2                	cmp    %eax,%edx
f01012e4:	77 19                	ja     f01012ff <mem_init+0x28e>
f01012e6:	68 22 55 10 f0       	push   $0xf0105522
f01012eb:	68 cd 53 10 f0       	push   $0xf01053cd
f01012f0:	68 d0 02 00 00       	push   $0x2d0
f01012f5:	68 8d 53 10 f0       	push   $0xf010538d
f01012fa:	e8 a1 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012ff:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0101304:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101307:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f010130e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101311:	83 ec 0c             	sub    $0xc,%esp
f0101314:	6a 00                	push   $0x0
f0101316:	e8 77 fa ff ff       	call   f0100d92 <page_alloc>
f010131b:	83 c4 10             	add    $0x10,%esp
f010131e:	85 c0                	test   %eax,%eax
f0101320:	74 19                	je     f010133b <mem_init+0x2ca>
f0101322:	68 3f 55 10 f0       	push   $0xf010553f
f0101327:	68 cd 53 10 f0       	push   $0xf01053cd
f010132c:	68 d7 02 00 00       	push   $0x2d7
f0101331:	68 8d 53 10 f0       	push   $0xf010538d
f0101336:	e8 65 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010133b:	83 ec 0c             	sub    $0xc,%esp
f010133e:	57                   	push   %edi
f010133f:	e8 be fa ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f0101344:	89 34 24             	mov    %esi,(%esp)
f0101347:	e8 b6 fa ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f010134c:	83 c4 04             	add    $0x4,%esp
f010134f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101352:	e8 ab fa ff ff       	call   f0100e02 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101357:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010135e:	e8 2f fa ff ff       	call   f0100d92 <page_alloc>
f0101363:	89 c6                	mov    %eax,%esi
f0101365:	83 c4 10             	add    $0x10,%esp
f0101368:	85 c0                	test   %eax,%eax
f010136a:	75 19                	jne    f0101385 <mem_init+0x314>
f010136c:	68 94 54 10 f0       	push   $0xf0105494
f0101371:	68 cd 53 10 f0       	push   $0xf01053cd
f0101376:	68 de 02 00 00       	push   $0x2de
f010137b:	68 8d 53 10 f0       	push   $0xf010538d
f0101380:	e8 1b ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101385:	83 ec 0c             	sub    $0xc,%esp
f0101388:	6a 00                	push   $0x0
f010138a:	e8 03 fa ff ff       	call   f0100d92 <page_alloc>
f010138f:	89 c7                	mov    %eax,%edi
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	85 c0                	test   %eax,%eax
f0101396:	75 19                	jne    f01013b1 <mem_init+0x340>
f0101398:	68 aa 54 10 f0       	push   $0xf01054aa
f010139d:	68 cd 53 10 f0       	push   $0xf01053cd
f01013a2:	68 df 02 00 00       	push   $0x2df
f01013a7:	68 8d 53 10 f0       	push   $0xf010538d
f01013ac:	e8 ef ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b1:	83 ec 0c             	sub    $0xc,%esp
f01013b4:	6a 00                	push   $0x0
f01013b6:	e8 d7 f9 ff ff       	call   f0100d92 <page_alloc>
f01013bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013be:	83 c4 10             	add    $0x10,%esp
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	75 19                	jne    f01013de <mem_init+0x36d>
f01013c5:	68 c0 54 10 f0       	push   $0xf01054c0
f01013ca:	68 cd 53 10 f0       	push   $0xf01053cd
f01013cf:	68 e0 02 00 00       	push   $0x2e0
f01013d4:	68 8d 53 10 f0       	push   $0xf010538d
f01013d9:	e8 c2 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013de:	39 fe                	cmp    %edi,%esi
f01013e0:	75 19                	jne    f01013fb <mem_init+0x38a>
f01013e2:	68 d6 54 10 f0       	push   $0xf01054d6
f01013e7:	68 cd 53 10 f0       	push   $0xf01053cd
f01013ec:	68 e2 02 00 00       	push   $0x2e2
f01013f1:	68 8d 53 10 f0       	push   $0xf010538d
f01013f6:	e8 a5 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013fe:	39 c7                	cmp    %eax,%edi
f0101400:	74 04                	je     f0101406 <mem_init+0x395>
f0101402:	39 c6                	cmp    %eax,%esi
f0101404:	75 19                	jne    f010141f <mem_init+0x3ae>
f0101406:	68 70 4d 10 f0       	push   $0xf0104d70
f010140b:	68 cd 53 10 f0       	push   $0xf01053cd
f0101410:	68 e3 02 00 00       	push   $0x2e3
f0101415:	68 8d 53 10 f0       	push   $0xf010538d
f010141a:	e8 81 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010141f:	83 ec 0c             	sub    $0xc,%esp
f0101422:	6a 00                	push   $0x0
f0101424:	e8 69 f9 ff ff       	call   f0100d92 <page_alloc>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	85 c0                	test   %eax,%eax
f010142e:	74 19                	je     f0101449 <mem_init+0x3d8>
f0101430:	68 3f 55 10 f0       	push   $0xf010553f
f0101435:	68 cd 53 10 f0       	push   $0xf01053cd
f010143a:	68 e4 02 00 00       	push   $0x2e4
f010143f:	68 8d 53 10 f0       	push   $0xf010538d
f0101444:	e8 57 ec ff ff       	call   f01000a0 <_panic>
f0101449:	89 f0                	mov    %esi,%eax
f010144b:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101451:	c1 f8 03             	sar    $0x3,%eax
f0101454:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101457:	89 c2                	mov    %eax,%edx
f0101459:	c1 ea 0c             	shr    $0xc,%edx
f010145c:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0101462:	72 12                	jb     f0101476 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101464:	50                   	push   %eax
f0101465:	68 e4 4b 10 f0       	push   $0xf0104be4
f010146a:	6a 56                	push   $0x56
f010146c:	68 b3 53 10 f0       	push   $0xf01053b3
f0101471:	e8 2a ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101476:	83 ec 04             	sub    $0x4,%esp
f0101479:	68 00 10 00 00       	push   $0x1000
f010147e:	6a 01                	push   $0x1
f0101480:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101485:	50                   	push   %eax
f0101486:	e8 89 2d 00 00       	call   f0104214 <memset>
	page_free(pp0);
f010148b:	89 34 24             	mov    %esi,(%esp)
f010148e:	e8 6f f9 ff ff       	call   f0100e02 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101493:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010149a:	e8 f3 f8 ff ff       	call   f0100d92 <page_alloc>
f010149f:	83 c4 10             	add    $0x10,%esp
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	75 19                	jne    f01014bf <mem_init+0x44e>
f01014a6:	68 4e 55 10 f0       	push   $0xf010554e
f01014ab:	68 cd 53 10 f0       	push   $0xf01053cd
f01014b0:	68 e9 02 00 00       	push   $0x2e9
f01014b5:	68 8d 53 10 f0       	push   $0xf010538d
f01014ba:	e8 e1 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014bf:	39 c6                	cmp    %eax,%esi
f01014c1:	74 19                	je     f01014dc <mem_init+0x46b>
f01014c3:	68 6c 55 10 f0       	push   $0xf010556c
f01014c8:	68 cd 53 10 f0       	push   $0xf01053cd
f01014cd:	68 ea 02 00 00       	push   $0x2ea
f01014d2:	68 8d 53 10 f0       	push   $0xf010538d
f01014d7:	e8 c4 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014dc:	89 f0                	mov    %esi,%eax
f01014de:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01014e4:	c1 f8 03             	sar    $0x3,%eax
f01014e7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ea:	89 c2                	mov    %eax,%edx
f01014ec:	c1 ea 0c             	shr    $0xc,%edx
f01014ef:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01014f5:	72 12                	jb     f0101509 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f7:	50                   	push   %eax
f01014f8:	68 e4 4b 10 f0       	push   $0xf0104be4
f01014fd:	6a 56                	push   $0x56
f01014ff:	68 b3 53 10 f0       	push   $0xf01053b3
f0101504:	e8 97 eb ff ff       	call   f01000a0 <_panic>
f0101509:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010150f:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101515:	80 38 00             	cmpb   $0x0,(%eax)
f0101518:	74 19                	je     f0101533 <mem_init+0x4c2>
f010151a:	68 7c 55 10 f0       	push   $0xf010557c
f010151f:	68 cd 53 10 f0       	push   $0xf01053cd
f0101524:	68 ed 02 00 00       	push   $0x2ed
f0101529:	68 8d 53 10 f0       	push   $0xf010538d
f010152e:	e8 6d eb ff ff       	call   f01000a0 <_panic>
f0101533:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101536:	39 d0                	cmp    %edx,%eax
f0101538:	75 db                	jne    f0101515 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010153a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010153d:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f0101542:	83 ec 0c             	sub    $0xc,%esp
f0101545:	56                   	push   %esi
f0101546:	e8 b7 f8 ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f010154b:	89 3c 24             	mov    %edi,(%esp)
f010154e:	e8 af f8 ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f0101553:	83 c4 04             	add    $0x4,%esp
f0101556:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101559:	e8 a4 f8 ff ff       	call   f0100e02 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010155e:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0101563:	83 c4 10             	add    $0x10,%esp
f0101566:	eb 05                	jmp    f010156d <mem_init+0x4fc>
		--nfree;
f0101568:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010156b:	8b 00                	mov    (%eax),%eax
f010156d:	85 c0                	test   %eax,%eax
f010156f:	75 f7                	jne    f0101568 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101571:	85 db                	test   %ebx,%ebx
f0101573:	74 19                	je     f010158e <mem_init+0x51d>
f0101575:	68 86 55 10 f0       	push   $0xf0105586
f010157a:	68 cd 53 10 f0       	push   $0xf01053cd
f010157f:	68 fa 02 00 00       	push   $0x2fa
f0101584:	68 8d 53 10 f0       	push   $0xf010538d
f0101589:	e8 12 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010158e:	83 ec 0c             	sub    $0xc,%esp
f0101591:	68 90 4d 10 f0       	push   $0xf0104d90
f0101596:	e8 51 19 00 00       	call   f0102eec <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010159b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a2:	e8 eb f7 ff ff       	call   f0100d92 <page_alloc>
f01015a7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015aa:	83 c4 10             	add    $0x10,%esp
f01015ad:	85 c0                	test   %eax,%eax
f01015af:	75 19                	jne    f01015ca <mem_init+0x559>
f01015b1:	68 94 54 10 f0       	push   $0xf0105494
f01015b6:	68 cd 53 10 f0       	push   $0xf01053cd
f01015bb:	68 59 03 00 00       	push   $0x359
f01015c0:	68 8d 53 10 f0       	push   $0xf010538d
f01015c5:	e8 d6 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ca:	83 ec 0c             	sub    $0xc,%esp
f01015cd:	6a 00                	push   $0x0
f01015cf:	e8 be f7 ff ff       	call   f0100d92 <page_alloc>
f01015d4:	89 c3                	mov    %eax,%ebx
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	75 19                	jne    f01015f6 <mem_init+0x585>
f01015dd:	68 aa 54 10 f0       	push   $0xf01054aa
f01015e2:	68 cd 53 10 f0       	push   $0xf01053cd
f01015e7:	68 5a 03 00 00       	push   $0x35a
f01015ec:	68 8d 53 10 f0       	push   $0xf010538d
f01015f1:	e8 aa ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f6:	83 ec 0c             	sub    $0xc,%esp
f01015f9:	6a 00                	push   $0x0
f01015fb:	e8 92 f7 ff ff       	call   f0100d92 <page_alloc>
f0101600:	89 c6                	mov    %eax,%esi
f0101602:	83 c4 10             	add    $0x10,%esp
f0101605:	85 c0                	test   %eax,%eax
f0101607:	75 19                	jne    f0101622 <mem_init+0x5b1>
f0101609:	68 c0 54 10 f0       	push   $0xf01054c0
f010160e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101613:	68 5b 03 00 00       	push   $0x35b
f0101618:	68 8d 53 10 f0       	push   $0xf010538d
f010161d:	e8 7e ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101622:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101625:	75 19                	jne    f0101640 <mem_init+0x5cf>
f0101627:	68 d6 54 10 f0       	push   $0xf01054d6
f010162c:	68 cd 53 10 f0       	push   $0xf01053cd
f0101631:	68 5e 03 00 00       	push   $0x35e
f0101636:	68 8d 53 10 f0       	push   $0xf010538d
f010163b:	e8 60 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101640:	39 c3                	cmp    %eax,%ebx
f0101642:	74 05                	je     f0101649 <mem_init+0x5d8>
f0101644:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101647:	75 19                	jne    f0101662 <mem_init+0x5f1>
f0101649:	68 70 4d 10 f0       	push   $0xf0104d70
f010164e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101653:	68 5f 03 00 00       	push   $0x35f
f0101658:	68 8d 53 10 f0       	push   $0xf010538d
f010165d:	e8 3e ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101662:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0101667:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010166a:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f0101671:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101674:	83 ec 0c             	sub    $0xc,%esp
f0101677:	6a 00                	push   $0x0
f0101679:	e8 14 f7 ff ff       	call   f0100d92 <page_alloc>
f010167e:	83 c4 10             	add    $0x10,%esp
f0101681:	85 c0                	test   %eax,%eax
f0101683:	74 19                	je     f010169e <mem_init+0x62d>
f0101685:	68 3f 55 10 f0       	push   $0xf010553f
f010168a:	68 cd 53 10 f0       	push   $0xf01053cd
f010168f:	68 66 03 00 00       	push   $0x366
f0101694:	68 8d 53 10 f0       	push   $0xf010538d
f0101699:	e8 02 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010169e:	83 ec 04             	sub    $0x4,%esp
f01016a1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016a4:	50                   	push   %eax
f01016a5:	6a 00                	push   $0x0
f01016a7:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01016ad:	e8 94 f8 ff ff       	call   f0100f46 <page_lookup>
f01016b2:	83 c4 10             	add    $0x10,%esp
f01016b5:	85 c0                	test   %eax,%eax
f01016b7:	74 19                	je     f01016d2 <mem_init+0x661>
f01016b9:	68 b0 4d 10 f0       	push   $0xf0104db0
f01016be:	68 cd 53 10 f0       	push   $0xf01053cd
f01016c3:	68 69 03 00 00       	push   $0x369
f01016c8:	68 8d 53 10 f0       	push   $0xf010538d
f01016cd:	e8 ce e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016d2:	6a 02                	push   $0x2
f01016d4:	6a 00                	push   $0x0
f01016d6:	53                   	push   %ebx
f01016d7:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01016dd:	e8 0a f9 ff ff       	call   f0100fec <page_insert>
f01016e2:	83 c4 10             	add    $0x10,%esp
f01016e5:	85 c0                	test   %eax,%eax
f01016e7:	78 19                	js     f0101702 <mem_init+0x691>
f01016e9:	68 e8 4d 10 f0       	push   $0xf0104de8
f01016ee:	68 cd 53 10 f0       	push   $0xf01053cd
f01016f3:	68 6c 03 00 00       	push   $0x36c
f01016f8:	68 8d 53 10 f0       	push   $0xf010538d
f01016fd:	e8 9e e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101702:	83 ec 0c             	sub    $0xc,%esp
f0101705:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101708:	e8 f5 f6 ff ff       	call   f0100e02 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010170d:	6a 02                	push   $0x2
f010170f:	6a 00                	push   $0x0
f0101711:	53                   	push   %ebx
f0101712:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101718:	e8 cf f8 ff ff       	call   f0100fec <page_insert>
f010171d:	83 c4 20             	add    $0x20,%esp
f0101720:	85 c0                	test   %eax,%eax
f0101722:	74 19                	je     f010173d <mem_init+0x6cc>
f0101724:	68 18 4e 10 f0       	push   $0xf0104e18
f0101729:	68 cd 53 10 f0       	push   $0xf01053cd
f010172e:	68 70 03 00 00       	push   $0x370
f0101733:	68 8d 53 10 f0       	push   $0xf010538d
f0101738:	e8 63 e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010173d:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101743:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0101748:	89 c1                	mov    %eax,%ecx
f010174a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010174d:	8b 17                	mov    (%edi),%edx
f010174f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101755:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101758:	29 c8                	sub    %ecx,%eax
f010175a:	c1 f8 03             	sar    $0x3,%eax
f010175d:	c1 e0 0c             	shl    $0xc,%eax
f0101760:	39 c2                	cmp    %eax,%edx
f0101762:	74 19                	je     f010177d <mem_init+0x70c>
f0101764:	68 48 4e 10 f0       	push   $0xf0104e48
f0101769:	68 cd 53 10 f0       	push   $0xf01053cd
f010176e:	68 71 03 00 00       	push   $0x371
f0101773:	68 8d 53 10 f0       	push   $0xf010538d
f0101778:	e8 23 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010177d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101782:	89 f8                	mov    %edi,%eax
f0101784:	e8 d9 f1 ff ff       	call   f0100962 <check_va2pa>
f0101789:	89 da                	mov    %ebx,%edx
f010178b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010178e:	c1 fa 03             	sar    $0x3,%edx
f0101791:	c1 e2 0c             	shl    $0xc,%edx
f0101794:	39 d0                	cmp    %edx,%eax
f0101796:	74 19                	je     f01017b1 <mem_init+0x740>
f0101798:	68 70 4e 10 f0       	push   $0xf0104e70
f010179d:	68 cd 53 10 f0       	push   $0xf01053cd
f01017a2:	68 72 03 00 00       	push   $0x372
f01017a7:	68 8d 53 10 f0       	push   $0xf010538d
f01017ac:	e8 ef e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017b1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017b6:	74 19                	je     f01017d1 <mem_init+0x760>
f01017b8:	68 91 55 10 f0       	push   $0xf0105591
f01017bd:	68 cd 53 10 f0       	push   $0xf01053cd
f01017c2:	68 73 03 00 00       	push   $0x373
f01017c7:	68 8d 53 10 f0       	push   $0xf010538d
f01017cc:	e8 cf e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017d4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017d9:	74 19                	je     f01017f4 <mem_init+0x783>
f01017db:	68 a2 55 10 f0       	push   $0xf01055a2
f01017e0:	68 cd 53 10 f0       	push   $0xf01053cd
f01017e5:	68 74 03 00 00       	push   $0x374
f01017ea:	68 8d 53 10 f0       	push   $0xf010538d
f01017ef:	e8 ac e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017f4:	6a 02                	push   $0x2
f01017f6:	68 00 10 00 00       	push   $0x1000
f01017fb:	56                   	push   %esi
f01017fc:	57                   	push   %edi
f01017fd:	e8 ea f7 ff ff       	call   f0100fec <page_insert>
f0101802:	83 c4 10             	add    $0x10,%esp
f0101805:	85 c0                	test   %eax,%eax
f0101807:	74 19                	je     f0101822 <mem_init+0x7b1>
f0101809:	68 a0 4e 10 f0       	push   $0xf0104ea0
f010180e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101813:	68 77 03 00 00       	push   $0x377
f0101818:	68 8d 53 10 f0       	push   $0xf010538d
f010181d:	e8 7e e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101822:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101827:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f010182c:	e8 31 f1 ff ff       	call   f0100962 <check_va2pa>
f0101831:	89 f2                	mov    %esi,%edx
f0101833:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101839:	c1 fa 03             	sar    $0x3,%edx
f010183c:	c1 e2 0c             	shl    $0xc,%edx
f010183f:	39 d0                	cmp    %edx,%eax
f0101841:	74 19                	je     f010185c <mem_init+0x7eb>
f0101843:	68 dc 4e 10 f0       	push   $0xf0104edc
f0101848:	68 cd 53 10 f0       	push   $0xf01053cd
f010184d:	68 78 03 00 00       	push   $0x378
f0101852:	68 8d 53 10 f0       	push   $0xf010538d
f0101857:	e8 44 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010185c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101861:	74 19                	je     f010187c <mem_init+0x80b>
f0101863:	68 b3 55 10 f0       	push   $0xf01055b3
f0101868:	68 cd 53 10 f0       	push   $0xf01053cd
f010186d:	68 79 03 00 00       	push   $0x379
f0101872:	68 8d 53 10 f0       	push   $0xf010538d
f0101877:	e8 24 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010187c:	83 ec 0c             	sub    $0xc,%esp
f010187f:	6a 00                	push   $0x0
f0101881:	e8 0c f5 ff ff       	call   f0100d92 <page_alloc>
f0101886:	83 c4 10             	add    $0x10,%esp
f0101889:	85 c0                	test   %eax,%eax
f010188b:	74 19                	je     f01018a6 <mem_init+0x835>
f010188d:	68 3f 55 10 f0       	push   $0xf010553f
f0101892:	68 cd 53 10 f0       	push   $0xf01053cd
f0101897:	68 7c 03 00 00       	push   $0x37c
f010189c:	68 8d 53 10 f0       	push   $0xf010538d
f01018a1:	e8 fa e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018a6:	6a 02                	push   $0x2
f01018a8:	68 00 10 00 00       	push   $0x1000
f01018ad:	56                   	push   %esi
f01018ae:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01018b4:	e8 33 f7 ff ff       	call   f0100fec <page_insert>
f01018b9:	83 c4 10             	add    $0x10,%esp
f01018bc:	85 c0                	test   %eax,%eax
f01018be:	74 19                	je     f01018d9 <mem_init+0x868>
f01018c0:	68 a0 4e 10 f0       	push   $0xf0104ea0
f01018c5:	68 cd 53 10 f0       	push   $0xf01053cd
f01018ca:	68 7f 03 00 00       	push   $0x37f
f01018cf:	68 8d 53 10 f0       	push   $0xf010538d
f01018d4:	e8 c7 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018d9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018de:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01018e3:	e8 7a f0 ff ff       	call   f0100962 <check_va2pa>
f01018e8:	89 f2                	mov    %esi,%edx
f01018ea:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f01018f0:	c1 fa 03             	sar    $0x3,%edx
f01018f3:	c1 e2 0c             	shl    $0xc,%edx
f01018f6:	39 d0                	cmp    %edx,%eax
f01018f8:	74 19                	je     f0101913 <mem_init+0x8a2>
f01018fa:	68 dc 4e 10 f0       	push   $0xf0104edc
f01018ff:	68 cd 53 10 f0       	push   $0xf01053cd
f0101904:	68 80 03 00 00       	push   $0x380
f0101909:	68 8d 53 10 f0       	push   $0xf010538d
f010190e:	e8 8d e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101913:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101918:	74 19                	je     f0101933 <mem_init+0x8c2>
f010191a:	68 b3 55 10 f0       	push   $0xf01055b3
f010191f:	68 cd 53 10 f0       	push   $0xf01053cd
f0101924:	68 81 03 00 00       	push   $0x381
f0101929:	68 8d 53 10 f0       	push   $0xf010538d
f010192e:	e8 6d e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101933:	83 ec 0c             	sub    $0xc,%esp
f0101936:	6a 00                	push   $0x0
f0101938:	e8 55 f4 ff ff       	call   f0100d92 <page_alloc>
f010193d:	83 c4 10             	add    $0x10,%esp
f0101940:	85 c0                	test   %eax,%eax
f0101942:	74 19                	je     f010195d <mem_init+0x8ec>
f0101944:	68 3f 55 10 f0       	push   $0xf010553f
f0101949:	68 cd 53 10 f0       	push   $0xf01053cd
f010194e:	68 85 03 00 00       	push   $0x385
f0101953:	68 8d 53 10 f0       	push   $0xf010538d
f0101958:	e8 43 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010195d:	8b 15 48 0c 17 f0    	mov    0xf0170c48,%edx
f0101963:	8b 02                	mov    (%edx),%eax
f0101965:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010196a:	89 c1                	mov    %eax,%ecx
f010196c:	c1 e9 0c             	shr    $0xc,%ecx
f010196f:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f0101975:	72 15                	jb     f010198c <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101977:	50                   	push   %eax
f0101978:	68 e4 4b 10 f0       	push   $0xf0104be4
f010197d:	68 88 03 00 00       	push   $0x388
f0101982:	68 8d 53 10 f0       	push   $0xf010538d
f0101987:	e8 14 e7 ff ff       	call   f01000a0 <_panic>
f010198c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101991:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101994:	83 ec 04             	sub    $0x4,%esp
f0101997:	6a 00                	push   $0x0
f0101999:	68 00 10 00 00       	push   $0x1000
f010199e:	52                   	push   %edx
f010199f:	e8 c0 f4 ff ff       	call   f0100e64 <pgdir_walk>
f01019a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019a7:	8d 57 04             	lea    0x4(%edi),%edx
f01019aa:	83 c4 10             	add    $0x10,%esp
f01019ad:	39 d0                	cmp    %edx,%eax
f01019af:	74 19                	je     f01019ca <mem_init+0x959>
f01019b1:	68 0c 4f 10 f0       	push   $0xf0104f0c
f01019b6:	68 cd 53 10 f0       	push   $0xf01053cd
f01019bb:	68 89 03 00 00       	push   $0x389
f01019c0:	68 8d 53 10 f0       	push   $0xf010538d
f01019c5:	e8 d6 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019ca:	6a 06                	push   $0x6
f01019cc:	68 00 10 00 00       	push   $0x1000
f01019d1:	56                   	push   %esi
f01019d2:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01019d8:	e8 0f f6 ff ff       	call   f0100fec <page_insert>
f01019dd:	83 c4 10             	add    $0x10,%esp
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	74 19                	je     f01019fd <mem_init+0x98c>
f01019e4:	68 4c 4f 10 f0       	push   $0xf0104f4c
f01019e9:	68 cd 53 10 f0       	push   $0xf01053cd
f01019ee:	68 8c 03 00 00       	push   $0x38c
f01019f3:	68 8d 53 10 f0       	push   $0xf010538d
f01019f8:	e8 a3 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019fd:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101a03:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a08:	89 f8                	mov    %edi,%eax
f0101a0a:	e8 53 ef ff ff       	call   f0100962 <check_va2pa>
f0101a0f:	89 f2                	mov    %esi,%edx
f0101a11:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101a17:	c1 fa 03             	sar    $0x3,%edx
f0101a1a:	c1 e2 0c             	shl    $0xc,%edx
f0101a1d:	39 d0                	cmp    %edx,%eax
f0101a1f:	74 19                	je     f0101a3a <mem_init+0x9c9>
f0101a21:	68 dc 4e 10 f0       	push   $0xf0104edc
f0101a26:	68 cd 53 10 f0       	push   $0xf01053cd
f0101a2b:	68 8d 03 00 00       	push   $0x38d
f0101a30:	68 8d 53 10 f0       	push   $0xf010538d
f0101a35:	e8 66 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a3a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a3f:	74 19                	je     f0101a5a <mem_init+0x9e9>
f0101a41:	68 b3 55 10 f0       	push   $0xf01055b3
f0101a46:	68 cd 53 10 f0       	push   $0xf01053cd
f0101a4b:	68 8e 03 00 00       	push   $0x38e
f0101a50:	68 8d 53 10 f0       	push   $0xf010538d
f0101a55:	e8 46 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a5a:	83 ec 04             	sub    $0x4,%esp
f0101a5d:	6a 00                	push   $0x0
f0101a5f:	68 00 10 00 00       	push   $0x1000
f0101a64:	57                   	push   %edi
f0101a65:	e8 fa f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101a6a:	83 c4 10             	add    $0x10,%esp
f0101a6d:	f6 00 04             	testb  $0x4,(%eax)
f0101a70:	75 19                	jne    f0101a8b <mem_init+0xa1a>
f0101a72:	68 8c 4f 10 f0       	push   $0xf0104f8c
f0101a77:	68 cd 53 10 f0       	push   $0xf01053cd
f0101a7c:	68 8f 03 00 00       	push   $0x38f
f0101a81:	68 8d 53 10 f0       	push   $0xf010538d
f0101a86:	e8 15 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a8b:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101a90:	f6 00 04             	testb  $0x4,(%eax)
f0101a93:	75 19                	jne    f0101aae <mem_init+0xa3d>
f0101a95:	68 c4 55 10 f0       	push   $0xf01055c4
f0101a9a:	68 cd 53 10 f0       	push   $0xf01053cd
f0101a9f:	68 90 03 00 00       	push   $0x390
f0101aa4:	68 8d 53 10 f0       	push   $0xf010538d
f0101aa9:	e8 f2 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aae:	6a 02                	push   $0x2
f0101ab0:	68 00 10 00 00       	push   $0x1000
f0101ab5:	56                   	push   %esi
f0101ab6:	50                   	push   %eax
f0101ab7:	e8 30 f5 ff ff       	call   f0100fec <page_insert>
f0101abc:	83 c4 10             	add    $0x10,%esp
f0101abf:	85 c0                	test   %eax,%eax
f0101ac1:	74 19                	je     f0101adc <mem_init+0xa6b>
f0101ac3:	68 a0 4e 10 f0       	push   $0xf0104ea0
f0101ac8:	68 cd 53 10 f0       	push   $0xf01053cd
f0101acd:	68 93 03 00 00       	push   $0x393
f0101ad2:	68 8d 53 10 f0       	push   $0xf010538d
f0101ad7:	e8 c4 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101adc:	83 ec 04             	sub    $0x4,%esp
f0101adf:	6a 00                	push   $0x0
f0101ae1:	68 00 10 00 00       	push   $0x1000
f0101ae6:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101aec:	e8 73 f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101af1:	83 c4 10             	add    $0x10,%esp
f0101af4:	f6 00 02             	testb  $0x2,(%eax)
f0101af7:	75 19                	jne    f0101b12 <mem_init+0xaa1>
f0101af9:	68 c0 4f 10 f0       	push   $0xf0104fc0
f0101afe:	68 cd 53 10 f0       	push   $0xf01053cd
f0101b03:	68 94 03 00 00       	push   $0x394
f0101b08:	68 8d 53 10 f0       	push   $0xf010538d
f0101b0d:	e8 8e e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b12:	83 ec 04             	sub    $0x4,%esp
f0101b15:	6a 00                	push   $0x0
f0101b17:	68 00 10 00 00       	push   $0x1000
f0101b1c:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b22:	e8 3d f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101b27:	83 c4 10             	add    $0x10,%esp
f0101b2a:	f6 00 04             	testb  $0x4,(%eax)
f0101b2d:	74 19                	je     f0101b48 <mem_init+0xad7>
f0101b2f:	68 f4 4f 10 f0       	push   $0xf0104ff4
f0101b34:	68 cd 53 10 f0       	push   $0xf01053cd
f0101b39:	68 95 03 00 00       	push   $0x395
f0101b3e:	68 8d 53 10 f0       	push   $0xf010538d
f0101b43:	e8 58 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b48:	6a 02                	push   $0x2
f0101b4a:	68 00 00 40 00       	push   $0x400000
f0101b4f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b52:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b58:	e8 8f f4 ff ff       	call   f0100fec <page_insert>
f0101b5d:	83 c4 10             	add    $0x10,%esp
f0101b60:	85 c0                	test   %eax,%eax
f0101b62:	78 19                	js     f0101b7d <mem_init+0xb0c>
f0101b64:	68 2c 50 10 f0       	push   $0xf010502c
f0101b69:	68 cd 53 10 f0       	push   $0xf01053cd
f0101b6e:	68 98 03 00 00       	push   $0x398
f0101b73:	68 8d 53 10 f0       	push   $0xf010538d
f0101b78:	e8 23 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b7d:	6a 02                	push   $0x2
f0101b7f:	68 00 10 00 00       	push   $0x1000
f0101b84:	53                   	push   %ebx
f0101b85:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b8b:	e8 5c f4 ff ff       	call   f0100fec <page_insert>
f0101b90:	83 c4 10             	add    $0x10,%esp
f0101b93:	85 c0                	test   %eax,%eax
f0101b95:	74 19                	je     f0101bb0 <mem_init+0xb3f>
f0101b97:	68 64 50 10 f0       	push   $0xf0105064
f0101b9c:	68 cd 53 10 f0       	push   $0xf01053cd
f0101ba1:	68 9b 03 00 00       	push   $0x39b
f0101ba6:	68 8d 53 10 f0       	push   $0xf010538d
f0101bab:	e8 f0 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bb0:	83 ec 04             	sub    $0x4,%esp
f0101bb3:	6a 00                	push   $0x0
f0101bb5:	68 00 10 00 00       	push   $0x1000
f0101bba:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101bc0:	e8 9f f2 ff ff       	call   f0100e64 <pgdir_walk>
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	f6 00 04             	testb  $0x4,(%eax)
f0101bcb:	74 19                	je     f0101be6 <mem_init+0xb75>
f0101bcd:	68 f4 4f 10 f0       	push   $0xf0104ff4
f0101bd2:	68 cd 53 10 f0       	push   $0xf01053cd
f0101bd7:	68 9c 03 00 00       	push   $0x39c
f0101bdc:	68 8d 53 10 f0       	push   $0xf010538d
f0101be1:	e8 ba e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101be6:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101bec:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bf1:	89 f8                	mov    %edi,%eax
f0101bf3:	e8 6a ed ff ff       	call   f0100962 <check_va2pa>
f0101bf8:	89 c1                	mov    %eax,%ecx
f0101bfa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bfd:	89 d8                	mov    %ebx,%eax
f0101bff:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101c05:	c1 f8 03             	sar    $0x3,%eax
f0101c08:	c1 e0 0c             	shl    $0xc,%eax
f0101c0b:	39 c1                	cmp    %eax,%ecx
f0101c0d:	74 19                	je     f0101c28 <mem_init+0xbb7>
f0101c0f:	68 a0 50 10 f0       	push   $0xf01050a0
f0101c14:	68 cd 53 10 f0       	push   $0xf01053cd
f0101c19:	68 9f 03 00 00       	push   $0x39f
f0101c1e:	68 8d 53 10 f0       	push   $0xf010538d
f0101c23:	e8 78 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c28:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c2d:	89 f8                	mov    %edi,%eax
f0101c2f:	e8 2e ed ff ff       	call   f0100962 <check_va2pa>
f0101c34:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c37:	74 19                	je     f0101c52 <mem_init+0xbe1>
f0101c39:	68 cc 50 10 f0       	push   $0xf01050cc
f0101c3e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101c43:	68 a0 03 00 00       	push   $0x3a0
f0101c48:	68 8d 53 10 f0       	push   $0xf010538d
f0101c4d:	e8 4e e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c52:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c57:	74 19                	je     f0101c72 <mem_init+0xc01>
f0101c59:	68 da 55 10 f0       	push   $0xf01055da
f0101c5e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101c63:	68 a2 03 00 00       	push   $0x3a2
f0101c68:	68 8d 53 10 f0       	push   $0xf010538d
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c72:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c77:	74 19                	je     f0101c92 <mem_init+0xc21>
f0101c79:	68 eb 55 10 f0       	push   $0xf01055eb
f0101c7e:	68 cd 53 10 f0       	push   $0xf01053cd
f0101c83:	68 a3 03 00 00       	push   $0x3a3
f0101c88:	68 8d 53 10 f0       	push   $0xf010538d
f0101c8d:	e8 0e e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c92:	83 ec 0c             	sub    $0xc,%esp
f0101c95:	6a 00                	push   $0x0
f0101c97:	e8 f6 f0 ff ff       	call   f0100d92 <page_alloc>
f0101c9c:	83 c4 10             	add    $0x10,%esp
f0101c9f:	39 c6                	cmp    %eax,%esi
f0101ca1:	75 04                	jne    f0101ca7 <mem_init+0xc36>
f0101ca3:	85 c0                	test   %eax,%eax
f0101ca5:	75 19                	jne    f0101cc0 <mem_init+0xc4f>
f0101ca7:	68 fc 50 10 f0       	push   $0xf01050fc
f0101cac:	68 cd 53 10 f0       	push   $0xf01053cd
f0101cb1:	68 a6 03 00 00       	push   $0x3a6
f0101cb6:	68 8d 53 10 f0       	push   $0xf010538d
f0101cbb:	e8 e0 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cc0:	83 ec 08             	sub    $0x8,%esp
f0101cc3:	6a 00                	push   $0x0
f0101cc5:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101ccb:	e8 ce f2 ff ff       	call   f0100f9e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cd0:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101cd6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cdb:	89 f8                	mov    %edi,%eax
f0101cdd:	e8 80 ec ff ff       	call   f0100962 <check_va2pa>
f0101ce2:	83 c4 10             	add    $0x10,%esp
f0101ce5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ce8:	74 19                	je     f0101d03 <mem_init+0xc92>
f0101cea:	68 20 51 10 f0       	push   $0xf0105120
f0101cef:	68 cd 53 10 f0       	push   $0xf01053cd
f0101cf4:	68 aa 03 00 00       	push   $0x3aa
f0101cf9:	68 8d 53 10 f0       	push   $0xf010538d
f0101cfe:	e8 9d e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d03:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d08:	89 f8                	mov    %edi,%eax
f0101d0a:	e8 53 ec ff ff       	call   f0100962 <check_va2pa>
f0101d0f:	89 da                	mov    %ebx,%edx
f0101d11:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101d17:	c1 fa 03             	sar    $0x3,%edx
f0101d1a:	c1 e2 0c             	shl    $0xc,%edx
f0101d1d:	39 d0                	cmp    %edx,%eax
f0101d1f:	74 19                	je     f0101d3a <mem_init+0xcc9>
f0101d21:	68 cc 50 10 f0       	push   $0xf01050cc
f0101d26:	68 cd 53 10 f0       	push   $0xf01053cd
f0101d2b:	68 ab 03 00 00       	push   $0x3ab
f0101d30:	68 8d 53 10 f0       	push   $0xf010538d
f0101d35:	e8 66 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d3a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xce9>
f0101d41:	68 91 55 10 f0       	push   $0xf0105591
f0101d46:	68 cd 53 10 f0       	push   $0xf01053cd
f0101d4b:	68 ac 03 00 00       	push   $0x3ac
f0101d50:	68 8d 53 10 f0       	push   $0xf010538d
f0101d55:	e8 46 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d5a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d5f:	74 19                	je     f0101d7a <mem_init+0xd09>
f0101d61:	68 eb 55 10 f0       	push   $0xf01055eb
f0101d66:	68 cd 53 10 f0       	push   $0xf01053cd
f0101d6b:	68 ad 03 00 00       	push   $0x3ad
f0101d70:	68 8d 53 10 f0       	push   $0xf010538d
f0101d75:	e8 26 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d7a:	6a 00                	push   $0x0
f0101d7c:	68 00 10 00 00       	push   $0x1000
f0101d81:	53                   	push   %ebx
f0101d82:	57                   	push   %edi
f0101d83:	e8 64 f2 ff ff       	call   f0100fec <page_insert>
f0101d88:	83 c4 10             	add    $0x10,%esp
f0101d8b:	85 c0                	test   %eax,%eax
f0101d8d:	74 19                	je     f0101da8 <mem_init+0xd37>
f0101d8f:	68 44 51 10 f0       	push   $0xf0105144
f0101d94:	68 cd 53 10 f0       	push   $0xf01053cd
f0101d99:	68 b0 03 00 00       	push   $0x3b0
f0101d9e:	68 8d 53 10 f0       	push   $0xf010538d
f0101da3:	e8 f8 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101da8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dad:	75 19                	jne    f0101dc8 <mem_init+0xd57>
f0101daf:	68 fc 55 10 f0       	push   $0xf01055fc
f0101db4:	68 cd 53 10 f0       	push   $0xf01053cd
f0101db9:	68 b1 03 00 00       	push   $0x3b1
f0101dbe:	68 8d 53 10 f0       	push   $0xf010538d
f0101dc3:	e8 d8 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dc8:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dcb:	74 19                	je     f0101de6 <mem_init+0xd75>
f0101dcd:	68 08 56 10 f0       	push   $0xf0105608
f0101dd2:	68 cd 53 10 f0       	push   $0xf01053cd
f0101dd7:	68 b2 03 00 00       	push   $0x3b2
f0101ddc:	68 8d 53 10 f0       	push   $0xf010538d
f0101de1:	e8 ba e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101de6:	83 ec 08             	sub    $0x8,%esp
f0101de9:	68 00 10 00 00       	push   $0x1000
f0101dee:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101df4:	e8 a5 f1 ff ff       	call   f0100f9e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101df9:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101dff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e04:	89 f8                	mov    %edi,%eax
f0101e06:	e8 57 eb ff ff       	call   f0100962 <check_va2pa>
f0101e0b:	83 c4 10             	add    $0x10,%esp
f0101e0e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e11:	74 19                	je     f0101e2c <mem_init+0xdbb>
f0101e13:	68 20 51 10 f0       	push   $0xf0105120
f0101e18:	68 cd 53 10 f0       	push   $0xf01053cd
f0101e1d:	68 b6 03 00 00       	push   $0x3b6
f0101e22:	68 8d 53 10 f0       	push   $0xf010538d
f0101e27:	e8 74 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e2c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e31:	89 f8                	mov    %edi,%eax
f0101e33:	e8 2a eb ff ff       	call   f0100962 <check_va2pa>
f0101e38:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3b:	74 19                	je     f0101e56 <mem_init+0xde5>
f0101e3d:	68 7c 51 10 f0       	push   $0xf010517c
f0101e42:	68 cd 53 10 f0       	push   $0xf01053cd
f0101e47:	68 b7 03 00 00       	push   $0x3b7
f0101e4c:	68 8d 53 10 f0       	push   $0xf010538d
f0101e51:	e8 4a e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e56:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e5b:	74 19                	je     f0101e76 <mem_init+0xe05>
f0101e5d:	68 1d 56 10 f0       	push   $0xf010561d
f0101e62:	68 cd 53 10 f0       	push   $0xf01053cd
f0101e67:	68 b8 03 00 00       	push   $0x3b8
f0101e6c:	68 8d 53 10 f0       	push   $0xf010538d
f0101e71:	e8 2a e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e76:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e7b:	74 19                	je     f0101e96 <mem_init+0xe25>
f0101e7d:	68 eb 55 10 f0       	push   $0xf01055eb
f0101e82:	68 cd 53 10 f0       	push   $0xf01053cd
f0101e87:	68 b9 03 00 00       	push   $0x3b9
f0101e8c:	68 8d 53 10 f0       	push   $0xf010538d
f0101e91:	e8 0a e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e96:	83 ec 0c             	sub    $0xc,%esp
f0101e99:	6a 00                	push   $0x0
f0101e9b:	e8 f2 ee ff ff       	call   f0100d92 <page_alloc>
f0101ea0:	83 c4 10             	add    $0x10,%esp
f0101ea3:	85 c0                	test   %eax,%eax
f0101ea5:	74 04                	je     f0101eab <mem_init+0xe3a>
f0101ea7:	39 c3                	cmp    %eax,%ebx
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xe53>
f0101eab:	68 a4 51 10 f0       	push   $0xf01051a4
f0101eb0:	68 cd 53 10 f0       	push   $0xf01053cd
f0101eb5:	68 bc 03 00 00       	push   $0x3bc
f0101eba:	68 8d 53 10 f0       	push   $0xf010538d
f0101ebf:	e8 dc e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ec4:	83 ec 0c             	sub    $0xc,%esp
f0101ec7:	6a 00                	push   $0x0
f0101ec9:	e8 c4 ee ff ff       	call   f0100d92 <page_alloc>
f0101ece:	83 c4 10             	add    $0x10,%esp
f0101ed1:	85 c0                	test   %eax,%eax
f0101ed3:	74 19                	je     f0101eee <mem_init+0xe7d>
f0101ed5:	68 3f 55 10 f0       	push   $0xf010553f
f0101eda:	68 cd 53 10 f0       	push   $0xf01053cd
f0101edf:	68 bf 03 00 00       	push   $0x3bf
f0101ee4:	68 8d 53 10 f0       	push   $0xf010538d
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eee:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f0101ef4:	8b 11                	mov    (%ecx),%edx
f0101ef6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101efc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eff:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101f05:	c1 f8 03             	sar    $0x3,%eax
f0101f08:	c1 e0 0c             	shl    $0xc,%eax
f0101f0b:	39 c2                	cmp    %eax,%edx
f0101f0d:	74 19                	je     f0101f28 <mem_init+0xeb7>
f0101f0f:	68 48 4e 10 f0       	push   $0xf0104e48
f0101f14:	68 cd 53 10 f0       	push   $0xf01053cd
f0101f19:	68 c2 03 00 00       	push   $0x3c2
f0101f1e:	68 8d 53 10 f0       	push   $0xf010538d
f0101f23:	e8 78 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f28:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f31:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f36:	74 19                	je     f0101f51 <mem_init+0xee0>
f0101f38:	68 a2 55 10 f0       	push   $0xf01055a2
f0101f3d:	68 cd 53 10 f0       	push   $0xf01053cd
f0101f42:	68 c4 03 00 00       	push   $0x3c4
f0101f47:	68 8d 53 10 f0       	push   $0xf010538d
f0101f4c:	e8 4f e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f54:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f5a:	83 ec 0c             	sub    $0xc,%esp
f0101f5d:	50                   	push   %eax
f0101f5e:	e8 9f ee ff ff       	call   f0100e02 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f63:	83 c4 0c             	add    $0xc,%esp
f0101f66:	6a 01                	push   $0x1
f0101f68:	68 00 10 40 00       	push   $0x401000
f0101f6d:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101f73:	e8 ec ee ff ff       	call   f0100e64 <pgdir_walk>
f0101f78:	89 c7                	mov    %eax,%edi
f0101f7a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f7d:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101f82:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f85:	8b 40 04             	mov    0x4(%eax),%eax
f0101f88:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f8d:	8b 0d 44 0c 17 f0    	mov    0xf0170c44,%ecx
f0101f93:	89 c2                	mov    %eax,%edx
f0101f95:	c1 ea 0c             	shr    $0xc,%edx
f0101f98:	83 c4 10             	add    $0x10,%esp
f0101f9b:	39 ca                	cmp    %ecx,%edx
f0101f9d:	72 15                	jb     f0101fb4 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f9f:	50                   	push   %eax
f0101fa0:	68 e4 4b 10 f0       	push   $0xf0104be4
f0101fa5:	68 cb 03 00 00       	push   $0x3cb
f0101faa:	68 8d 53 10 f0       	push   $0xf010538d
f0101faf:	e8 ec e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fb4:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fb9:	39 c7                	cmp    %eax,%edi
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xf65>
f0101fbd:	68 2e 56 10 f0       	push   $0xf010562e
f0101fc2:	68 cd 53 10 f0       	push   $0xf01053cd
f0101fc7:	68 cc 03 00 00       	push   $0x3cc
f0101fcc:	68 8d 53 10 f0       	push   $0xf010538d
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fd6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fd9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fe0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fe9:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101fef:	c1 f8 03             	sar    $0x3,%eax
f0101ff2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ff5:	89 c2                	mov    %eax,%edx
f0101ff7:	c1 ea 0c             	shr    $0xc,%edx
f0101ffa:	39 d1                	cmp    %edx,%ecx
f0101ffc:	77 12                	ja     f0102010 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ffe:	50                   	push   %eax
f0101fff:	68 e4 4b 10 f0       	push   $0xf0104be4
f0102004:	6a 56                	push   $0x56
f0102006:	68 b3 53 10 f0       	push   $0xf01053b3
f010200b:	e8 90 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102010:	83 ec 04             	sub    $0x4,%esp
f0102013:	68 00 10 00 00       	push   $0x1000
f0102018:	68 ff 00 00 00       	push   $0xff
f010201d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102022:	50                   	push   %eax
f0102023:	e8 ec 21 00 00       	call   f0104214 <memset>
	page_free(pp0);
f0102028:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010202b:	89 3c 24             	mov    %edi,(%esp)
f010202e:	e8 cf ed ff ff       	call   f0100e02 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102033:	83 c4 0c             	add    $0xc,%esp
f0102036:	6a 01                	push   $0x1
f0102038:	6a 00                	push   $0x0
f010203a:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102040:	e8 1f ee ff ff       	call   f0100e64 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102045:	89 fa                	mov    %edi,%edx
f0102047:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f010204d:	c1 fa 03             	sar    $0x3,%edx
f0102050:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102053:	89 d0                	mov    %edx,%eax
f0102055:	c1 e8 0c             	shr    $0xc,%eax
f0102058:	83 c4 10             	add    $0x10,%esp
f010205b:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102061:	72 12                	jb     f0102075 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102063:	52                   	push   %edx
f0102064:	68 e4 4b 10 f0       	push   $0xf0104be4
f0102069:	6a 56                	push   $0x56
f010206b:	68 b3 53 10 f0       	push   $0xf01053b3
f0102070:	e8 2b e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102075:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010207b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010207e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102084:	f6 00 01             	testb  $0x1,(%eax)
f0102087:	74 19                	je     f01020a2 <mem_init+0x1031>
f0102089:	68 46 56 10 f0       	push   $0xf0105646
f010208e:	68 cd 53 10 f0       	push   $0xf01053cd
f0102093:	68 d6 03 00 00       	push   $0x3d6
f0102098:	68 8d 53 10 f0       	push   $0xf010538d
f010209d:	e8 fe df ff ff       	call   f01000a0 <_panic>
f01020a2:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020a5:	39 d0                	cmp    %edx,%eax
f01020a7:	75 db                	jne    f0102084 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020a9:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01020ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020bd:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020c0:	89 3d 7c ff 16 f0    	mov    %edi,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f01020c6:	83 ec 0c             	sub    $0xc,%esp
f01020c9:	50                   	push   %eax
f01020ca:	e8 33 ed ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f01020cf:	89 1c 24             	mov    %ebx,(%esp)
f01020d2:	e8 2b ed ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f01020d7:	89 34 24             	mov    %esi,(%esp)
f01020da:	e8 23 ed ff ff       	call   f0100e02 <page_free>

	cprintf("check_page() succeeded!\n");
f01020df:	c7 04 24 5d 56 10 f0 	movl   $0xf010565d,(%esp)
f01020e6:	e8 01 0e 00 00       	call   f0102eec <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_U);
f01020eb:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020f0:	83 c4 10             	add    $0x10,%esp
f01020f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f8:	77 15                	ja     f010210f <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020fa:	50                   	push   %eax
f01020fb:	68 08 4c 10 f0       	push   $0xf0104c08
f0102100:	68 ce 00 00 00       	push   $0xce
f0102105:	68 8d 53 10 f0       	push   $0xf010538d
f010210a:	e8 91 df ff ff       	call   f01000a0 <_panic>
f010210f:	8b 15 44 0c 17 f0    	mov    0xf0170c44,%edx
f0102115:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010211c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102122:	83 ec 08             	sub    $0x8,%esp
f0102125:	6a 04                	push   $0x4
f0102127:	05 00 00 00 10       	add    $0x10000000,%eax
f010212c:	50                   	push   %eax
f010212d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102132:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102137:	e8 bb ed ff ff       	call   f0100ef7 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)pages,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_W);
f010213c:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102142:	83 c4 10             	add    $0x10,%esp
f0102145:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010214b:	77 15                	ja     f0102162 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010214d:	52                   	push   %edx
f010214e:	68 08 4c 10 f0       	push   $0xf0104c08
f0102153:	68 cf 00 00 00       	push   $0xcf
f0102158:	68 8d 53 10 f0       	push   $0xf010538d
f010215d:	e8 3e df ff ff       	call   f01000a0 <_panic>
f0102162:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0102167:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f010216e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102174:	83 ec 08             	sub    $0x8,%esp
f0102177:	6a 02                	push   $0x2
f0102179:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f010217f:	50                   	push   %eax
f0102180:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102185:	e8 6d ed ff ff       	call   f0100ef7 <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here. 
	
	boot_map_region(kern_pgdir,UENVS,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_U);
f010218a:	a1 84 ff 16 f0       	mov    0xf016ff84,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218f:	83 c4 10             	add    $0x10,%esp
f0102192:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102197:	77 15                	ja     f01021ae <mem_init+0x113d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102199:	50                   	push   %eax
f010219a:	68 08 4c 10 f0       	push   $0xf0104c08
f010219f:	68 d9 00 00 00       	push   $0xd9
f01021a4:	68 8d 53 10 f0       	push   $0xf010538d
f01021a9:	e8 f2 de ff ff       	call   f01000a0 <_panic>
f01021ae:	83 ec 08             	sub    $0x8,%esp
f01021b1:	6a 04                	push   $0x4
f01021b3:	05 00 00 00 10       	add    $0x10000000,%eax
f01021b8:	50                   	push   %eax
f01021b9:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021be:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021c3:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01021c8:	e8 2a ed ff ff       	call   f0100ef7 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)envs,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_W);
f01021cd:	8b 15 84 ff 16 f0    	mov    0xf016ff84,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d3:	83 c4 10             	add    $0x10,%esp
f01021d6:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01021dc:	77 15                	ja     f01021f3 <mem_init+0x1182>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021de:	52                   	push   %edx
f01021df:	68 08 4c 10 f0       	push   $0xf0104c08
f01021e4:	68 da 00 00 00       	push   $0xda
f01021e9:	68 8d 53 10 f0       	push   $0xf010538d
f01021ee:	e8 ad de ff ff       	call   f01000a0 <_panic>
f01021f3:	83 ec 08             	sub    $0x8,%esp
f01021f6:	6a 02                	push   $0x2
f01021f8:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01021fe:	50                   	push   %eax
f01021ff:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102204:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102209:	e8 e9 ec ff ff       	call   f0100ef7 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010220e:	83 c4 10             	add    $0x10,%esp
f0102211:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f0102216:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010221b:	77 15                	ja     f0102232 <mem_init+0x11c1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010221d:	50                   	push   %eax
f010221e:	68 08 4c 10 f0       	push   $0xf0104c08
f0102223:	68 e8 00 00 00       	push   $0xe8
f0102228:	68 8d 53 10 f0       	push   $0xf010538d
f010222d:	e8 6e de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102232:	83 ec 08             	sub    $0x8,%esp
f0102235:	6a 02                	push   $0x2
f0102237:	68 00 00 11 00       	push   $0x110000
f010223c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102241:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102246:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f010224b:	e8 a7 ec ff ff       	call   f0100ef7 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,KERNBASE,(-1>>31)-KERNBASE,0,PTE_W);
f0102250:	83 c4 08             	add    $0x8,%esp
f0102253:	6a 02                	push   $0x2
f0102255:	6a 00                	push   $0x0
f0102257:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010225c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102261:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102266:	e8 8c ec ff ff       	call   f0100ef7 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010226b:	8b 1d 48 0c 17 f0    	mov    0xf0170c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102271:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0102276:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102279:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102280:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102285:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102288:	8b 3d 4c 0c 17 f0    	mov    0xf0170c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010228e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102291:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102294:	be 00 00 00 00       	mov    $0x0,%esi
f0102299:	eb 55                	jmp    f01022f0 <mem_init+0x127f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010229b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01022a1:	89 d8                	mov    %ebx,%eax
f01022a3:	e8 ba e6 ff ff       	call   f0100962 <check_va2pa>
f01022a8:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022af:	77 15                	ja     f01022c6 <mem_init+0x1255>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022b1:	57                   	push   %edi
f01022b2:	68 08 4c 10 f0       	push   $0xf0104c08
f01022b7:	68 12 03 00 00       	push   $0x312
f01022bc:	68 8d 53 10 f0       	push   $0xf010538d
f01022c1:	e8 da dd ff ff       	call   f01000a0 <_panic>
f01022c6:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022cd:	39 d0                	cmp    %edx,%eax
f01022cf:	74 19                	je     f01022ea <mem_init+0x1279>
f01022d1:	68 c8 51 10 f0       	push   $0xf01051c8
f01022d6:	68 cd 53 10 f0       	push   $0xf01053cd
f01022db:	68 12 03 00 00       	push   $0x312
f01022e0:	68 8d 53 10 f0       	push   $0xf010538d
f01022e5:	e8 b6 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022ea:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022f0:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022f3:	77 a6                	ja     f010229b <mem_init+0x122a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022f5:	8b 3d 84 ff 16 f0    	mov    0xf016ff84,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022fb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022fe:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102303:	89 f2                	mov    %esi,%edx
f0102305:	89 d8                	mov    %ebx,%eax
f0102307:	e8 56 e6 ff ff       	call   f0100962 <check_va2pa>
f010230c:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102313:	77 15                	ja     f010232a <mem_init+0x12b9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102315:	57                   	push   %edi
f0102316:	68 08 4c 10 f0       	push   $0xf0104c08
f010231b:	68 17 03 00 00       	push   $0x317
f0102320:	68 8d 53 10 f0       	push   $0xf010538d
f0102325:	e8 76 dd ff ff       	call   f01000a0 <_panic>
f010232a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102331:	39 c2                	cmp    %eax,%edx
f0102333:	74 19                	je     f010234e <mem_init+0x12dd>
f0102335:	68 fc 51 10 f0       	push   $0xf01051fc
f010233a:	68 cd 53 10 f0       	push   $0xf01053cd
f010233f:	68 17 03 00 00       	push   $0x317
f0102344:	68 8d 53 10 f0       	push   $0xf010538d
f0102349:	e8 52 dd ff ff       	call   f01000a0 <_panic>
f010234e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102354:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010235a:	75 a7                	jne    f0102303 <mem_init+0x1292>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010235c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010235f:	c1 e7 0c             	shl    $0xc,%edi
f0102362:	be 00 00 00 00       	mov    $0x0,%esi
f0102367:	eb 30                	jmp    f0102399 <mem_init+0x1328>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102369:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010236f:	89 d8                	mov    %ebx,%eax
f0102371:	e8 ec e5 ff ff       	call   f0100962 <check_va2pa>
f0102376:	39 c6                	cmp    %eax,%esi
f0102378:	74 19                	je     f0102393 <mem_init+0x1322>
f010237a:	68 30 52 10 f0       	push   $0xf0105230
f010237f:	68 cd 53 10 f0       	push   $0xf01053cd
f0102384:	68 1b 03 00 00       	push   $0x31b
f0102389:	68 8d 53 10 f0       	push   $0xf010538d
f010238e:	e8 0d dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102393:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102399:	39 fe                	cmp    %edi,%esi
f010239b:	72 cc                	jb     f0102369 <mem_init+0x12f8>
f010239d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023a2:	89 f2                	mov    %esi,%edx
f01023a4:	89 d8                	mov    %ebx,%eax
f01023a6:	e8 b7 e5 ff ff       	call   f0100962 <check_va2pa>
f01023ab:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f01023b1:	39 c2                	cmp    %eax,%edx
f01023b3:	74 19                	je     f01023ce <mem_init+0x135d>
f01023b5:	68 58 52 10 f0       	push   $0xf0105258
f01023ba:	68 cd 53 10 f0       	push   $0xf01053cd
f01023bf:	68 1f 03 00 00       	push   $0x31f
f01023c4:	68 8d 53 10 f0       	push   $0xf010538d
f01023c9:	e8 d2 dc ff ff       	call   f01000a0 <_panic>
f01023ce:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023d4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023da:	75 c6                	jne    f01023a2 <mem_init+0x1331>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023dc:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023e1:	89 d8                	mov    %ebx,%eax
f01023e3:	e8 7a e5 ff ff       	call   f0100962 <check_va2pa>
f01023e8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023eb:	74 51                	je     f010243e <mem_init+0x13cd>
f01023ed:	68 a0 52 10 f0       	push   $0xf01052a0
f01023f2:	68 cd 53 10 f0       	push   $0xf01053cd
f01023f7:	68 20 03 00 00       	push   $0x320
f01023fc:	68 8d 53 10 f0       	push   $0xf010538d
f0102401:	e8 9a dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102406:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010240b:	72 36                	jb     f0102443 <mem_init+0x13d2>
f010240d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102412:	76 07                	jbe    f010241b <mem_init+0x13aa>
f0102414:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102419:	75 28                	jne    f0102443 <mem_init+0x13d2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010241b:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010241f:	0f 85 83 00 00 00    	jne    f01024a8 <mem_init+0x1437>
f0102425:	68 76 56 10 f0       	push   $0xf0105676
f010242a:	68 cd 53 10 f0       	push   $0xf01053cd
f010242f:	68 29 03 00 00       	push   $0x329
f0102434:	68 8d 53 10 f0       	push   $0xf010538d
f0102439:	e8 62 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010243e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102443:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102448:	76 3f                	jbe    f0102489 <mem_init+0x1418>
				assert(pgdir[i] & PTE_P);
f010244a:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010244d:	f6 c2 01             	test   $0x1,%dl
f0102450:	75 19                	jne    f010246b <mem_init+0x13fa>
f0102452:	68 76 56 10 f0       	push   $0xf0105676
f0102457:	68 cd 53 10 f0       	push   $0xf01053cd
f010245c:	68 2d 03 00 00       	push   $0x32d
f0102461:	68 8d 53 10 f0       	push   $0xf010538d
f0102466:	e8 35 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010246b:	f6 c2 02             	test   $0x2,%dl
f010246e:	75 38                	jne    f01024a8 <mem_init+0x1437>
f0102470:	68 87 56 10 f0       	push   $0xf0105687
f0102475:	68 cd 53 10 f0       	push   $0xf01053cd
f010247a:	68 2e 03 00 00       	push   $0x32e
f010247f:	68 8d 53 10 f0       	push   $0xf010538d
f0102484:	e8 17 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102489:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010248d:	74 19                	je     f01024a8 <mem_init+0x1437>
f010248f:	68 98 56 10 f0       	push   $0xf0105698
f0102494:	68 cd 53 10 f0       	push   $0xf01053cd
f0102499:	68 30 03 00 00       	push   $0x330
f010249e:	68 8d 53 10 f0       	push   $0xf010538d
f01024a3:	e8 f8 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024a8:	83 c0 01             	add    $0x1,%eax
f01024ab:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024b0:	0f 86 50 ff ff ff    	jbe    f0102406 <mem_init+0x1395>
				assert(pgdir[i] == 0);
				
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024b6:	83 ec 0c             	sub    $0xc,%esp
f01024b9:	68 d0 52 10 f0       	push   $0xf01052d0
f01024be:	e8 29 0a 00 00       	call   f0102eec <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024c3:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024c8:	83 c4 10             	add    $0x10,%esp
f01024cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024d0:	77 15                	ja     f01024e7 <mem_init+0x1476>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024d2:	50                   	push   %eax
f01024d3:	68 08 4c 10 f0       	push   $0xf0104c08
f01024d8:	68 ff 00 00 00       	push   $0xff
f01024dd:	68 8d 53 10 f0       	push   $0xf010538d
f01024e2:	e8 b9 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024e7:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ec:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01024f4:	e8 47 e5 ff ff       	call   f0100a40 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01024f9:	0f 20 c0             	mov    %cr0,%eax
f01024fc:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01024ff:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102504:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102507:	83 ec 0c             	sub    $0xc,%esp
f010250a:	6a 00                	push   $0x0
f010250c:	e8 81 e8 ff ff       	call   f0100d92 <page_alloc>
f0102511:	89 c3                	mov    %eax,%ebx
f0102513:	83 c4 10             	add    $0x10,%esp
f0102516:	85 c0                	test   %eax,%eax
f0102518:	75 19                	jne    f0102533 <mem_init+0x14c2>
f010251a:	68 94 54 10 f0       	push   $0xf0105494
f010251f:	68 cd 53 10 f0       	push   $0xf01053cd
f0102524:	68 f1 03 00 00       	push   $0x3f1
f0102529:	68 8d 53 10 f0       	push   $0xf010538d
f010252e:	e8 6d db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102533:	83 ec 0c             	sub    $0xc,%esp
f0102536:	6a 00                	push   $0x0
f0102538:	e8 55 e8 ff ff       	call   f0100d92 <page_alloc>
f010253d:	89 c7                	mov    %eax,%edi
f010253f:	83 c4 10             	add    $0x10,%esp
f0102542:	85 c0                	test   %eax,%eax
f0102544:	75 19                	jne    f010255f <mem_init+0x14ee>
f0102546:	68 aa 54 10 f0       	push   $0xf01054aa
f010254b:	68 cd 53 10 f0       	push   $0xf01053cd
f0102550:	68 f2 03 00 00       	push   $0x3f2
f0102555:	68 8d 53 10 f0       	push   $0xf010538d
f010255a:	e8 41 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010255f:	83 ec 0c             	sub    $0xc,%esp
f0102562:	6a 00                	push   $0x0
f0102564:	e8 29 e8 ff ff       	call   f0100d92 <page_alloc>
f0102569:	89 c6                	mov    %eax,%esi
f010256b:	83 c4 10             	add    $0x10,%esp
f010256e:	85 c0                	test   %eax,%eax
f0102570:	75 19                	jne    f010258b <mem_init+0x151a>
f0102572:	68 c0 54 10 f0       	push   $0xf01054c0
f0102577:	68 cd 53 10 f0       	push   $0xf01053cd
f010257c:	68 f3 03 00 00       	push   $0x3f3
f0102581:	68 8d 53 10 f0       	push   $0xf010538d
f0102586:	e8 15 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010258b:	83 ec 0c             	sub    $0xc,%esp
f010258e:	53                   	push   %ebx
f010258f:	e8 6e e8 ff ff       	call   f0100e02 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102594:	89 f8                	mov    %edi,%eax
f0102596:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f010259c:	c1 f8 03             	sar    $0x3,%eax
f010259f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a2:	89 c2                	mov    %eax,%edx
f01025a4:	c1 ea 0c             	shr    $0xc,%edx
f01025a7:	83 c4 10             	add    $0x10,%esp
f01025aa:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01025b0:	72 12                	jb     f01025c4 <mem_init+0x1553>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b2:	50                   	push   %eax
f01025b3:	68 e4 4b 10 f0       	push   $0xf0104be4
f01025b8:	6a 56                	push   $0x56
f01025ba:	68 b3 53 10 f0       	push   $0xf01053b3
f01025bf:	e8 dc da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025c4:	83 ec 04             	sub    $0x4,%esp
f01025c7:	68 00 10 00 00       	push   $0x1000
f01025cc:	6a 01                	push   $0x1
f01025ce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025d3:	50                   	push   %eax
f01025d4:	e8 3b 1c 00 00       	call   f0104214 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d9:	89 f0                	mov    %esi,%eax
f01025db:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01025e1:	c1 f8 03             	sar    $0x3,%eax
f01025e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e7:	89 c2                	mov    %eax,%edx
f01025e9:	c1 ea 0c             	shr    $0xc,%edx
f01025ec:	83 c4 10             	add    $0x10,%esp
f01025ef:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01025f5:	72 12                	jb     f0102609 <mem_init+0x1598>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f7:	50                   	push   %eax
f01025f8:	68 e4 4b 10 f0       	push   $0xf0104be4
f01025fd:	6a 56                	push   $0x56
f01025ff:	68 b3 53 10 f0       	push   $0xf01053b3
f0102604:	e8 97 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102609:	83 ec 04             	sub    $0x4,%esp
f010260c:	68 00 10 00 00       	push   $0x1000
f0102611:	6a 02                	push   $0x2
f0102613:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102618:	50                   	push   %eax
f0102619:	e8 f6 1b 00 00       	call   f0104214 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010261e:	6a 02                	push   $0x2
f0102620:	68 00 10 00 00       	push   $0x1000
f0102625:	57                   	push   %edi
f0102626:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f010262c:	e8 bb e9 ff ff       	call   f0100fec <page_insert>
	assert(pp1->pp_ref == 1);
f0102631:	83 c4 20             	add    $0x20,%esp
f0102634:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102639:	74 19                	je     f0102654 <mem_init+0x15e3>
f010263b:	68 91 55 10 f0       	push   $0xf0105591
f0102640:	68 cd 53 10 f0       	push   $0xf01053cd
f0102645:	68 f8 03 00 00       	push   $0x3f8
f010264a:	68 8d 53 10 f0       	push   $0xf010538d
f010264f:	e8 4c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102654:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010265b:	01 01 01 
f010265e:	74 19                	je     f0102679 <mem_init+0x1608>
f0102660:	68 f0 52 10 f0       	push   $0xf01052f0
f0102665:	68 cd 53 10 f0       	push   $0xf01053cd
f010266a:	68 f9 03 00 00       	push   $0x3f9
f010266f:	68 8d 53 10 f0       	push   $0xf010538d
f0102674:	e8 27 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102679:	6a 02                	push   $0x2
f010267b:	68 00 10 00 00       	push   $0x1000
f0102680:	56                   	push   %esi
f0102681:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102687:	e8 60 e9 ff ff       	call   f0100fec <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010268c:	83 c4 10             	add    $0x10,%esp
f010268f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102696:	02 02 02 
f0102699:	74 19                	je     f01026b4 <mem_init+0x1643>
f010269b:	68 14 53 10 f0       	push   $0xf0105314
f01026a0:	68 cd 53 10 f0       	push   $0xf01053cd
f01026a5:	68 fb 03 00 00       	push   $0x3fb
f01026aa:	68 8d 53 10 f0       	push   $0xf010538d
f01026af:	e8 ec d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026b4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026b9:	74 19                	je     f01026d4 <mem_init+0x1663>
f01026bb:	68 b3 55 10 f0       	push   $0xf01055b3
f01026c0:	68 cd 53 10 f0       	push   $0xf01053cd
f01026c5:	68 fc 03 00 00       	push   $0x3fc
f01026ca:	68 8d 53 10 f0       	push   $0xf010538d
f01026cf:	e8 cc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026d4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026d9:	74 19                	je     f01026f4 <mem_init+0x1683>
f01026db:	68 1d 56 10 f0       	push   $0xf010561d
f01026e0:	68 cd 53 10 f0       	push   $0xf01053cd
f01026e5:	68 fd 03 00 00       	push   $0x3fd
f01026ea:	68 8d 53 10 f0       	push   $0xf010538d
f01026ef:	e8 ac d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026f4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026fb:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026fe:	89 f0                	mov    %esi,%eax
f0102700:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102706:	c1 f8 03             	sar    $0x3,%eax
f0102709:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010270c:	89 c2                	mov    %eax,%edx
f010270e:	c1 ea 0c             	shr    $0xc,%edx
f0102711:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0102717:	72 12                	jb     f010272b <mem_init+0x16ba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102719:	50                   	push   %eax
f010271a:	68 e4 4b 10 f0       	push   $0xf0104be4
f010271f:	6a 56                	push   $0x56
f0102721:	68 b3 53 10 f0       	push   $0xf01053b3
f0102726:	e8 75 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010272b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102732:	03 03 03 
f0102735:	74 19                	je     f0102750 <mem_init+0x16df>
f0102737:	68 38 53 10 f0       	push   $0xf0105338
f010273c:	68 cd 53 10 f0       	push   $0xf01053cd
f0102741:	68 ff 03 00 00       	push   $0x3ff
f0102746:	68 8d 53 10 f0       	push   $0xf010538d
f010274b:	e8 50 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102750:	83 ec 08             	sub    $0x8,%esp
f0102753:	68 00 10 00 00       	push   $0x1000
f0102758:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f010275e:	e8 3b e8 ff ff       	call   f0100f9e <page_remove>
	assert(pp2->pp_ref == 0);
f0102763:	83 c4 10             	add    $0x10,%esp
f0102766:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010276b:	74 19                	je     f0102786 <mem_init+0x1715>
f010276d:	68 eb 55 10 f0       	push   $0xf01055eb
f0102772:	68 cd 53 10 f0       	push   $0xf01053cd
f0102777:	68 01 04 00 00       	push   $0x401
f010277c:	68 8d 53 10 f0       	push   $0xf010538d
f0102781:	e8 1a d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102786:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f010278c:	8b 11                	mov    (%ecx),%edx
f010278e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102794:	89 d8                	mov    %ebx,%eax
f0102796:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f010279c:	c1 f8 03             	sar    $0x3,%eax
f010279f:	c1 e0 0c             	shl    $0xc,%eax
f01027a2:	39 c2                	cmp    %eax,%edx
f01027a4:	74 19                	je     f01027bf <mem_init+0x174e>
f01027a6:	68 48 4e 10 f0       	push   $0xf0104e48
f01027ab:	68 cd 53 10 f0       	push   $0xf01053cd
f01027b0:	68 04 04 00 00       	push   $0x404
f01027b5:	68 8d 53 10 f0       	push   $0xf010538d
f01027ba:	e8 e1 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027bf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027c5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027ca:	74 19                	je     f01027e5 <mem_init+0x1774>
f01027cc:	68 a2 55 10 f0       	push   $0xf01055a2
f01027d1:	68 cd 53 10 f0       	push   $0xf01053cd
f01027d6:	68 06 04 00 00       	push   $0x406
f01027db:	68 8d 53 10 f0       	push   $0xf010538d
f01027e0:	e8 bb d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027e5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027eb:	83 ec 0c             	sub    $0xc,%esp
f01027ee:	53                   	push   %ebx
f01027ef:	e8 0e e6 ff ff       	call   f0100e02 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027f4:	c7 04 24 64 53 10 f0 	movl   $0xf0105364,(%esp)
f01027fb:	e8 ec 06 00 00       	call   f0102eec <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102800:	83 c4 10             	add    $0x10,%esp
f0102803:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102806:	5b                   	pop    %ebx
f0102807:	5e                   	pop    %esi
f0102808:	5f                   	pop    %edi
f0102809:	5d                   	pop    %ebp
f010280a:	c3                   	ret    

f010280b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010280b:	55                   	push   %ebp
f010280c:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010280e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102811:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102814:	5d                   	pop    %ebp
f0102815:	c3                   	ret    

f0102816 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102816:	55                   	push   %ebp
f0102817:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102819:	b8 00 00 00 00       	mov    $0x0,%eax
f010281e:	5d                   	pop    %ebp
f010281f:	c3                   	ret    

f0102820 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102820:	55                   	push   %ebp
f0102821:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102823:	5d                   	pop    %ebp
f0102824:	c3                   	ret    

f0102825 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102825:	55                   	push   %ebp
f0102826:	89 e5                	mov    %esp,%ebp
f0102828:	57                   	push   %edi
f0102829:	56                   	push   %esi
f010282a:	53                   	push   %ebx
f010282b:	83 ec 0c             	sub    $0xc,%esp
f010282e:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
f0102830:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102836:	89 d3                	mov    %edx,%ebx
        void* koniec = ROUNDUP(zaciatok+len,PGSIZE);
f0102838:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010283f:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

        for(int i=(int)zaciatok;i<(int)koniec;i+=PGSIZE)
f0102845:	eb 3d                	jmp    f0102884 <region_alloc+0x5f>
        {
                struct PageInfo* page = page_alloc(0);
f0102847:	83 ec 0c             	sub    $0xc,%esp
f010284a:	6a 00                	push   $0x0
f010284c:	e8 41 e5 ff ff       	call   f0100d92 <page_alloc>

                if(!page)
f0102851:	83 c4 10             	add    $0x10,%esp
f0102854:	85 c0                	test   %eax,%eax
f0102856:	75 17                	jne    f010286f <region_alloc+0x4a>
                        panic("Unable to alloc a page!");
f0102858:	83 ec 04             	sub    $0x4,%esp
f010285b:	68 a6 56 10 f0       	push   $0xf01056a6
f0102860:	68 1d 01 00 00       	push   $0x11d
f0102865:	68 be 56 10 f0       	push   $0xf01056be
f010286a:	e8 31 d8 ff ff       	call   f01000a0 <_panic>

                page_insert(e->env_pgdir,page,(void*)i,PTE_P|PTE_W|PTE_U);
f010286f:	6a 07                	push   $0x7
f0102871:	53                   	push   %ebx
f0102872:	50                   	push   %eax
f0102873:	ff 77 5c             	pushl  0x5c(%edi)
f0102876:	e8 71 e7 ff ff       	call   f0100fec <page_insert>
	// (But only if you need it for load_icode.)
	
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
        void* koniec = ROUNDUP(zaciatok+len,PGSIZE);

        for(int i=(int)zaciatok;i<(int)koniec;i+=PGSIZE)
f010287b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102881:	83 c4 10             	add    $0x10,%esp
f0102884:	39 f3                	cmp    %esi,%ebx
f0102886:	7c bf                	jl     f0102847 <region_alloc+0x22>

	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102888:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010288b:	5b                   	pop    %ebx
f010288c:	5e                   	pop    %esi
f010288d:	5f                   	pop    %edi
f010288e:	5d                   	pop    %ebp
f010288f:	c3                   	ret    

f0102890 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102890:	55                   	push   %ebp
f0102891:	89 e5                	mov    %esp,%ebp
f0102893:	8b 55 08             	mov    0x8(%ebp),%edx
f0102896:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102899:	85 d2                	test   %edx,%edx
f010289b:	75 11                	jne    f01028ae <envid2env+0x1e>
		*env_store = curenv;
f010289d:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01028a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028a5:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01028ac:	eb 5e                	jmp    f010290c <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028ae:	89 d0                	mov    %edx,%eax
f01028b0:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028b5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028b8:	c1 e0 05             	shl    $0x5,%eax
f01028bb:	03 05 84 ff 16 f0    	add    0xf016ff84,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028c1:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028c5:	74 05                	je     f01028cc <envid2env+0x3c>
f01028c7:	3b 50 48             	cmp    0x48(%eax),%edx
f01028ca:	74 10                	je     f01028dc <envid2env+0x4c>
		*env_store = 0;
f01028cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028d5:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028da:	eb 30                	jmp    f010290c <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01028dc:	84 c9                	test   %cl,%cl
f01028de:	74 22                	je     f0102902 <envid2env+0x72>
f01028e0:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f01028e6:	39 d0                	cmp    %edx,%eax
f01028e8:	74 18                	je     f0102902 <envid2env+0x72>
f01028ea:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028ed:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028f0:	74 10                	je     f0102902 <envid2env+0x72>
		*env_store = 0;
f01028f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028f5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028fb:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102900:	eb 0a                	jmp    f010290c <envid2env+0x7c>
	}

	*env_store = e;
f0102902:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102905:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102907:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010290c:	5d                   	pop    %ebp
f010290d:	c3                   	ret    

f010290e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010290e:	55                   	push   %ebp
f010290f:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102911:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102916:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102919:	b8 23 00 00 00       	mov    $0x23,%eax
f010291e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102920:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102922:	b8 10 00 00 00       	mov    $0x10,%eax
f0102927:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102929:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f010292b:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010292d:	ea 34 29 10 f0 08 00 	ljmp   $0x8,$0xf0102934
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102934:	b8 00 00 00 00       	mov    $0x0,%eax
f0102939:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010293c:	5d                   	pop    %ebp
f010293d:	c3                   	ret    

f010293e <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010293e:	55                   	push   %ebp
f010293f:	89 e5                	mov    %esp,%ebp
f0102941:	56                   	push   %esi
f0102942:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	
	for(int i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f0102943:	8b 35 84 ff 16 f0    	mov    0xf016ff84,%esi
f0102949:	8b 15 88 ff 16 f0    	mov    0xf016ff88,%edx
f010294f:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102955:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102958:	89 c1                	mov    %eax,%ecx
f010295a:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link=env_free_list;
f0102961:	89 50 44             	mov    %edx,0x44(%eax)
f0102964:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];		
f0102967:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	
	for(int i=NENV-1;i>=0;i--)
f0102969:	39 d8                	cmp    %ebx,%eax
f010296b:	75 eb                	jne    f0102958 <env_init+0x1a>
f010296d:	89 35 88 ff 16 f0    	mov    %esi,0xf016ff88
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];		
	}
	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102973:	e8 96 ff ff ff       	call   f010290e <env_init_percpu>
}
f0102978:	5b                   	pop    %ebx
f0102979:	5e                   	pop    %esi
f010297a:	5d                   	pop    %ebp
f010297b:	c3                   	ret    

f010297c <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010297c:	55                   	push   %ebp
f010297d:	89 e5                	mov    %esp,%ebp
f010297f:	53                   	push   %ebx
f0102980:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102983:	8b 1d 88 ff 16 f0    	mov    0xf016ff88,%ebx
f0102989:	85 db                	test   %ebx,%ebx
f010298b:	0f 84 43 01 00 00    	je     f0102ad4 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102991:	83 ec 0c             	sub    $0xc,%esp
f0102994:	6a 01                	push   $0x1
f0102996:	e8 f7 e3 ff ff       	call   f0100d92 <page_alloc>
f010299b:	83 c4 10             	add    $0x10,%esp
f010299e:	85 c0                	test   %eax,%eax
f01029a0:	0f 84 35 01 00 00    	je     f0102adb <env_alloc+0x15f>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.

	p->pp_ref++;
f01029a6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029ab:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01029b1:	c1 f8 03             	sar    $0x3,%eax
f01029b4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029b7:	89 c2                	mov    %eax,%edx
f01029b9:	c1 ea 0c             	shr    $0xc,%edx
f01029bc:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01029c2:	72 12                	jb     f01029d6 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029c4:	50                   	push   %eax
f01029c5:	68 e4 4b 10 f0       	push   $0xf0104be4
f01029ca:	6a 56                	push   $0x56
f01029cc:	68 b3 53 10 f0       	push   $0xf01053b3
f01029d1:	e8 ca d6 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01029d6:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pde_t*)page2kva(p);
f01029db:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f01029de:	83 ec 04             	sub    $0x4,%esp
f01029e1:	68 00 10 00 00       	push   $0x1000
f01029e6:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01029ec:	50                   	push   %eax
f01029ed:	e8 d7 18 00 00       	call   f01042c9 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029f2:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029f5:	83 c4 10             	add    $0x10,%esp
f01029f8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029fd:	77 15                	ja     f0102a14 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029ff:	50                   	push   %eax
f0102a00:	68 08 4c 10 f0       	push   $0xf0104c08
f0102a05:	68 c4 00 00 00       	push   $0xc4
f0102a0a:	68 be 56 10 f0       	push   $0xf01056be
f0102a0f:	e8 8c d6 ff ff       	call   f01000a0 <_panic>
f0102a14:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a1a:	83 ca 05             	or     $0x5,%edx
f0102a1d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a23:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a26:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a2b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a30:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a35:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a38:	89 da                	mov    %ebx,%edx
f0102a3a:	2b 15 84 ff 16 f0    	sub    0xf016ff84,%edx
f0102a40:	c1 fa 05             	sar    $0x5,%edx
f0102a43:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a49:	09 d0                	or     %edx,%eax
f0102a4b:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a51:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a54:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a5b:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a62:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a69:	83 ec 04             	sub    $0x4,%esp
f0102a6c:	6a 44                	push   $0x44
f0102a6e:	6a 00                	push   $0x0
f0102a70:	53                   	push   %ebx
f0102a71:	e8 9e 17 00 00       	call   f0104214 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a76:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a7c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a82:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a88:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a8f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a95:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a98:	a3 88 ff 16 f0       	mov    %eax,0xf016ff88
	*newenv_store = e;
f0102a9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aa0:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102aa2:	8b 53 48             	mov    0x48(%ebx),%edx
f0102aa5:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f0102aaa:	83 c4 10             	add    $0x10,%esp
f0102aad:	85 c0                	test   %eax,%eax
f0102aaf:	74 05                	je     f0102ab6 <env_alloc+0x13a>
f0102ab1:	8b 40 48             	mov    0x48(%eax),%eax
f0102ab4:	eb 05                	jmp    f0102abb <env_alloc+0x13f>
f0102ab6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102abb:	83 ec 04             	sub    $0x4,%esp
f0102abe:	52                   	push   %edx
f0102abf:	50                   	push   %eax
f0102ac0:	68 c9 56 10 f0       	push   $0xf01056c9
f0102ac5:	e8 22 04 00 00       	call   f0102eec <cprintf>
	return 0;
f0102aca:	83 c4 10             	add    $0x10,%esp
f0102acd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ad2:	eb 0c                	jmp    f0102ae0 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102ad4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102ad9:	eb 05                	jmp    f0102ae0 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102adb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102ae0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ae3:	c9                   	leave  
f0102ae4:	c3                   	ret    

f0102ae5 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102ae5:	55                   	push   %ebp
f0102ae6:	89 e5                	mov    %esp,%ebp
f0102ae8:	57                   	push   %edi
f0102ae9:	56                   	push   %esi
f0102aea:	53                   	push   %ebx
f0102aeb:	83 ec 34             	sub    $0x34,%esp
f0102aee:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* e;
	int error = env_alloc(&e,0);
f0102af1:	6a 00                	push   $0x0
f0102af3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102af6:	50                   	push   %eax
f0102af7:	e8 80 fe ff ff       	call   f010297c <env_alloc>

	if(error<0)
f0102afc:	83 c4 10             	add    $0x10,%esp
f0102aff:	85 c0                	test   %eax,%eax
f0102b01:	79 15                	jns    f0102b18 <env_create+0x33>
		panic("Environment allocation error: %e",error);
f0102b03:	50                   	push   %eax
f0102b04:	68 14 57 10 f0       	push   $0xf0105714
f0102b09:	68 95 01 00 00       	push   $0x195
f0102b0e:	68 be 56 10 f0       	push   $0xf01056be
f0102b13:	e8 88 d5 ff ff       	call   f01000a0 <_panic>

	load_icode(e,binary);
f0102b18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b1b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	struct Proghdr *ph, *eph;
	struct Elf *elf=(struct Elf*) binary;
        
	// is this a valid ELF?
        if (elf->e_magic != ELF_MAGIC)
f0102b1e:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b24:	74 17                	je     f0102b3d <env_create+0x58>
                panic("Not a valid ELF!");
f0102b26:	83 ec 04             	sub    $0x4,%esp
f0102b29:	68 de 56 10 f0       	push   $0xf01056de
f0102b2e:	68 64 01 00 00       	push   $0x164
f0102b33:	68 be 56 10 f0       	push   $0xf01056be
f0102b38:	e8 63 d5 ff ff       	call   f01000a0 <_panic>

        // load each program segment (ignores ph flags)
        ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0102b3d:	89 fb                	mov    %edi,%ebx
f0102b3f:	03 5f 1c             	add    0x1c(%edi),%ebx
        
	eph = ph + elf->e_phnum;
f0102b42:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b46:	c1 e6 05             	shl    $0x5,%esi
f0102b49:	01 de                	add    %ebx,%esi
	
	lcr3(PADDR(e->env_pgdir));
f0102b4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b4e:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b51:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b56:	77 15                	ja     f0102b6d <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b58:	50                   	push   %eax
f0102b59:	68 08 4c 10 f0       	push   $0xf0104c08
f0102b5e:	68 6b 01 00 00       	push   $0x16b
f0102b63:	68 be 56 10 f0       	push   $0xf01056be
f0102b68:	e8 33 d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b6d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b72:	0f 22 d8             	mov    %eax,%cr3
f0102b75:	eb 41                	jmp    f0102bb8 <env_create+0xd3>

        for (; ph < eph; ph++)
	{	
		if(ph->p_type==ELF_PROG_LOAD)
f0102b77:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b7a:	75 39                	jne    f0102bb5 <env_create+0xd0>
		{
			region_alloc(e,(void*)ph->p_va,ph->p_memsz);	
f0102b7c:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b7f:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b85:	e8 9b fc ff ff       	call   f0102825 <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0102b8a:	83 ec 04             	sub    $0x4,%esp
f0102b8d:	ff 73 10             	pushl  0x10(%ebx)
f0102b90:	89 f8                	mov    %edi,%eax
f0102b92:	03 43 04             	add    0x4(%ebx),%eax
f0102b95:	50                   	push   %eax
f0102b96:	ff 73 08             	pushl  0x8(%ebx)
f0102b99:	e8 2b 17 00 00       	call   f01042c9 <memcpy>
			memset((void*)ph->p_va,0,ph->p_memsz-ph->p_filesz);				
f0102b9e:	83 c4 0c             	add    $0xc,%esp
f0102ba1:	8b 43 14             	mov    0x14(%ebx),%eax
f0102ba4:	2b 43 10             	sub    0x10(%ebx),%eax
f0102ba7:	50                   	push   %eax
f0102ba8:	6a 00                	push   $0x0
f0102baa:	ff 73 08             	pushl  0x8(%ebx)
f0102bad:	e8 62 16 00 00       	call   f0104214 <memset>
f0102bb2:	83 c4 10             	add    $0x10,%esp
        
	eph = ph + elf->e_phnum;
	
	lcr3(PADDR(e->env_pgdir));

        for (; ph < eph; ph++)
f0102bb5:	83 c3 20             	add    $0x20,%ebx
f0102bb8:	39 de                	cmp    %ebx,%esi
f0102bba:	77 bb                	ja     f0102b77 <env_create+0x92>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
			memset((void*)ph->p_va,0,ph->p_memsz-ph->p_filesz);				
		}
	}
	
	lcr3(PADDR(kern_pgdir));
f0102bbc:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bc1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bc6:	77 15                	ja     f0102bdd <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bc8:	50                   	push   %eax
f0102bc9:	68 08 4c 10 f0       	push   $0xf0104c08
f0102bce:	68 77 01 00 00       	push   $0x177
f0102bd3:	68 be 56 10 f0       	push   $0xf01056be
f0102bd8:	e8 c3 d4 ff ff       	call   f01000a0 <_panic>
f0102bdd:	05 00 00 00 10       	add    $0x10000000,%eax
f0102be2:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here

	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);	
f0102be5:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bea:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bef:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102bf2:	89 f0                	mov    %esi,%eax
f0102bf4:	e8 2c fc ff ff       	call   f0102825 <region_alloc>

	e->env_tf.tf_eip = elf->e_entry;
f0102bf9:	8b 47 18             	mov    0x18(%edi),%eax
f0102bfc:	89 46 30             	mov    %eax,0x30(%esi)

	e->env_tf.tf_esp = (uintptr_t)(USTACKTOP);
f0102bff:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	if(error<0)
		panic("Environment allocation error: %e",error);

	load_icode(e,binary);
	
	e->env_type=type;
f0102c06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c09:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c0c:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c12:	5b                   	pop    %ebx
f0102c13:	5e                   	pop    %esi
f0102c14:	5f                   	pop    %edi
f0102c15:	5d                   	pop    %ebp
f0102c16:	c3                   	ret    

f0102c17 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c17:	55                   	push   %ebp
f0102c18:	89 e5                	mov    %esp,%ebp
f0102c1a:	57                   	push   %edi
f0102c1b:	56                   	push   %esi
f0102c1c:	53                   	push   %ebx
f0102c1d:	83 ec 1c             	sub    $0x1c,%esp
f0102c20:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c23:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102c29:	39 fa                	cmp    %edi,%edx
f0102c2b:	75 29                	jne    f0102c56 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c2d:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c32:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c37:	77 15                	ja     f0102c4e <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c39:	50                   	push   %eax
f0102c3a:	68 08 4c 10 f0       	push   $0xf0104c08
f0102c3f:	68 aa 01 00 00       	push   $0x1aa
f0102c44:	68 be 56 10 f0       	push   $0xf01056be
f0102c49:	e8 52 d4 ff ff       	call   f01000a0 <_panic>
f0102c4e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c53:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c56:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c59:	85 d2                	test   %edx,%edx
f0102c5b:	74 05                	je     f0102c62 <env_free+0x4b>
f0102c5d:	8b 42 48             	mov    0x48(%edx),%eax
f0102c60:	eb 05                	jmp    f0102c67 <env_free+0x50>
f0102c62:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c67:	83 ec 04             	sub    $0x4,%esp
f0102c6a:	51                   	push   %ecx
f0102c6b:	50                   	push   %eax
f0102c6c:	68 ef 56 10 f0       	push   $0xf01056ef
f0102c71:	e8 76 02 00 00       	call   f0102eec <cprintf>
f0102c76:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c79:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c80:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c83:	89 d0                	mov    %edx,%eax
f0102c85:	c1 e0 02             	shl    $0x2,%eax
f0102c88:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c8b:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c8e:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c91:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c97:	0f 84 a8 00 00 00    	je     f0102d45 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c9d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ca3:	89 f0                	mov    %esi,%eax
f0102ca5:	c1 e8 0c             	shr    $0xc,%eax
f0102ca8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cab:	39 05 44 0c 17 f0    	cmp    %eax,0xf0170c44
f0102cb1:	77 15                	ja     f0102cc8 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cb3:	56                   	push   %esi
f0102cb4:	68 e4 4b 10 f0       	push   $0xf0104be4
f0102cb9:	68 b9 01 00 00       	push   $0x1b9
f0102cbe:	68 be 56 10 f0       	push   $0xf01056be
f0102cc3:	e8 d8 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cc8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ccb:	c1 e0 16             	shl    $0x16,%eax
f0102cce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cd1:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102cd6:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102cdd:	01 
f0102cde:	74 17                	je     f0102cf7 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102ce0:	83 ec 08             	sub    $0x8,%esp
f0102ce3:	89 d8                	mov    %ebx,%eax
f0102ce5:	c1 e0 0c             	shl    $0xc,%eax
f0102ce8:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102ceb:	50                   	push   %eax
f0102cec:	ff 77 5c             	pushl  0x5c(%edi)
f0102cef:	e8 aa e2 ff ff       	call   f0100f9e <page_remove>
f0102cf4:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102cf7:	83 c3 01             	add    $0x1,%ebx
f0102cfa:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d00:	75 d4                	jne    f0102cd6 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d02:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d05:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d08:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d0f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d12:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102d18:	72 14                	jb     f0102d2e <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d1a:	83 ec 04             	sub    $0x4,%esp
f0102d1d:	68 14 4d 10 f0       	push   $0xf0104d14
f0102d22:	6a 4f                	push   $0x4f
f0102d24:	68 b3 53 10 f0       	push   $0xf01053b3
f0102d29:	e8 72 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d2e:	83 ec 0c             	sub    $0xc,%esp
f0102d31:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0102d36:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d39:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d3c:	50                   	push   %eax
f0102d3d:	e8 fb e0 ff ff       	call   f0100e3d <page_decref>
f0102d42:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d45:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d4c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d51:	0f 85 29 ff ff ff    	jne    f0102c80 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d57:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d5a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d5f:	77 15                	ja     f0102d76 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d61:	50                   	push   %eax
f0102d62:	68 08 4c 10 f0       	push   $0xf0104c08
f0102d67:	68 c7 01 00 00       	push   $0x1c7
f0102d6c:	68 be 56 10 f0       	push   $0xf01056be
f0102d71:	e8 2a d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d76:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d7d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d82:	c1 e8 0c             	shr    $0xc,%eax
f0102d85:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102d8b:	72 14                	jb     f0102da1 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d8d:	83 ec 04             	sub    $0x4,%esp
f0102d90:	68 14 4d 10 f0       	push   $0xf0104d14
f0102d95:	6a 4f                	push   $0x4f
f0102d97:	68 b3 53 10 f0       	push   $0xf01053b3
f0102d9c:	e8 ff d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102da1:	83 ec 0c             	sub    $0xc,%esp
f0102da4:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
f0102daa:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102dad:	50                   	push   %eax
f0102dae:	e8 8a e0 ff ff       	call   f0100e3d <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102db3:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102dba:	a1 88 ff 16 f0       	mov    0xf016ff88,%eax
f0102dbf:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102dc2:	89 3d 88 ff 16 f0    	mov    %edi,0xf016ff88
}
f0102dc8:	83 c4 10             	add    $0x10,%esp
f0102dcb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dce:	5b                   	pop    %ebx
f0102dcf:	5e                   	pop    %esi
f0102dd0:	5f                   	pop    %edi
f0102dd1:	5d                   	pop    %ebp
f0102dd2:	c3                   	ret    

f0102dd3 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102dd3:	55                   	push   %ebp
f0102dd4:	89 e5                	mov    %esp,%ebp
f0102dd6:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102dd9:	ff 75 08             	pushl  0x8(%ebp)
f0102ddc:	e8 36 fe ff ff       	call   f0102c17 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102de1:	c7 04 24 38 57 10 f0 	movl   $0xf0105738,(%esp)
f0102de8:	e8 ff 00 00 00       	call   f0102eec <cprintf>
f0102ded:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102df0:	83 ec 0c             	sub    $0xc,%esp
f0102df3:	6a 00                	push   $0x0
f0102df5:	e8 f7 d9 ff ff       	call   f01007f1 <monitor>
f0102dfa:	83 c4 10             	add    $0x10,%esp
f0102dfd:	eb f1                	jmp    f0102df0 <env_destroy+0x1d>

f0102dff <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102dff:	55                   	push   %ebp
f0102e00:	89 e5                	mov    %esp,%ebp
f0102e02:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102e05:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e08:	61                   	popa   
f0102e09:	07                   	pop    %es
f0102e0a:	1f                   	pop    %ds
f0102e0b:	83 c4 08             	add    $0x8,%esp
f0102e0e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e0f:	68 05 57 10 f0       	push   $0xf0105705
f0102e14:	68 f0 01 00 00       	push   $0x1f0
f0102e19:	68 be 56 10 f0       	push   $0xf01056be
f0102e1e:	e8 7d d2 ff ff       	call   f01000a0 <_panic>

f0102e23 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e23:	55                   	push   %ebp
f0102e24:	89 e5                	mov    %esp,%ebp
f0102e26:	83 ec 08             	sub    $0x8,%esp
f0102e29:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.

	if(curenv)
f0102e2c:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102e32:	85 d2                	test   %edx,%edx
f0102e34:	74 0d                	je     f0102e43 <env_run+0x20>
	{		
		if(curenv->env_status==ENV_RUNNING)
f0102e36:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e3a:	75 07                	jne    f0102e43 <env_run+0x20>
			curenv->env_status=ENV_RUNNABLE;
f0102e3c:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}	
		
	lcr3(PADDR(e->env_pgdir));
f0102e43:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e46:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e4c:	77 15                	ja     f0102e63 <env_run+0x40>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e4e:	52                   	push   %edx
f0102e4f:	68 08 4c 10 f0       	push   $0xf0104c08
f0102e54:	68 0e 02 00 00       	push   $0x20e
f0102e59:	68 be 56 10 f0       	push   $0xf01056be
f0102e5e:	e8 3d d2 ff ff       	call   f01000a0 <_panic>
f0102e63:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102e69:	0f 22 da             	mov    %edx,%cr3
	
	curenv=e;
f0102e6c:	a3 80 ff 16 f0       	mov    %eax,0xf016ff80
	
	e->env_status=ENV_RUNNING;
f0102e71:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102e78:	83 40 58 01          	addl   $0x1,0x58(%eax)
		
	env_pop_tf(&e->env_tf);
f0102e7c:	83 ec 0c             	sub    $0xc,%esp
f0102e7f:	50                   	push   %eax
f0102e80:	e8 7a ff ff ff       	call   f0102dff <env_pop_tf>

f0102e85 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e85:	55                   	push   %ebp
f0102e86:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e88:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e90:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e91:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e96:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e97:	0f b6 c0             	movzbl %al,%eax
}
f0102e9a:	5d                   	pop    %ebp
f0102e9b:	c3                   	ret    

f0102e9c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e9c:	55                   	push   %ebp
f0102e9d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e9f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ea4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea7:	ee                   	out    %al,(%dx)
f0102ea8:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ead:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eb0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102eb1:	5d                   	pop    %ebp
f0102eb2:	c3                   	ret    

f0102eb3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102eb3:	55                   	push   %ebp
f0102eb4:	89 e5                	mov    %esp,%ebp
f0102eb6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102eb9:	ff 75 08             	pushl  0x8(%ebp)
f0102ebc:	e8 54 d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102ec1:	83 c4 10             	add    $0x10,%esp
f0102ec4:	c9                   	leave  
f0102ec5:	c3                   	ret    

f0102ec6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ec6:	55                   	push   %ebp
f0102ec7:	89 e5                	mov    %esp,%ebp
f0102ec9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ecc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ed3:	ff 75 0c             	pushl  0xc(%ebp)
f0102ed6:	ff 75 08             	pushl  0x8(%ebp)
f0102ed9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102edc:	50                   	push   %eax
f0102edd:	68 b3 2e 10 f0       	push   $0xf0102eb3
f0102ee2:	e8 c1 0c 00 00       	call   f0103ba8 <vprintfmt>
	return cnt;
}
f0102ee7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eea:	c9                   	leave  
f0102eeb:	c3                   	ret    

f0102eec <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102eec:	55                   	push   %ebp
f0102eed:	89 e5                	mov    %esp,%ebp
f0102eef:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ef2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ef5:	50                   	push   %eax
f0102ef6:	ff 75 08             	pushl  0x8(%ebp)
f0102ef9:	e8 c8 ff ff ff       	call   f0102ec6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102efe:	c9                   	leave  
f0102eff:	c3                   	ret    

f0102f00 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f03:	b8 c0 07 17 f0       	mov    $0xf01707c0,%eax
f0102f08:	c7 05 c4 07 17 f0 00 	movl   $0xf0000000,0xf01707c4
f0102f0f:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f12:	66 c7 05 c8 07 17 f0 	movw   $0x10,0xf01707c8
f0102f19:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f1b:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102f22:	67 00 
f0102f24:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102f2a:	89 c2                	mov    %eax,%edx
f0102f2c:	c1 ea 10             	shr    $0x10,%edx
f0102f2f:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102f35:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f3c:	c1 e8 18             	shr    $0x18,%eax
f0102f3f:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f44:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f4b:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f50:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f53:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f58:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f5b:	5d                   	pop    %ebp
f0102f5c:	c3                   	ret    

f0102f5d <trap_init>:
}


void
trap_init(void)
{
f0102f5d:	55                   	push   %ebp
f0102f5e:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0102f60:	b8 14 36 10 f0       	mov    $0xf0103614,%eax
f0102f65:	66 a3 a0 ff 16 f0    	mov    %ax,0xf016ffa0
f0102f6b:	66 c7 05 a2 ff 16 f0 	movw   $0x8,0xf016ffa2
f0102f72:	08 00 
f0102f74:	c6 05 a4 ff 16 f0 00 	movb   $0x0,0xf016ffa4
f0102f7b:	c6 05 a5 ff 16 f0 8e 	movb   $0x8e,0xf016ffa5
f0102f82:	c1 e8 10             	shr    $0x10,%eax
f0102f85:	66 a3 a6 ff 16 f0    	mov    %ax,0xf016ffa6
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f0102f8b:	b8 1a 36 10 f0       	mov    $0xf010361a,%eax
f0102f90:	66 a3 a8 ff 16 f0    	mov    %ax,0xf016ffa8
f0102f96:	66 c7 05 aa ff 16 f0 	movw   $0x8,0xf016ffaa
f0102f9d:	08 00 
f0102f9f:	c6 05 ac ff 16 f0 00 	movb   $0x0,0xf016ffac
f0102fa6:	c6 05 ad ff 16 f0 8e 	movb   $0x8e,0xf016ffad
f0102fad:	c1 e8 10             	shr    $0x10,%eax
f0102fb0:	66 a3 ae ff 16 f0    	mov    %ax,0xf016ffae
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f0102fb6:	b8 20 36 10 f0       	mov    $0xf0103620,%eax
f0102fbb:	66 a3 b0 ff 16 f0    	mov    %ax,0xf016ffb0
f0102fc1:	66 c7 05 b2 ff 16 f0 	movw   $0x8,0xf016ffb2
f0102fc8:	08 00 
f0102fca:	c6 05 b4 ff 16 f0 00 	movb   $0x0,0xf016ffb4
f0102fd1:	c6 05 b5 ff 16 f0 8e 	movb   $0x8e,0xf016ffb5
f0102fd8:	c1 e8 10             	shr    $0x10,%eax
f0102fdb:	66 a3 b6 ff 16 f0    	mov    %ax,0xf016ffb6
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f0102fe1:	b8 26 36 10 f0       	mov    $0xf0103626,%eax
f0102fe6:	66 a3 b8 ff 16 f0    	mov    %ax,0xf016ffb8
f0102fec:	66 c7 05 ba ff 16 f0 	movw   $0x8,0xf016ffba
f0102ff3:	08 00 
f0102ff5:	c6 05 bc ff 16 f0 00 	movb   $0x0,0xf016ffbc
f0102ffc:	c6 05 bd ff 16 f0 ee 	movb   $0xee,0xf016ffbd
f0103003:	c1 e8 10             	shr    $0x10,%eax
f0103006:	66 a3 be ff 16 f0    	mov    %ax,0xf016ffbe
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f010300c:	b8 2c 36 10 f0       	mov    $0xf010362c,%eax
f0103011:	66 a3 c0 ff 16 f0    	mov    %ax,0xf016ffc0
f0103017:	66 c7 05 c2 ff 16 f0 	movw   $0x8,0xf016ffc2
f010301e:	08 00 
f0103020:	c6 05 c4 ff 16 f0 00 	movb   $0x0,0xf016ffc4
f0103027:	c6 05 c5 ff 16 f0 8e 	movb   $0x8e,0xf016ffc5
f010302e:	c1 e8 10             	shr    $0x10,%eax
f0103031:	66 a3 c6 ff 16 f0    	mov    %ax,0xf016ffc6
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103037:	b8 32 36 10 f0       	mov    $0xf0103632,%eax
f010303c:	66 a3 c8 ff 16 f0    	mov    %ax,0xf016ffc8
f0103042:	66 c7 05 ca ff 16 f0 	movw   $0x8,0xf016ffca
f0103049:	08 00 
f010304b:	c6 05 cc ff 16 f0 00 	movb   $0x0,0xf016ffcc
f0103052:	c6 05 cd ff 16 f0 8e 	movb   $0x8e,0xf016ffcd
f0103059:	c1 e8 10             	shr    $0x10,%eax
f010305c:	66 a3 ce ff 16 f0    	mov    %ax,0xf016ffce
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f0103062:	b8 38 36 10 f0       	mov    $0xf0103638,%eax
f0103067:	66 a3 d0 ff 16 f0    	mov    %ax,0xf016ffd0
f010306d:	66 c7 05 d2 ff 16 f0 	movw   $0x8,0xf016ffd2
f0103074:	08 00 
f0103076:	c6 05 d4 ff 16 f0 00 	movb   $0x0,0xf016ffd4
f010307d:	c6 05 d5 ff 16 f0 8e 	movb   $0x8e,0xf016ffd5
f0103084:	c1 e8 10             	shr    $0x10,%eax
f0103087:	66 a3 d6 ff 16 f0    	mov    %ax,0xf016ffd6
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f010308d:	b8 3e 36 10 f0       	mov    $0xf010363e,%eax
f0103092:	66 a3 d8 ff 16 f0    	mov    %ax,0xf016ffd8
f0103098:	66 c7 05 da ff 16 f0 	movw   $0x8,0xf016ffda
f010309f:	08 00 
f01030a1:	c6 05 dc ff 16 f0 00 	movb   $0x0,0xf016ffdc
f01030a8:	c6 05 dd ff 16 f0 8e 	movb   $0x8e,0xf016ffdd
f01030af:	c1 e8 10             	shr    $0x10,%eax
f01030b2:	66 a3 de ff 16 f0    	mov    %ax,0xf016ffde
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01030b8:	b8 44 36 10 f0       	mov    $0xf0103644,%eax
f01030bd:	66 a3 e0 ff 16 f0    	mov    %ax,0xf016ffe0
f01030c3:	66 c7 05 e2 ff 16 f0 	movw   $0x8,0xf016ffe2
f01030ca:	08 00 
f01030cc:	c6 05 e4 ff 16 f0 00 	movb   $0x0,0xf016ffe4
f01030d3:	c6 05 e5 ff 16 f0 8e 	movb   $0x8e,0xf016ffe5
f01030da:	c1 e8 10             	shr    $0x10,%eax
f01030dd:	66 a3 e6 ff 16 f0    	mov    %ax,0xf016ffe6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f01030e3:	b8 48 36 10 f0       	mov    $0xf0103648,%eax
f01030e8:	66 a3 f0 ff 16 f0    	mov    %ax,0xf016fff0
f01030ee:	66 c7 05 f2 ff 16 f0 	movw   $0x8,0xf016fff2
f01030f5:	08 00 
f01030f7:	c6 05 f4 ff 16 f0 00 	movb   $0x0,0xf016fff4
f01030fe:	c6 05 f5 ff 16 f0 8e 	movb   $0x8e,0xf016fff5
f0103105:	c1 e8 10             	shr    $0x10,%eax
f0103108:	66 a3 f6 ff 16 f0    	mov    %ax,0xf016fff6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f010310e:	b8 4c 36 10 f0       	mov    $0xf010364c,%eax
f0103113:	66 a3 f8 ff 16 f0    	mov    %ax,0xf016fff8
f0103119:	66 c7 05 fa ff 16 f0 	movw   $0x8,0xf016fffa
f0103120:	08 00 
f0103122:	c6 05 fc ff 16 f0 00 	movb   $0x0,0xf016fffc
f0103129:	c6 05 fd ff 16 f0 8e 	movb   $0x8e,0xf016fffd
f0103130:	c1 e8 10             	shr    $0x10,%eax
f0103133:	66 a3 fe ff 16 f0    	mov    %ax,0xf016fffe
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103139:	b8 50 36 10 f0       	mov    $0xf0103650,%eax
f010313e:	66 a3 00 00 17 f0    	mov    %ax,0xf0170000
f0103144:	66 c7 05 02 00 17 f0 	movw   $0x8,0xf0170002
f010314b:	08 00 
f010314d:	c6 05 04 00 17 f0 00 	movb   $0x0,0xf0170004
f0103154:	c6 05 05 00 17 f0 8e 	movb   $0x8e,0xf0170005
f010315b:	c1 e8 10             	shr    $0x10,%eax
f010315e:	66 a3 06 00 17 f0    	mov    %ax,0xf0170006
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103164:	b8 54 36 10 f0       	mov    $0xf0103654,%eax
f0103169:	66 a3 08 00 17 f0    	mov    %ax,0xf0170008
f010316f:	66 c7 05 0a 00 17 f0 	movw   $0x8,0xf017000a
f0103176:	08 00 
f0103178:	c6 05 0c 00 17 f0 00 	movb   $0x0,0xf017000c
f010317f:	c6 05 0d 00 17 f0 8e 	movb   $0x8e,0xf017000d
f0103186:	c1 e8 10             	shr    $0x10,%eax
f0103189:	66 a3 0e 00 17 f0    	mov    %ax,0xf017000e
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f010318f:	b8 58 36 10 f0       	mov    $0xf0103658,%eax
f0103194:	66 a3 10 00 17 f0    	mov    %ax,0xf0170010
f010319a:	66 c7 05 12 00 17 f0 	movw   $0x8,0xf0170012
f01031a1:	08 00 
f01031a3:	c6 05 14 00 17 f0 00 	movb   $0x0,0xf0170014
f01031aa:	c6 05 15 00 17 f0 8e 	movb   $0x8e,0xf0170015
f01031b1:	c1 e8 10             	shr    $0x10,%eax
f01031b4:	66 a3 16 00 17 f0    	mov    %ax,0xf0170016
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01031ba:	b8 5c 36 10 f0       	mov    $0xf010365c,%eax
f01031bf:	66 a3 20 00 17 f0    	mov    %ax,0xf0170020
f01031c5:	66 c7 05 22 00 17 f0 	movw   $0x8,0xf0170022
f01031cc:	08 00 
f01031ce:	c6 05 24 00 17 f0 00 	movb   $0x0,0xf0170024
f01031d5:	c6 05 25 00 17 f0 8e 	movb   $0x8e,0xf0170025
f01031dc:	c1 e8 10             	shr    $0x10,%eax
f01031df:	66 a3 26 00 17 f0    	mov    %ax,0xf0170026
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f01031e5:	b8 62 36 10 f0       	mov    $0xf0103662,%eax
f01031ea:	66 a3 28 00 17 f0    	mov    %ax,0xf0170028
f01031f0:	66 c7 05 2a 00 17 f0 	movw   $0x8,0xf017002a
f01031f7:	08 00 
f01031f9:	c6 05 2c 00 17 f0 00 	movb   $0x0,0xf017002c
f0103200:	c6 05 2d 00 17 f0 8e 	movb   $0x8e,0xf017002d
f0103207:	c1 e8 10             	shr    $0x10,%eax
f010320a:	66 a3 2e 00 17 f0    	mov    %ax,0xf017002e
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103210:	b8 66 36 10 f0       	mov    $0xf0103666,%eax
f0103215:	66 a3 30 00 17 f0    	mov    %ax,0xf0170030
f010321b:	66 c7 05 32 00 17 f0 	movw   $0x8,0xf0170032
f0103222:	08 00 
f0103224:	c6 05 34 00 17 f0 00 	movb   $0x0,0xf0170034
f010322b:	c6 05 35 00 17 f0 8e 	movb   $0x8e,0xf0170035
f0103232:	c1 e8 10             	shr    $0x10,%eax
f0103235:	66 a3 36 00 17 f0    	mov    %ax,0xf0170036
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f010323b:	b8 6c 36 10 f0       	mov    $0xf010366c,%eax
f0103240:	66 a3 38 00 17 f0    	mov    %ax,0xf0170038
f0103246:	66 c7 05 3a 00 17 f0 	movw   $0x8,0xf017003a
f010324d:	08 00 
f010324f:	c6 05 3c 00 17 f0 00 	movb   $0x0,0xf017003c
f0103256:	c6 05 3d 00 17 f0 8e 	movb   $0x8e,0xf017003d
f010325d:	c1 e8 10             	shr    $0x10,%eax
f0103260:	66 a3 3e 00 17 f0    	mov    %ax,0xf017003e
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f0103266:	b8 72 36 10 f0       	mov    $0xf0103672,%eax
f010326b:	66 a3 20 01 17 f0    	mov    %ax,0xf0170120
f0103271:	66 c7 05 22 01 17 f0 	movw   $0x8,0xf0170122
f0103278:	08 00 
f010327a:	c6 05 24 01 17 f0 00 	movb   $0x0,0xf0170124
f0103281:	c6 05 25 01 17 f0 ef 	movb   $0xef,0xf0170125
f0103288:	c1 e8 10             	shr    $0x10,%eax
f010328b:	66 a3 26 01 17 f0    	mov    %ax,0xf0170126

	// Per-CPU setup 
	trap_init_percpu();
f0103291:	e8 6a fc ff ff       	call   f0102f00 <trap_init_percpu>
}
f0103296:	5d                   	pop    %ebp
f0103297:	c3                   	ret    

f0103298 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103298:	55                   	push   %ebp
f0103299:	89 e5                	mov    %esp,%ebp
f010329b:	53                   	push   %ebx
f010329c:	83 ec 0c             	sub    $0xc,%esp
f010329f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032a2:	ff 33                	pushl  (%ebx)
f01032a4:	68 6e 57 10 f0       	push   $0xf010576e
f01032a9:	e8 3e fc ff ff       	call   f0102eec <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032ae:	83 c4 08             	add    $0x8,%esp
f01032b1:	ff 73 04             	pushl  0x4(%ebx)
f01032b4:	68 7d 57 10 f0       	push   $0xf010577d
f01032b9:	e8 2e fc ff ff       	call   f0102eec <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01032be:	83 c4 08             	add    $0x8,%esp
f01032c1:	ff 73 08             	pushl  0x8(%ebx)
f01032c4:	68 8c 57 10 f0       	push   $0xf010578c
f01032c9:	e8 1e fc ff ff       	call   f0102eec <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01032ce:	83 c4 08             	add    $0x8,%esp
f01032d1:	ff 73 0c             	pushl  0xc(%ebx)
f01032d4:	68 9b 57 10 f0       	push   $0xf010579b
f01032d9:	e8 0e fc ff ff       	call   f0102eec <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01032de:	83 c4 08             	add    $0x8,%esp
f01032e1:	ff 73 10             	pushl  0x10(%ebx)
f01032e4:	68 aa 57 10 f0       	push   $0xf01057aa
f01032e9:	e8 fe fb ff ff       	call   f0102eec <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01032ee:	83 c4 08             	add    $0x8,%esp
f01032f1:	ff 73 14             	pushl  0x14(%ebx)
f01032f4:	68 b9 57 10 f0       	push   $0xf01057b9
f01032f9:	e8 ee fb ff ff       	call   f0102eec <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01032fe:	83 c4 08             	add    $0x8,%esp
f0103301:	ff 73 18             	pushl  0x18(%ebx)
f0103304:	68 c8 57 10 f0       	push   $0xf01057c8
f0103309:	e8 de fb ff ff       	call   f0102eec <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010330e:	83 c4 08             	add    $0x8,%esp
f0103311:	ff 73 1c             	pushl  0x1c(%ebx)
f0103314:	68 d7 57 10 f0       	push   $0xf01057d7
f0103319:	e8 ce fb ff ff       	call   f0102eec <cprintf>
}
f010331e:	83 c4 10             	add    $0x10,%esp
f0103321:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103324:	c9                   	leave  
f0103325:	c3                   	ret    

f0103326 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103326:	55                   	push   %ebp
f0103327:	89 e5                	mov    %esp,%ebp
f0103329:	56                   	push   %esi
f010332a:	53                   	push   %ebx
f010332b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010332e:	83 ec 08             	sub    $0x8,%esp
f0103331:	53                   	push   %ebx
f0103332:	68 0d 59 10 f0       	push   $0xf010590d
f0103337:	e8 b0 fb ff ff       	call   f0102eec <cprintf>
	print_regs(&tf->tf_regs);
f010333c:	89 1c 24             	mov    %ebx,(%esp)
f010333f:	e8 54 ff ff ff       	call   f0103298 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103344:	83 c4 08             	add    $0x8,%esp
f0103347:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010334b:	50                   	push   %eax
f010334c:	68 28 58 10 f0       	push   $0xf0105828
f0103351:	e8 96 fb ff ff       	call   f0102eec <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103356:	83 c4 08             	add    $0x8,%esp
f0103359:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010335d:	50                   	push   %eax
f010335e:	68 3b 58 10 f0       	push   $0xf010583b
f0103363:	e8 84 fb ff ff       	call   f0102eec <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103368:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010336b:	83 c4 10             	add    $0x10,%esp
f010336e:	83 f8 13             	cmp    $0x13,%eax
f0103371:	77 09                	ja     f010337c <print_trapframe+0x56>
		return excnames[trapno];
f0103373:	8b 14 85 e0 5a 10 f0 	mov    -0xfefa520(,%eax,4),%edx
f010337a:	eb 10                	jmp    f010338c <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f010337c:	83 f8 30             	cmp    $0x30,%eax
f010337f:	b9 f2 57 10 f0       	mov    $0xf01057f2,%ecx
f0103384:	ba e6 57 10 f0       	mov    $0xf01057e6,%edx
f0103389:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010338c:	83 ec 04             	sub    $0x4,%esp
f010338f:	52                   	push   %edx
f0103390:	50                   	push   %eax
f0103391:	68 4e 58 10 f0       	push   $0xf010584e
f0103396:	e8 51 fb ff ff       	call   f0102eec <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010339b:	83 c4 10             	add    $0x10,%esp
f010339e:	3b 1d a0 07 17 f0    	cmp    0xf01707a0,%ebx
f01033a4:	75 1a                	jne    f01033c0 <print_trapframe+0x9a>
f01033a6:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033aa:	75 14                	jne    f01033c0 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01033ac:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033af:	83 ec 08             	sub    $0x8,%esp
f01033b2:	50                   	push   %eax
f01033b3:	68 60 58 10 f0       	push   $0xf0105860
f01033b8:	e8 2f fb ff ff       	call   f0102eec <cprintf>
f01033bd:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01033c0:	83 ec 08             	sub    $0x8,%esp
f01033c3:	ff 73 2c             	pushl  0x2c(%ebx)
f01033c6:	68 6f 58 10 f0       	push   $0xf010586f
f01033cb:	e8 1c fb ff ff       	call   f0102eec <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01033d0:	83 c4 10             	add    $0x10,%esp
f01033d3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033d7:	75 49                	jne    f0103422 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01033d9:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01033dc:	89 c2                	mov    %eax,%edx
f01033de:	83 e2 01             	and    $0x1,%edx
f01033e1:	ba 0c 58 10 f0       	mov    $0xf010580c,%edx
f01033e6:	b9 01 58 10 f0       	mov    $0xf0105801,%ecx
f01033eb:	0f 44 ca             	cmove  %edx,%ecx
f01033ee:	89 c2                	mov    %eax,%edx
f01033f0:	83 e2 02             	and    $0x2,%edx
f01033f3:	ba 1e 58 10 f0       	mov    $0xf010581e,%edx
f01033f8:	be 18 58 10 f0       	mov    $0xf0105818,%esi
f01033fd:	0f 45 d6             	cmovne %esi,%edx
f0103400:	83 e0 04             	and    $0x4,%eax
f0103403:	be 38 59 10 f0       	mov    $0xf0105938,%esi
f0103408:	b8 23 58 10 f0       	mov    $0xf0105823,%eax
f010340d:	0f 44 c6             	cmove  %esi,%eax
f0103410:	51                   	push   %ecx
f0103411:	52                   	push   %edx
f0103412:	50                   	push   %eax
f0103413:	68 7d 58 10 f0       	push   $0xf010587d
f0103418:	e8 cf fa ff ff       	call   f0102eec <cprintf>
f010341d:	83 c4 10             	add    $0x10,%esp
f0103420:	eb 10                	jmp    f0103432 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103422:	83 ec 0c             	sub    $0xc,%esp
f0103425:	68 74 56 10 f0       	push   $0xf0105674
f010342a:	e8 bd fa ff ff       	call   f0102eec <cprintf>
f010342f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103432:	83 ec 08             	sub    $0x8,%esp
f0103435:	ff 73 30             	pushl  0x30(%ebx)
f0103438:	68 8c 58 10 f0       	push   $0xf010588c
f010343d:	e8 aa fa ff ff       	call   f0102eec <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103442:	83 c4 08             	add    $0x8,%esp
f0103445:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103449:	50                   	push   %eax
f010344a:	68 9b 58 10 f0       	push   $0xf010589b
f010344f:	e8 98 fa ff ff       	call   f0102eec <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103454:	83 c4 08             	add    $0x8,%esp
f0103457:	ff 73 38             	pushl  0x38(%ebx)
f010345a:	68 ae 58 10 f0       	push   $0xf01058ae
f010345f:	e8 88 fa ff ff       	call   f0102eec <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103464:	83 c4 10             	add    $0x10,%esp
f0103467:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010346b:	74 25                	je     f0103492 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010346d:	83 ec 08             	sub    $0x8,%esp
f0103470:	ff 73 3c             	pushl  0x3c(%ebx)
f0103473:	68 bd 58 10 f0       	push   $0xf01058bd
f0103478:	e8 6f fa ff ff       	call   f0102eec <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010347d:	83 c4 08             	add    $0x8,%esp
f0103480:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103484:	50                   	push   %eax
f0103485:	68 cc 58 10 f0       	push   $0xf01058cc
f010348a:	e8 5d fa ff ff       	call   f0102eec <cprintf>
f010348f:	83 c4 10             	add    $0x10,%esp
	}
}
f0103492:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103495:	5b                   	pop    %ebx
f0103496:	5e                   	pop    %esi
f0103497:	5d                   	pop    %ebp
f0103498:	c3                   	ret    

f0103499 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103499:	55                   	push   %ebp
f010349a:	89 e5                	mov    %esp,%ebp
f010349c:	53                   	push   %ebx
f010349d:	83 ec 04             	sub    $0x4,%esp
f01034a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034a3:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034a6:	ff 73 30             	pushl  0x30(%ebx)
f01034a9:	50                   	push   %eax
f01034aa:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01034af:	ff 70 48             	pushl  0x48(%eax)
f01034b2:	68 84 5a 10 f0       	push   $0xf0105a84
f01034b7:	e8 30 fa ff ff       	call   f0102eec <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01034bc:	89 1c 24             	mov    %ebx,(%esp)
f01034bf:	e8 62 fe ff ff       	call   f0103326 <print_trapframe>
	env_destroy(curenv);
f01034c4:	83 c4 04             	add    $0x4,%esp
f01034c7:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f01034cd:	e8 01 f9 ff ff       	call   f0102dd3 <env_destroy>
}
f01034d2:	83 c4 10             	add    $0x10,%esp
f01034d5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034d8:	c9                   	leave  
f01034d9:	c3                   	ret    

f01034da <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01034da:	55                   	push   %ebp
f01034db:	89 e5                	mov    %esp,%ebp
f01034dd:	57                   	push   %edi
f01034de:	56                   	push   %esi
f01034df:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01034e2:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01034e3:	9c                   	pushf  
f01034e4:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01034e5:	f6 c4 02             	test   $0x2,%ah
f01034e8:	74 19                	je     f0103503 <trap+0x29>
f01034ea:	68 df 58 10 f0       	push   $0xf01058df
f01034ef:	68 cd 53 10 f0       	push   $0xf01053cd
f01034f4:	68 cf 00 00 00       	push   $0xcf
f01034f9:	68 f8 58 10 f0       	push   $0xf01058f8
f01034fe:	e8 9d cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103503:	83 ec 08             	sub    $0x8,%esp
f0103506:	56                   	push   %esi
f0103507:	68 04 59 10 f0       	push   $0xf0105904
f010350c:	e8 db f9 ff ff       	call   f0102eec <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103511:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103515:	83 e0 03             	and    $0x3,%eax
f0103518:	83 c4 10             	add    $0x10,%esp
f010351b:	66 83 f8 03          	cmp    $0x3,%ax
f010351f:	75 31                	jne    f0103552 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103521:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f0103526:	85 c0                	test   %eax,%eax
f0103528:	75 19                	jne    f0103543 <trap+0x69>
f010352a:	68 1f 59 10 f0       	push   $0xf010591f
f010352f:	68 cd 53 10 f0       	push   $0xf01053cd
f0103534:	68 d5 00 00 00       	push   $0xd5
f0103539:	68 f8 58 10 f0       	push   $0xf01058f8
f010353e:	e8 5d cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103543:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103548:	89 c7                	mov    %eax,%edi
f010354a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010354c:	8b 35 80 ff 16 f0    	mov    0xf016ff80,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103552:	89 35 a0 07 17 f0    	mov    %esi,0xf01707a0
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	
	switch(tf->tf_trapno)
f0103558:	8b 46 28             	mov    0x28(%esi),%eax
f010355b:	83 f8 0e             	cmp    $0xe,%eax
f010355e:	74 0c                	je     f010356c <trap+0x92>
f0103560:	83 f8 30             	cmp    $0x30,%eax
f0103563:	74 23                	je     f0103588 <trap+0xae>
f0103565:	83 f8 03             	cmp    $0x3,%eax
f0103568:	75 3d                	jne    f01035a7 <trap+0xcd>
f010356a:	eb 0e                	jmp    f010357a <trap+0xa0>
	{
		case T_PGFLT:
			page_fault_handler(tf);
f010356c:	83 ec 0c             	sub    $0xc,%esp
f010356f:	56                   	push   %esi
f0103570:	e8 24 ff ff ff       	call   f0103499 <page_fault_handler>
f0103575:	83 c4 10             	add    $0x10,%esp
f0103578:	eb 2d                	jmp    f01035a7 <trap+0xcd>
			break;
		case T_BRKPT:
			monitor(tf);
f010357a:	83 ec 0c             	sub    $0xc,%esp
f010357d:	56                   	push   %esi
f010357e:	e8 6e d2 ff ff       	call   f01007f1 <monitor>
f0103583:	83 c4 10             	add    $0x10,%esp
f0103586:	eb 1f                	jmp    f01035a7 <trap+0xcd>
			break;
		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(\
f0103588:	83 ec 08             	sub    $0x8,%esp
f010358b:	ff 76 04             	pushl  0x4(%esi)
f010358e:	ff 36                	pushl  (%esi)
f0103590:	ff 76 10             	pushl  0x10(%esi)
f0103593:	ff 76 18             	pushl  0x18(%esi)
f0103596:	ff 76 14             	pushl  0x14(%esi)
f0103599:	ff 76 1c             	pushl  0x1c(%esi)
f010359c:	e8 e9 00 00 00       	call   f010368a <syscall>
f01035a1:	89 46 1c             	mov    %eax,0x1c(%esi)
f01035a4:	83 c4 20             	add    $0x20,%esp
			);
			break;
	}
	
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01035a7:	83 ec 0c             	sub    $0xc,%esp
f01035aa:	56                   	push   %esi
f01035ab:	e8 76 fd ff ff       	call   f0103326 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01035b0:	83 c4 10             	add    $0x10,%esp
f01035b3:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01035b8:	75 17                	jne    f01035d1 <trap+0xf7>
		panic("unhandled trap in kernel");
f01035ba:	83 ec 04             	sub    $0x4,%esp
f01035bd:	68 26 59 10 f0       	push   $0xf0105926
f01035c2:	68 be 00 00 00       	push   $0xbe
f01035c7:	68 f8 58 10 f0       	push   $0xf01058f8
f01035cc:	e8 cf ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01035d1:	83 ec 0c             	sub    $0xc,%esp
f01035d4:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f01035da:	e8 f4 f7 ff ff       	call   f0102dd3 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01035df:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01035e4:	83 c4 10             	add    $0x10,%esp
f01035e7:	85 c0                	test   %eax,%eax
f01035e9:	74 06                	je     f01035f1 <trap+0x117>
f01035eb:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035ef:	74 19                	je     f010360a <trap+0x130>
f01035f1:	68 a8 5a 10 f0       	push   $0xf0105aa8
f01035f6:	68 cd 53 10 f0       	push   $0xf01053cd
f01035fb:	68 e7 00 00 00       	push   $0xe7
f0103600:	68 f8 58 10 f0       	push   $0xf01058f8
f0103605:	e8 96 ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f010360a:	83 ec 0c             	sub    $0xc,%esp
f010360d:	50                   	push   %eax
f010360e:	e8 10 f8 ff ff       	call   f0102e23 <env_run>
f0103613:	90                   	nop

f0103614 <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f0103614:	6a 00                	push   $0x0
f0103616:	6a 00                	push   $0x0
f0103618:	eb 5e                	jmp    f0103678 <_alltraps>

f010361a <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f010361a:	6a 00                	push   $0x0
f010361c:	6a 01                	push   $0x1
f010361e:	eb 58                	jmp    f0103678 <_alltraps>

f0103620 <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f0103620:	6a 00                	push   $0x0
f0103622:	6a 02                	push   $0x2
f0103624:	eb 52                	jmp    f0103678 <_alltraps>

f0103626 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0103626:	6a 00                	push   $0x0
f0103628:	6a 03                	push   $0x3
f010362a:	eb 4c                	jmp    f0103678 <_alltraps>

f010362c <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f010362c:	6a 00                	push   $0x0
f010362e:	6a 04                	push   $0x4
f0103630:	eb 46                	jmp    f0103678 <_alltraps>

f0103632 <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f0103632:	6a 00                	push   $0x0
f0103634:	6a 05                	push   $0x5
f0103636:	eb 40                	jmp    f0103678 <_alltraps>

f0103638 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f0103638:	6a 00                	push   $0x0
f010363a:	6a 06                	push   $0x6
f010363c:	eb 3a                	jmp    f0103678 <_alltraps>

f010363e <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f010363e:	6a 00                	push   $0x0
f0103640:	6a 07                	push   $0x7
f0103642:	eb 34                	jmp    f0103678 <_alltraps>

f0103644 <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f0103644:	6a 08                	push   $0x8
f0103646:	eb 30                	jmp    f0103678 <_alltraps>

f0103648 <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f0103648:	6a 0a                	push   $0xa
f010364a:	eb 2c                	jmp    f0103678 <_alltraps>

f010364c <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f010364c:	6a 0b                	push   $0xb
f010364e:	eb 28                	jmp    f0103678 <_alltraps>

f0103650 <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f0103650:	6a 0c                	push   $0xc
f0103652:	eb 24                	jmp    f0103678 <_alltraps>

f0103654 <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f0103654:	6a 0d                	push   $0xd
f0103656:	eb 20                	jmp    f0103678 <_alltraps>

f0103658 <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f0103658:	6a 0e                	push   $0xe
f010365a:	eb 1c                	jmp    f0103678 <_alltraps>

f010365c <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f010365c:	6a 00                	push   $0x0
f010365e:	6a 10                	push   $0x10
f0103660:	eb 16                	jmp    f0103678 <_alltraps>

f0103662 <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f0103662:	6a 11                	push   $0x11
f0103664:	eb 12                	jmp    f0103678 <_alltraps>

f0103666 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f0103666:	6a 00                	push   $0x0
f0103668:	6a 12                	push   $0x12
f010366a:	eb 0c                	jmp    f0103678 <_alltraps>

f010366c <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f010366c:	6a 00                	push   $0x0
f010366e:	6a 13                	push   $0x13
f0103670:	eb 06                	jmp    f0103678 <_alltraps>

f0103672 <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f0103672:	6a 00                	push   $0x0
f0103674:	6a 30                	push   $0x30
f0103676:	eb 00                	jmp    f0103678 <_alltraps>

f0103678 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f0103678:	1e                   	push   %ds
	pushl	%es
f0103679:	06                   	push   %es
	pushal
f010367a:	60                   	pusha  
	mov	$GD_KD, %eax
f010367b:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f0103680:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f0103682:	8e d8                	mov    %eax,%ds
	pushl	%esp
f0103684:	54                   	push   %esp
	call	trap
f0103685:	e8 50 fe ff ff       	call   f01034da <trap>

f010368a <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010368a:	55                   	push   %ebp
f010368b:	89 e5                	mov    %esp,%ebp
f010368d:	83 ec 18             	sub    $0x18,%esp
f0103690:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) 
f0103693:	83 f8 01             	cmp    $0x1,%eax
f0103696:	74 31                	je     f01036c9 <syscall+0x3f>
f0103698:	83 f8 01             	cmp    $0x1,%eax
f010369b:	72 0f                	jb     f01036ac <syscall+0x22>
f010369d:	83 f8 02             	cmp    $0x2,%eax
f01036a0:	74 2e                	je     f01036d0 <syscall+0x46>
f01036a2:	83 f8 03             	cmp    $0x3,%eax
f01036a5:	74 33                	je     f01036da <syscall+0x50>
f01036a7:	e9 93 00 00 00       	jmp    f010373f <syscall+0xb5>
	// Destroy the environment if not.

	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01036ac:	83 ec 04             	sub    $0x4,%esp
f01036af:	ff 75 0c             	pushl  0xc(%ebp)
f01036b2:	ff 75 10             	pushl  0x10(%ebp)
f01036b5:	68 30 5b 10 f0       	push   $0xf0105b30
f01036ba:	e8 2d f8 ff ff       	call   f0102eec <cprintf>
f01036bf:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) 
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
f01036c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01036c7:	eb 7b                	jmp    f0103744 <syscall+0xba>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01036c9:	e8 f5 cd ff ff       	call   f01004c3 <cons_getc>
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f01036ce:	eb 74                	jmp    f0103744 <syscall+0xba>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01036d0:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01036d5:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char*)a1,(size_t)a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return (int32_t)sys_getenvid();			
f01036d8:	eb 6a                	jmp    f0103744 <syscall+0xba>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01036da:	83 ec 04             	sub    $0x4,%esp
f01036dd:	6a 01                	push   $0x1
f01036df:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036e2:	50                   	push   %eax
f01036e3:	ff 75 0c             	pushl  0xc(%ebp)
f01036e6:	e8 a5 f1 ff ff       	call   f0102890 <envid2env>
f01036eb:	83 c4 10             	add    $0x10,%esp
f01036ee:	85 c0                	test   %eax,%eax
f01036f0:	78 52                	js     f0103744 <syscall+0xba>
		return r;
	if (e == curenv)
f01036f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036f5:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f01036fb:	39 d0                	cmp    %edx,%eax
f01036fd:	75 15                	jne    f0103714 <syscall+0x8a>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01036ff:	83 ec 08             	sub    $0x8,%esp
f0103702:	ff 70 48             	pushl  0x48(%eax)
f0103705:	68 35 5b 10 f0       	push   $0xf0105b35
f010370a:	e8 dd f7 ff ff       	call   f0102eec <cprintf>
f010370f:	83 c4 10             	add    $0x10,%esp
f0103712:	eb 16                	jmp    f010372a <syscall+0xa0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103714:	83 ec 04             	sub    $0x4,%esp
f0103717:	ff 70 48             	pushl  0x48(%eax)
f010371a:	ff 72 48             	pushl  0x48(%edx)
f010371d:	68 50 5b 10 f0       	push   $0xf0105b50
f0103722:	e8 c5 f7 ff ff       	call   f0102eec <cprintf>
f0103727:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010372a:	83 ec 0c             	sub    $0xc,%esp
f010372d:	ff 75 f4             	pushl  -0xc(%ebp)
f0103730:	e8 9e f6 ff ff       	call   f0102dd3 <env_destroy>
f0103735:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103738:	b8 00 00 00 00       	mov    $0x0,%eax
f010373d:	eb 05                	jmp    f0103744 <syscall+0xba>
		case SYS_getenvid:
			return (int32_t)sys_getenvid();			
		case SYS_env_destroy:
			return sys_env_destroy((envid_t)a1);
		default:
			return -E_INVAL;
f010373f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0103744:	c9                   	leave  
f0103745:	c3                   	ret    

f0103746 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103746:	55                   	push   %ebp
f0103747:	89 e5                	mov    %esp,%ebp
f0103749:	57                   	push   %edi
f010374a:	56                   	push   %esi
f010374b:	53                   	push   %ebx
f010374c:	83 ec 14             	sub    $0x14,%esp
f010374f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103752:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103755:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103758:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010375b:	8b 1a                	mov    (%edx),%ebx
f010375d:	8b 01                	mov    (%ecx),%eax
f010375f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103762:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103769:	eb 7f                	jmp    f01037ea <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010376b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010376e:	01 d8                	add    %ebx,%eax
f0103770:	89 c6                	mov    %eax,%esi
f0103772:	c1 ee 1f             	shr    $0x1f,%esi
f0103775:	01 c6                	add    %eax,%esi
f0103777:	d1 fe                	sar    %esi
f0103779:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010377c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010377f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103782:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103784:	eb 03                	jmp    f0103789 <stab_binsearch+0x43>
			m--;
f0103786:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103789:	39 c3                	cmp    %eax,%ebx
f010378b:	7f 0d                	jg     f010379a <stab_binsearch+0x54>
f010378d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103791:	83 ea 0c             	sub    $0xc,%edx
f0103794:	39 f9                	cmp    %edi,%ecx
f0103796:	75 ee                	jne    f0103786 <stab_binsearch+0x40>
f0103798:	eb 05                	jmp    f010379f <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010379a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010379d:	eb 4b                	jmp    f01037ea <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010379f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037a2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037a5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01037a9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037ac:	76 11                	jbe    f01037bf <stab_binsearch+0x79>
			*region_left = m;
f01037ae:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01037b1:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01037b3:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037b6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037bd:	eb 2b                	jmp    f01037ea <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01037bf:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01037c2:	73 14                	jae    f01037d8 <stab_binsearch+0x92>
			*region_right = m - 1;
f01037c4:	83 e8 01             	sub    $0x1,%eax
f01037c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037ca:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037cd:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037cf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037d6:	eb 12                	jmp    f01037ea <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01037d8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037db:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01037dd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01037e1:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037e3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01037ea:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01037ed:	0f 8e 78 ff ff ff    	jle    f010376b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01037f3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01037f7:	75 0f                	jne    f0103808 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01037f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037fc:	8b 00                	mov    (%eax),%eax
f01037fe:	83 e8 01             	sub    $0x1,%eax
f0103801:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103804:	89 06                	mov    %eax,(%esi)
f0103806:	eb 2c                	jmp    f0103834 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103808:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010380b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010380d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103810:	8b 0e                	mov    (%esi),%ecx
f0103812:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103815:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103818:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010381b:	eb 03                	jmp    f0103820 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010381d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103820:	39 c8                	cmp    %ecx,%eax
f0103822:	7e 0b                	jle    f010382f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103824:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103828:	83 ea 0c             	sub    $0xc,%edx
f010382b:	39 df                	cmp    %ebx,%edi
f010382d:	75 ee                	jne    f010381d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010382f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103832:	89 06                	mov    %eax,(%esi)
	}
}
f0103834:	83 c4 14             	add    $0x14,%esp
f0103837:	5b                   	pop    %ebx
f0103838:	5e                   	pop    %esi
f0103839:	5f                   	pop    %edi
f010383a:	5d                   	pop    %ebp
f010383b:	c3                   	ret    

f010383c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010383c:	55                   	push   %ebp
f010383d:	89 e5                	mov    %esp,%ebp
f010383f:	57                   	push   %edi
f0103840:	56                   	push   %esi
f0103841:	53                   	push   %ebx
f0103842:	83 ec 3c             	sub    $0x3c,%esp
f0103845:	8b 75 08             	mov    0x8(%ebp),%esi
f0103848:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010384b:	c7 03 68 5b 10 f0    	movl   $0xf0105b68,(%ebx)
	info->eip_line = 0;
f0103851:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103858:	c7 43 08 68 5b 10 f0 	movl   $0xf0105b68,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010385f:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103866:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103869:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103870:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103876:	77 21                	ja     f0103899 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103878:	a1 00 00 20 00       	mov    0x200000,%eax
f010387d:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0103880:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103885:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f010388b:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010388e:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103894:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103897:	eb 1a                	jmp    f01038b3 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103899:	c7 45 c0 ac fe 10 f0 	movl   $0xf010feac,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01038a0:	c7 45 b8 b5 d4 10 f0 	movl   $0xf010d4b5,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01038a7:	b8 b4 d4 10 f0       	mov    $0xf010d4b4,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01038ac:	c7 45 bc 80 5d 10 f0 	movl   $0xf0105d80,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01038b3:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01038b6:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f01038b9:	0f 83 9d 01 00 00    	jae    f0103a5c <debuginfo_eip+0x220>
f01038bf:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01038c3:	0f 85 9a 01 00 00    	jne    f0103a63 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01038c9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01038d0:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01038d3:	29 f8                	sub    %edi,%eax
f01038d5:	c1 f8 02             	sar    $0x2,%eax
f01038d8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01038de:	83 e8 01             	sub    $0x1,%eax
f01038e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01038e4:	56                   	push   %esi
f01038e5:	6a 64                	push   $0x64
f01038e7:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01038ea:	89 c1                	mov    %eax,%ecx
f01038ec:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01038ef:	89 f8                	mov    %edi,%eax
f01038f1:	e8 50 fe ff ff       	call   f0103746 <stab_binsearch>
	if (lfile == 0)
f01038f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038f9:	83 c4 08             	add    $0x8,%esp
f01038fc:	85 c0                	test   %eax,%eax
f01038fe:	0f 84 66 01 00 00    	je     f0103a6a <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103904:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103907:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010390a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010390d:	56                   	push   %esi
f010390e:	6a 24                	push   $0x24
f0103910:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103913:	89 c1                	mov    %eax,%ecx
f0103915:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103918:	89 f8                	mov    %edi,%eax
f010391a:	e8 27 fe ff ff       	call   f0103746 <stab_binsearch>

	if (lfun <= rfun) {
f010391f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103922:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103925:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103928:	83 c4 08             	add    $0x8,%esp
f010392b:	39 d0                	cmp    %edx,%eax
f010392d:	7f 2b                	jg     f010395a <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010392f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103932:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103935:	8b 11                	mov    (%ecx),%edx
f0103937:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010393a:	2b 7d b8             	sub    -0x48(%ebp),%edi
f010393d:	39 fa                	cmp    %edi,%edx
f010393f:	73 06                	jae    f0103947 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103941:	03 55 b8             	add    -0x48(%ebp),%edx
f0103944:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103947:	8b 51 08             	mov    0x8(%ecx),%edx
f010394a:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010394d:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010394f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103952:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103955:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103958:	eb 0f                	jmp    f0103969 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010395a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010395d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103960:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103963:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103966:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103969:	83 ec 08             	sub    $0x8,%esp
f010396c:	6a 3a                	push   $0x3a
f010396e:	ff 73 08             	pushl  0x8(%ebx)
f0103971:	e8 82 08 00 00       	call   f01041f8 <strfind>
f0103976:	2b 43 08             	sub    0x8(%ebx),%eax
f0103979:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010397c:	83 c4 08             	add    $0x8,%esp
f010397f:	56                   	push   %esi
f0103980:	6a 44                	push   $0x44
f0103982:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103985:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103988:	8b 75 bc             	mov    -0x44(%ebp),%esi
f010398b:	89 f0                	mov    %esi,%eax
f010398d:	e8 b4 fd ff ff       	call   f0103746 <stab_binsearch>
	if(lline > rline)
f0103992:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103995:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103998:	83 c4 10             	add    $0x10,%esp
f010399b:	39 c2                	cmp    %eax,%edx
f010399d:	0f 8f ce 00 00 00    	jg     f0103a71 <debuginfo_eip+0x235>
	return -1;
	info->eip_line =  stabs[rline].n_desc;	
f01039a3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01039a6:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f01039ab:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01039ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01039b1:	89 d0                	mov    %edx,%eax
f01039b3:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01039b6:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01039b9:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01039bd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01039c0:	eb 0a                	jmp    f01039cc <debuginfo_eip+0x190>
f01039c2:	83 e8 01             	sub    $0x1,%eax
f01039c5:	83 ea 0c             	sub    $0xc,%edx
f01039c8:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01039cc:	39 c7                	cmp    %eax,%edi
f01039ce:	7e 05                	jle    f01039d5 <debuginfo_eip+0x199>
f01039d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039d3:	eb 47                	jmp    f0103a1c <debuginfo_eip+0x1e0>
	       && stabs[lline].n_type != N_SOL
f01039d5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01039d9:	80 f9 84             	cmp    $0x84,%cl
f01039dc:	75 0e                	jne    f01039ec <debuginfo_eip+0x1b0>
f01039de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039e1:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01039e5:	74 1c                	je     f0103a03 <debuginfo_eip+0x1c7>
f01039e7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01039ea:	eb 17                	jmp    f0103a03 <debuginfo_eip+0x1c7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01039ec:	80 f9 64             	cmp    $0x64,%cl
f01039ef:	75 d1                	jne    f01039c2 <debuginfo_eip+0x186>
f01039f1:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01039f5:	74 cb                	je     f01039c2 <debuginfo_eip+0x186>
f01039f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039fa:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01039fe:	74 03                	je     f0103a03 <debuginfo_eip+0x1c7>
f0103a00:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103a03:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a06:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a09:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103a0c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103a0f:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103a12:	29 f8                	sub    %edi,%eax
f0103a14:	39 c2                	cmp    %eax,%edx
f0103a16:	73 04                	jae    f0103a1c <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103a18:	01 fa                	add    %edi,%edx
f0103a1a:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a1c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a1f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a22:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103a27:	39 f2                	cmp    %esi,%edx
f0103a29:	7d 52                	jge    f0103a7d <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f0103a2b:	83 c2 01             	add    $0x1,%edx
f0103a2e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103a31:	89 d0                	mov    %edx,%eax
f0103a33:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103a36:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103a39:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a3c:	eb 04                	jmp    f0103a42 <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103a3e:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103a42:	39 c6                	cmp    %eax,%esi
f0103a44:	7e 32                	jle    f0103a78 <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103a46:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a4a:	83 c0 01             	add    $0x1,%eax
f0103a4d:	83 c2 0c             	add    $0xc,%edx
f0103a50:	80 f9 a0             	cmp    $0xa0,%cl
f0103a53:	74 e9                	je     f0103a3e <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a55:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a5a:	eb 21                	jmp    f0103a7d <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103a5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a61:	eb 1a                	jmp    f0103a7d <debuginfo_eip+0x241>
f0103a63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a68:	eb 13                	jmp    f0103a7d <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103a6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a6f:	eb 0c                	jmp    f0103a7d <debuginfo_eip+0x241>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline > rline)
	return -1;
f0103a71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a76:	eb 05                	jmp    f0103a7d <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103a78:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a80:	5b                   	pop    %ebx
f0103a81:	5e                   	pop    %esi
f0103a82:	5f                   	pop    %edi
f0103a83:	5d                   	pop    %ebp
f0103a84:	c3                   	ret    

f0103a85 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103a85:	55                   	push   %ebp
f0103a86:	89 e5                	mov    %esp,%ebp
f0103a88:	57                   	push   %edi
f0103a89:	56                   	push   %esi
f0103a8a:	53                   	push   %ebx
f0103a8b:	83 ec 1c             	sub    $0x1c,%esp
f0103a8e:	89 c7                	mov    %eax,%edi
f0103a90:	89 d6                	mov    %edx,%esi
f0103a92:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a95:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a98:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a9b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103a9e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103aa1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103aa6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103aa9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103aac:	39 d3                	cmp    %edx,%ebx
f0103aae:	72 05                	jb     f0103ab5 <printnum+0x30>
f0103ab0:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103ab3:	77 45                	ja     f0103afa <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103ab5:	83 ec 0c             	sub    $0xc,%esp
f0103ab8:	ff 75 18             	pushl  0x18(%ebp)
f0103abb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103abe:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103ac1:	53                   	push   %ebx
f0103ac2:	ff 75 10             	pushl  0x10(%ebp)
f0103ac5:	83 ec 08             	sub    $0x8,%esp
f0103ac8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103acb:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ace:	ff 75 dc             	pushl  -0x24(%ebp)
f0103ad1:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ad4:	e8 47 09 00 00       	call   f0104420 <__udivdi3>
f0103ad9:	83 c4 18             	add    $0x18,%esp
f0103adc:	52                   	push   %edx
f0103add:	50                   	push   %eax
f0103ade:	89 f2                	mov    %esi,%edx
f0103ae0:	89 f8                	mov    %edi,%eax
f0103ae2:	e8 9e ff ff ff       	call   f0103a85 <printnum>
f0103ae7:	83 c4 20             	add    $0x20,%esp
f0103aea:	eb 18                	jmp    f0103b04 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103aec:	83 ec 08             	sub    $0x8,%esp
f0103aef:	56                   	push   %esi
f0103af0:	ff 75 18             	pushl  0x18(%ebp)
f0103af3:	ff d7                	call   *%edi
f0103af5:	83 c4 10             	add    $0x10,%esp
f0103af8:	eb 03                	jmp    f0103afd <printnum+0x78>
f0103afa:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103afd:	83 eb 01             	sub    $0x1,%ebx
f0103b00:	85 db                	test   %ebx,%ebx
f0103b02:	7f e8                	jg     f0103aec <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b04:	83 ec 08             	sub    $0x8,%esp
f0103b07:	56                   	push   %esi
f0103b08:	83 ec 04             	sub    $0x4,%esp
f0103b0b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b0e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b11:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b14:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b17:	e8 34 0a 00 00       	call   f0104550 <__umoddi3>
f0103b1c:	83 c4 14             	add    $0x14,%esp
f0103b1f:	0f be 80 72 5b 10 f0 	movsbl -0xfefa48e(%eax),%eax
f0103b26:	50                   	push   %eax
f0103b27:	ff d7                	call   *%edi
}
f0103b29:	83 c4 10             	add    $0x10,%esp
f0103b2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b2f:	5b                   	pop    %ebx
f0103b30:	5e                   	pop    %esi
f0103b31:	5f                   	pop    %edi
f0103b32:	5d                   	pop    %ebp
f0103b33:	c3                   	ret    

f0103b34 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103b34:	55                   	push   %ebp
f0103b35:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103b37:	83 fa 01             	cmp    $0x1,%edx
f0103b3a:	7e 0e                	jle    f0103b4a <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103b3c:	8b 10                	mov    (%eax),%edx
f0103b3e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103b41:	89 08                	mov    %ecx,(%eax)
f0103b43:	8b 02                	mov    (%edx),%eax
f0103b45:	8b 52 04             	mov    0x4(%edx),%edx
f0103b48:	eb 22                	jmp    f0103b6c <getuint+0x38>
	else if (lflag)
f0103b4a:	85 d2                	test   %edx,%edx
f0103b4c:	74 10                	je     f0103b5e <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103b4e:	8b 10                	mov    (%eax),%edx
f0103b50:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103b53:	89 08                	mov    %ecx,(%eax)
f0103b55:	8b 02                	mov    (%edx),%eax
f0103b57:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b5c:	eb 0e                	jmp    f0103b6c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103b5e:	8b 10                	mov    (%eax),%edx
f0103b60:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103b63:	89 08                	mov    %ecx,(%eax)
f0103b65:	8b 02                	mov    (%edx),%eax
f0103b67:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103b6c:	5d                   	pop    %ebp
f0103b6d:	c3                   	ret    

f0103b6e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103b6e:	55                   	push   %ebp
f0103b6f:	89 e5                	mov    %esp,%ebp
f0103b71:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103b74:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103b78:	8b 10                	mov    (%eax),%edx
f0103b7a:	3b 50 04             	cmp    0x4(%eax),%edx
f0103b7d:	73 0a                	jae    f0103b89 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103b7f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103b82:	89 08                	mov    %ecx,(%eax)
f0103b84:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b87:	88 02                	mov    %al,(%edx)
}
f0103b89:	5d                   	pop    %ebp
f0103b8a:	c3                   	ret    

f0103b8b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103b8b:	55                   	push   %ebp
f0103b8c:	89 e5                	mov    %esp,%ebp
f0103b8e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103b91:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103b94:	50                   	push   %eax
f0103b95:	ff 75 10             	pushl  0x10(%ebp)
f0103b98:	ff 75 0c             	pushl  0xc(%ebp)
f0103b9b:	ff 75 08             	pushl  0x8(%ebp)
f0103b9e:	e8 05 00 00 00       	call   f0103ba8 <vprintfmt>
	va_end(ap);
}
f0103ba3:	83 c4 10             	add    $0x10,%esp
f0103ba6:	c9                   	leave  
f0103ba7:	c3                   	ret    

f0103ba8 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103ba8:	55                   	push   %ebp
f0103ba9:	89 e5                	mov    %esp,%ebp
f0103bab:	57                   	push   %edi
f0103bac:	56                   	push   %esi
f0103bad:	53                   	push   %ebx
f0103bae:	83 ec 2c             	sub    $0x2c,%esp
f0103bb1:	8b 75 08             	mov    0x8(%ebp),%esi
f0103bb4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103bb7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103bba:	eb 12                	jmp    f0103bce <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103bbc:	85 c0                	test   %eax,%eax
f0103bbe:	0f 84 89 03 00 00    	je     f0103f4d <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103bc4:	83 ec 08             	sub    $0x8,%esp
f0103bc7:	53                   	push   %ebx
f0103bc8:	50                   	push   %eax
f0103bc9:	ff d6                	call   *%esi
f0103bcb:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103bce:	83 c7 01             	add    $0x1,%edi
f0103bd1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103bd5:	83 f8 25             	cmp    $0x25,%eax
f0103bd8:	75 e2                	jne    f0103bbc <vprintfmt+0x14>
f0103bda:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103bde:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103be5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103bec:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103bf3:	ba 00 00 00 00       	mov    $0x0,%edx
f0103bf8:	eb 07                	jmp    f0103c01 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103bfd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c01:	8d 47 01             	lea    0x1(%edi),%eax
f0103c04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c07:	0f b6 07             	movzbl (%edi),%eax
f0103c0a:	0f b6 c8             	movzbl %al,%ecx
f0103c0d:	83 e8 23             	sub    $0x23,%eax
f0103c10:	3c 55                	cmp    $0x55,%al
f0103c12:	0f 87 1a 03 00 00    	ja     f0103f32 <vprintfmt+0x38a>
f0103c18:	0f b6 c0             	movzbl %al,%eax
f0103c1b:	ff 24 85 fc 5b 10 f0 	jmp    *-0xfefa404(,%eax,4)
f0103c22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103c25:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103c29:	eb d6                	jmp    f0103c01 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c33:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103c36:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103c39:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103c3d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103c40:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103c43:	83 fa 09             	cmp    $0x9,%edx
f0103c46:	77 39                	ja     f0103c81 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103c48:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103c4b:	eb e9                	jmp    f0103c36 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103c4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c50:	8d 48 04             	lea    0x4(%eax),%ecx
f0103c53:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103c56:	8b 00                	mov    (%eax),%eax
f0103c58:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103c5e:	eb 27                	jmp    f0103c87 <vprintfmt+0xdf>
f0103c60:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c63:	85 c0                	test   %eax,%eax
f0103c65:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103c6a:	0f 49 c8             	cmovns %eax,%ecx
f0103c6d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c73:	eb 8c                	jmp    f0103c01 <vprintfmt+0x59>
f0103c75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103c78:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103c7f:	eb 80                	jmp    f0103c01 <vprintfmt+0x59>
f0103c81:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103c84:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103c87:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103c8b:	0f 89 70 ff ff ff    	jns    f0103c01 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103c91:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103c94:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103c97:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c9e:	e9 5e ff ff ff       	jmp    f0103c01 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103ca3:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ca6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103ca9:	e9 53 ff ff ff       	jmp    f0103c01 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103cae:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cb1:	8d 50 04             	lea    0x4(%eax),%edx
f0103cb4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cb7:	83 ec 08             	sub    $0x8,%esp
f0103cba:	53                   	push   %ebx
f0103cbb:	ff 30                	pushl  (%eax)
f0103cbd:	ff d6                	call   *%esi
			break;
f0103cbf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103cc5:	e9 04 ff ff ff       	jmp    f0103bce <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103cca:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ccd:	8d 50 04             	lea    0x4(%eax),%edx
f0103cd0:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cd3:	8b 00                	mov    (%eax),%eax
f0103cd5:	99                   	cltd   
f0103cd6:	31 d0                	xor    %edx,%eax
f0103cd8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103cda:	83 f8 06             	cmp    $0x6,%eax
f0103cdd:	7f 0b                	jg     f0103cea <vprintfmt+0x142>
f0103cdf:	8b 14 85 54 5d 10 f0 	mov    -0xfefa2ac(,%eax,4),%edx
f0103ce6:	85 d2                	test   %edx,%edx
f0103ce8:	75 18                	jne    f0103d02 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103cea:	50                   	push   %eax
f0103ceb:	68 8a 5b 10 f0       	push   $0xf0105b8a
f0103cf0:	53                   	push   %ebx
f0103cf1:	56                   	push   %esi
f0103cf2:	e8 94 fe ff ff       	call   f0103b8b <printfmt>
f0103cf7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103cfd:	e9 cc fe ff ff       	jmp    f0103bce <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103d02:	52                   	push   %edx
f0103d03:	68 df 53 10 f0       	push   $0xf01053df
f0103d08:	53                   	push   %ebx
f0103d09:	56                   	push   %esi
f0103d0a:	e8 7c fe ff ff       	call   f0103b8b <printfmt>
f0103d0f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d15:	e9 b4 fe ff ff       	jmp    f0103bce <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d1d:	8d 50 04             	lea    0x4(%eax),%edx
f0103d20:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d23:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103d25:	85 ff                	test   %edi,%edi
f0103d27:	b8 83 5b 10 f0       	mov    $0xf0105b83,%eax
f0103d2c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103d2f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d33:	0f 8e 94 00 00 00    	jle    f0103dcd <vprintfmt+0x225>
f0103d39:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103d3d:	0f 84 98 00 00 00    	je     f0103ddb <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d43:	83 ec 08             	sub    $0x8,%esp
f0103d46:	ff 75 d0             	pushl  -0x30(%ebp)
f0103d49:	57                   	push   %edi
f0103d4a:	e8 5f 03 00 00       	call   f01040ae <strnlen>
f0103d4f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103d52:	29 c1                	sub    %eax,%ecx
f0103d54:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103d57:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103d5a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103d5e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d61:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103d64:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d66:	eb 0f                	jmp    f0103d77 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103d68:	83 ec 08             	sub    $0x8,%esp
f0103d6b:	53                   	push   %ebx
f0103d6c:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d6f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103d71:	83 ef 01             	sub    $0x1,%edi
f0103d74:	83 c4 10             	add    $0x10,%esp
f0103d77:	85 ff                	test   %edi,%edi
f0103d79:	7f ed                	jg     f0103d68 <vprintfmt+0x1c0>
f0103d7b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103d7e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103d81:	85 c9                	test   %ecx,%ecx
f0103d83:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d88:	0f 49 c1             	cmovns %ecx,%eax
f0103d8b:	29 c1                	sub    %eax,%ecx
f0103d8d:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d90:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d93:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d96:	89 cb                	mov    %ecx,%ebx
f0103d98:	eb 4d                	jmp    f0103de7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103d9a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103d9e:	74 1b                	je     f0103dbb <vprintfmt+0x213>
f0103da0:	0f be c0             	movsbl %al,%eax
f0103da3:	83 e8 20             	sub    $0x20,%eax
f0103da6:	83 f8 5e             	cmp    $0x5e,%eax
f0103da9:	76 10                	jbe    f0103dbb <vprintfmt+0x213>
					putch('?', putdat);
f0103dab:	83 ec 08             	sub    $0x8,%esp
f0103dae:	ff 75 0c             	pushl  0xc(%ebp)
f0103db1:	6a 3f                	push   $0x3f
f0103db3:	ff 55 08             	call   *0x8(%ebp)
f0103db6:	83 c4 10             	add    $0x10,%esp
f0103db9:	eb 0d                	jmp    f0103dc8 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103dbb:	83 ec 08             	sub    $0x8,%esp
f0103dbe:	ff 75 0c             	pushl  0xc(%ebp)
f0103dc1:	52                   	push   %edx
f0103dc2:	ff 55 08             	call   *0x8(%ebp)
f0103dc5:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103dc8:	83 eb 01             	sub    $0x1,%ebx
f0103dcb:	eb 1a                	jmp    f0103de7 <vprintfmt+0x23f>
f0103dcd:	89 75 08             	mov    %esi,0x8(%ebp)
f0103dd0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103dd3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103dd6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103dd9:	eb 0c                	jmp    f0103de7 <vprintfmt+0x23f>
f0103ddb:	89 75 08             	mov    %esi,0x8(%ebp)
f0103dde:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103de1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103de4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103de7:	83 c7 01             	add    $0x1,%edi
f0103dea:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103dee:	0f be d0             	movsbl %al,%edx
f0103df1:	85 d2                	test   %edx,%edx
f0103df3:	74 23                	je     f0103e18 <vprintfmt+0x270>
f0103df5:	85 f6                	test   %esi,%esi
f0103df7:	78 a1                	js     f0103d9a <vprintfmt+0x1f2>
f0103df9:	83 ee 01             	sub    $0x1,%esi
f0103dfc:	79 9c                	jns    f0103d9a <vprintfmt+0x1f2>
f0103dfe:	89 df                	mov    %ebx,%edi
f0103e00:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e03:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e06:	eb 18                	jmp    f0103e20 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103e08:	83 ec 08             	sub    $0x8,%esp
f0103e0b:	53                   	push   %ebx
f0103e0c:	6a 20                	push   $0x20
f0103e0e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103e10:	83 ef 01             	sub    $0x1,%edi
f0103e13:	83 c4 10             	add    $0x10,%esp
f0103e16:	eb 08                	jmp    f0103e20 <vprintfmt+0x278>
f0103e18:	89 df                	mov    %ebx,%edi
f0103e1a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e1d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e20:	85 ff                	test   %edi,%edi
f0103e22:	7f e4                	jg     f0103e08 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e24:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e27:	e9 a2 fd ff ff       	jmp    f0103bce <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e2c:	83 fa 01             	cmp    $0x1,%edx
f0103e2f:	7e 16                	jle    f0103e47 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103e31:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e34:	8d 50 08             	lea    0x8(%eax),%edx
f0103e37:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e3a:	8b 50 04             	mov    0x4(%eax),%edx
f0103e3d:	8b 00                	mov    (%eax),%eax
f0103e3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e42:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103e45:	eb 32                	jmp    f0103e79 <vprintfmt+0x2d1>
	else if (lflag)
f0103e47:	85 d2                	test   %edx,%edx
f0103e49:	74 18                	je     f0103e63 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103e4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e4e:	8d 50 04             	lea    0x4(%eax),%edx
f0103e51:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e54:	8b 00                	mov    (%eax),%eax
f0103e56:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e59:	89 c1                	mov    %eax,%ecx
f0103e5b:	c1 f9 1f             	sar    $0x1f,%ecx
f0103e5e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103e61:	eb 16                	jmp    f0103e79 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103e63:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e66:	8d 50 04             	lea    0x4(%eax),%edx
f0103e69:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e6c:	8b 00                	mov    (%eax),%eax
f0103e6e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103e71:	89 c1                	mov    %eax,%ecx
f0103e73:	c1 f9 1f             	sar    $0x1f,%ecx
f0103e76:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103e79:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103e7c:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103e7f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103e84:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103e88:	79 74                	jns    f0103efe <vprintfmt+0x356>
				putch('-', putdat);
f0103e8a:	83 ec 08             	sub    $0x8,%esp
f0103e8d:	53                   	push   %ebx
f0103e8e:	6a 2d                	push   $0x2d
f0103e90:	ff d6                	call   *%esi
				num = -(long long) num;
f0103e92:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103e95:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103e98:	f7 d8                	neg    %eax
f0103e9a:	83 d2 00             	adc    $0x0,%edx
f0103e9d:	f7 da                	neg    %edx
f0103e9f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103ea2:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103ea7:	eb 55                	jmp    f0103efe <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103ea9:	8d 45 14             	lea    0x14(%ebp),%eax
f0103eac:	e8 83 fc ff ff       	call   f0103b34 <getuint>
			base = 10;
f0103eb1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103eb6:	eb 46                	jmp    f0103efe <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
		        num = getuint(&ap, lflag);
f0103eb8:	8d 45 14             	lea    0x14(%ebp),%eax
f0103ebb:	e8 74 fc ff ff       	call   f0103b34 <getuint>
			base=8;
f0103ec0:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103ec5:	eb 37                	jmp    f0103efe <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103ec7:	83 ec 08             	sub    $0x8,%esp
f0103eca:	53                   	push   %ebx
f0103ecb:	6a 30                	push   $0x30
f0103ecd:	ff d6                	call   *%esi
			putch('x', putdat);
f0103ecf:	83 c4 08             	add    $0x8,%esp
f0103ed2:	53                   	push   %ebx
f0103ed3:	6a 78                	push   $0x78
f0103ed5:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103ed7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eda:	8d 50 04             	lea    0x4(%eax),%edx
f0103edd:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103ee0:	8b 00                	mov    (%eax),%eax
f0103ee2:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103ee7:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103eea:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103eef:	eb 0d                	jmp    f0103efe <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103ef1:	8d 45 14             	lea    0x14(%ebp),%eax
f0103ef4:	e8 3b fc ff ff       	call   f0103b34 <getuint>
			base = 16;
f0103ef9:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103efe:	83 ec 0c             	sub    $0xc,%esp
f0103f01:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103f05:	57                   	push   %edi
f0103f06:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f09:	51                   	push   %ecx
f0103f0a:	52                   	push   %edx
f0103f0b:	50                   	push   %eax
f0103f0c:	89 da                	mov    %ebx,%edx
f0103f0e:	89 f0                	mov    %esi,%eax
f0103f10:	e8 70 fb ff ff       	call   f0103a85 <printnum>
			break;
f0103f15:	83 c4 20             	add    $0x20,%esp
f0103f18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f1b:	e9 ae fc ff ff       	jmp    f0103bce <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103f20:	83 ec 08             	sub    $0x8,%esp
f0103f23:	53                   	push   %ebx
f0103f24:	51                   	push   %ecx
f0103f25:	ff d6                	call   *%esi
			break;
f0103f27:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103f2d:	e9 9c fc ff ff       	jmp    f0103bce <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103f32:	83 ec 08             	sub    $0x8,%esp
f0103f35:	53                   	push   %ebx
f0103f36:	6a 25                	push   $0x25
f0103f38:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f3a:	83 c4 10             	add    $0x10,%esp
f0103f3d:	eb 03                	jmp    f0103f42 <vprintfmt+0x39a>
f0103f3f:	83 ef 01             	sub    $0x1,%edi
f0103f42:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103f46:	75 f7                	jne    f0103f3f <vprintfmt+0x397>
f0103f48:	e9 81 fc ff ff       	jmp    f0103bce <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103f4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f50:	5b                   	pop    %ebx
f0103f51:	5e                   	pop    %esi
f0103f52:	5f                   	pop    %edi
f0103f53:	5d                   	pop    %ebp
f0103f54:	c3                   	ret    

f0103f55 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103f55:	55                   	push   %ebp
f0103f56:	89 e5                	mov    %esp,%ebp
f0103f58:	83 ec 18             	sub    $0x18,%esp
f0103f5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f5e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103f61:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103f64:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103f68:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103f6b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103f72:	85 c0                	test   %eax,%eax
f0103f74:	74 26                	je     f0103f9c <vsnprintf+0x47>
f0103f76:	85 d2                	test   %edx,%edx
f0103f78:	7e 22                	jle    f0103f9c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103f7a:	ff 75 14             	pushl  0x14(%ebp)
f0103f7d:	ff 75 10             	pushl  0x10(%ebp)
f0103f80:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103f83:	50                   	push   %eax
f0103f84:	68 6e 3b 10 f0       	push   $0xf0103b6e
f0103f89:	e8 1a fc ff ff       	call   f0103ba8 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103f8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103f91:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103f94:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f97:	83 c4 10             	add    $0x10,%esp
f0103f9a:	eb 05                	jmp    f0103fa1 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103f9c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103fa1:	c9                   	leave  
f0103fa2:	c3                   	ret    

f0103fa3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103fa3:	55                   	push   %ebp
f0103fa4:	89 e5                	mov    %esp,%ebp
f0103fa6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103fa9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103fac:	50                   	push   %eax
f0103fad:	ff 75 10             	pushl  0x10(%ebp)
f0103fb0:	ff 75 0c             	pushl  0xc(%ebp)
f0103fb3:	ff 75 08             	pushl  0x8(%ebp)
f0103fb6:	e8 9a ff ff ff       	call   f0103f55 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103fbb:	c9                   	leave  
f0103fbc:	c3                   	ret    

f0103fbd <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103fbd:	55                   	push   %ebp
f0103fbe:	89 e5                	mov    %esp,%ebp
f0103fc0:	57                   	push   %edi
f0103fc1:	56                   	push   %esi
f0103fc2:	53                   	push   %ebx
f0103fc3:	83 ec 0c             	sub    $0xc,%esp
f0103fc6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103fc9:	85 c0                	test   %eax,%eax
f0103fcb:	74 11                	je     f0103fde <readline+0x21>
		cprintf("%s", prompt);
f0103fcd:	83 ec 08             	sub    $0x8,%esp
f0103fd0:	50                   	push   %eax
f0103fd1:	68 df 53 10 f0       	push   $0xf01053df
f0103fd6:	e8 11 ef ff ff       	call   f0102eec <cprintf>
f0103fdb:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103fde:	83 ec 0c             	sub    $0xc,%esp
f0103fe1:	6a 00                	push   $0x0
f0103fe3:	e8 4e c6 ff ff       	call   f0100636 <iscons>
f0103fe8:	89 c7                	mov    %eax,%edi
f0103fea:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103fed:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ff2:	e8 2e c6 ff ff       	call   f0100625 <getchar>
f0103ff7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103ff9:	85 c0                	test   %eax,%eax
f0103ffb:	79 18                	jns    f0104015 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103ffd:	83 ec 08             	sub    $0x8,%esp
f0104000:	50                   	push   %eax
f0104001:	68 70 5d 10 f0       	push   $0xf0105d70
f0104006:	e8 e1 ee ff ff       	call   f0102eec <cprintf>
			return NULL;
f010400b:	83 c4 10             	add    $0x10,%esp
f010400e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104013:	eb 79                	jmp    f010408e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104015:	83 f8 08             	cmp    $0x8,%eax
f0104018:	0f 94 c2             	sete   %dl
f010401b:	83 f8 7f             	cmp    $0x7f,%eax
f010401e:	0f 94 c0             	sete   %al
f0104021:	08 c2                	or     %al,%dl
f0104023:	74 1a                	je     f010403f <readline+0x82>
f0104025:	85 f6                	test   %esi,%esi
f0104027:	7e 16                	jle    f010403f <readline+0x82>
			if (echoing)
f0104029:	85 ff                	test   %edi,%edi
f010402b:	74 0d                	je     f010403a <readline+0x7d>
				cputchar('\b');
f010402d:	83 ec 0c             	sub    $0xc,%esp
f0104030:	6a 08                	push   $0x8
f0104032:	e8 de c5 ff ff       	call   f0100615 <cputchar>
f0104037:	83 c4 10             	add    $0x10,%esp
			i--;
f010403a:	83 ee 01             	sub    $0x1,%esi
f010403d:	eb b3                	jmp    f0103ff2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010403f:	83 fb 1f             	cmp    $0x1f,%ebx
f0104042:	7e 23                	jle    f0104067 <readline+0xaa>
f0104044:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010404a:	7f 1b                	jg     f0104067 <readline+0xaa>
			if (echoing)
f010404c:	85 ff                	test   %edi,%edi
f010404e:	74 0c                	je     f010405c <readline+0x9f>
				cputchar(c);
f0104050:	83 ec 0c             	sub    $0xc,%esp
f0104053:	53                   	push   %ebx
f0104054:	e8 bc c5 ff ff       	call   f0100615 <cputchar>
f0104059:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010405c:	88 9e 40 08 17 f0    	mov    %bl,-0xfe8f7c0(%esi)
f0104062:	8d 76 01             	lea    0x1(%esi),%esi
f0104065:	eb 8b                	jmp    f0103ff2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104067:	83 fb 0a             	cmp    $0xa,%ebx
f010406a:	74 05                	je     f0104071 <readline+0xb4>
f010406c:	83 fb 0d             	cmp    $0xd,%ebx
f010406f:	75 81                	jne    f0103ff2 <readline+0x35>
			if (echoing)
f0104071:	85 ff                	test   %edi,%edi
f0104073:	74 0d                	je     f0104082 <readline+0xc5>
				cputchar('\n');
f0104075:	83 ec 0c             	sub    $0xc,%esp
f0104078:	6a 0a                	push   $0xa
f010407a:	e8 96 c5 ff ff       	call   f0100615 <cputchar>
f010407f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104082:	c6 86 40 08 17 f0 00 	movb   $0x0,-0xfe8f7c0(%esi)
			return buf;
f0104089:	b8 40 08 17 f0       	mov    $0xf0170840,%eax
		}
	}
}
f010408e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104091:	5b                   	pop    %ebx
f0104092:	5e                   	pop    %esi
f0104093:	5f                   	pop    %edi
f0104094:	5d                   	pop    %ebp
f0104095:	c3                   	ret    

f0104096 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104096:	55                   	push   %ebp
f0104097:	89 e5                	mov    %esp,%ebp
f0104099:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010409c:	b8 00 00 00 00       	mov    $0x0,%eax
f01040a1:	eb 03                	jmp    f01040a6 <strlen+0x10>
		n++;
f01040a3:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01040a6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01040aa:	75 f7                	jne    f01040a3 <strlen+0xd>
		n++;
	return n;
}
f01040ac:	5d                   	pop    %ebp
f01040ad:	c3                   	ret    

f01040ae <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01040ae:	55                   	push   %ebp
f01040af:	89 e5                	mov    %esp,%ebp
f01040b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040b4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040b7:	ba 00 00 00 00       	mov    $0x0,%edx
f01040bc:	eb 03                	jmp    f01040c1 <strnlen+0x13>
		n++;
f01040be:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040c1:	39 c2                	cmp    %eax,%edx
f01040c3:	74 08                	je     f01040cd <strnlen+0x1f>
f01040c5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01040c9:	75 f3                	jne    f01040be <strnlen+0x10>
f01040cb:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01040cd:	5d                   	pop    %ebp
f01040ce:	c3                   	ret    

f01040cf <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01040cf:	55                   	push   %ebp
f01040d0:	89 e5                	mov    %esp,%ebp
f01040d2:	53                   	push   %ebx
f01040d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01040d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01040d9:	89 c2                	mov    %eax,%edx
f01040db:	83 c2 01             	add    $0x1,%edx
f01040de:	83 c1 01             	add    $0x1,%ecx
f01040e1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01040e5:	88 5a ff             	mov    %bl,-0x1(%edx)
f01040e8:	84 db                	test   %bl,%bl
f01040ea:	75 ef                	jne    f01040db <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01040ec:	5b                   	pop    %ebx
f01040ed:	5d                   	pop    %ebp
f01040ee:	c3                   	ret    

f01040ef <strcat>:

char *
strcat(char *dst, const char *src)
{
f01040ef:	55                   	push   %ebp
f01040f0:	89 e5                	mov    %esp,%ebp
f01040f2:	53                   	push   %ebx
f01040f3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01040f6:	53                   	push   %ebx
f01040f7:	e8 9a ff ff ff       	call   f0104096 <strlen>
f01040fc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01040ff:	ff 75 0c             	pushl  0xc(%ebp)
f0104102:	01 d8                	add    %ebx,%eax
f0104104:	50                   	push   %eax
f0104105:	e8 c5 ff ff ff       	call   f01040cf <strcpy>
	return dst;
}
f010410a:	89 d8                	mov    %ebx,%eax
f010410c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010410f:	c9                   	leave  
f0104110:	c3                   	ret    

f0104111 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104111:	55                   	push   %ebp
f0104112:	89 e5                	mov    %esp,%ebp
f0104114:	56                   	push   %esi
f0104115:	53                   	push   %ebx
f0104116:	8b 75 08             	mov    0x8(%ebp),%esi
f0104119:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010411c:	89 f3                	mov    %esi,%ebx
f010411e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104121:	89 f2                	mov    %esi,%edx
f0104123:	eb 0f                	jmp    f0104134 <strncpy+0x23>
		*dst++ = *src;
f0104125:	83 c2 01             	add    $0x1,%edx
f0104128:	0f b6 01             	movzbl (%ecx),%eax
f010412b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010412e:	80 39 01             	cmpb   $0x1,(%ecx)
f0104131:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104134:	39 da                	cmp    %ebx,%edx
f0104136:	75 ed                	jne    f0104125 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104138:	89 f0                	mov    %esi,%eax
f010413a:	5b                   	pop    %ebx
f010413b:	5e                   	pop    %esi
f010413c:	5d                   	pop    %ebp
f010413d:	c3                   	ret    

f010413e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010413e:	55                   	push   %ebp
f010413f:	89 e5                	mov    %esp,%ebp
f0104141:	56                   	push   %esi
f0104142:	53                   	push   %ebx
f0104143:	8b 75 08             	mov    0x8(%ebp),%esi
f0104146:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104149:	8b 55 10             	mov    0x10(%ebp),%edx
f010414c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010414e:	85 d2                	test   %edx,%edx
f0104150:	74 21                	je     f0104173 <strlcpy+0x35>
f0104152:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104156:	89 f2                	mov    %esi,%edx
f0104158:	eb 09                	jmp    f0104163 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010415a:	83 c2 01             	add    $0x1,%edx
f010415d:	83 c1 01             	add    $0x1,%ecx
f0104160:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104163:	39 c2                	cmp    %eax,%edx
f0104165:	74 09                	je     f0104170 <strlcpy+0x32>
f0104167:	0f b6 19             	movzbl (%ecx),%ebx
f010416a:	84 db                	test   %bl,%bl
f010416c:	75 ec                	jne    f010415a <strlcpy+0x1c>
f010416e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104170:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104173:	29 f0                	sub    %esi,%eax
}
f0104175:	5b                   	pop    %ebx
f0104176:	5e                   	pop    %esi
f0104177:	5d                   	pop    %ebp
f0104178:	c3                   	ret    

f0104179 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104179:	55                   	push   %ebp
f010417a:	89 e5                	mov    %esp,%ebp
f010417c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010417f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104182:	eb 06                	jmp    f010418a <strcmp+0x11>
		p++, q++;
f0104184:	83 c1 01             	add    $0x1,%ecx
f0104187:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010418a:	0f b6 01             	movzbl (%ecx),%eax
f010418d:	84 c0                	test   %al,%al
f010418f:	74 04                	je     f0104195 <strcmp+0x1c>
f0104191:	3a 02                	cmp    (%edx),%al
f0104193:	74 ef                	je     f0104184 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104195:	0f b6 c0             	movzbl %al,%eax
f0104198:	0f b6 12             	movzbl (%edx),%edx
f010419b:	29 d0                	sub    %edx,%eax
}
f010419d:	5d                   	pop    %ebp
f010419e:	c3                   	ret    

f010419f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010419f:	55                   	push   %ebp
f01041a0:	89 e5                	mov    %esp,%ebp
f01041a2:	53                   	push   %ebx
f01041a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01041a6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041a9:	89 c3                	mov    %eax,%ebx
f01041ab:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01041ae:	eb 06                	jmp    f01041b6 <strncmp+0x17>
		n--, p++, q++;
f01041b0:	83 c0 01             	add    $0x1,%eax
f01041b3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01041b6:	39 d8                	cmp    %ebx,%eax
f01041b8:	74 15                	je     f01041cf <strncmp+0x30>
f01041ba:	0f b6 08             	movzbl (%eax),%ecx
f01041bd:	84 c9                	test   %cl,%cl
f01041bf:	74 04                	je     f01041c5 <strncmp+0x26>
f01041c1:	3a 0a                	cmp    (%edx),%cl
f01041c3:	74 eb                	je     f01041b0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01041c5:	0f b6 00             	movzbl (%eax),%eax
f01041c8:	0f b6 12             	movzbl (%edx),%edx
f01041cb:	29 d0                	sub    %edx,%eax
f01041cd:	eb 05                	jmp    f01041d4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01041cf:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01041d4:	5b                   	pop    %ebx
f01041d5:	5d                   	pop    %ebp
f01041d6:	c3                   	ret    

f01041d7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01041d7:	55                   	push   %ebp
f01041d8:	89 e5                	mov    %esp,%ebp
f01041da:	8b 45 08             	mov    0x8(%ebp),%eax
f01041dd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01041e1:	eb 07                	jmp    f01041ea <strchr+0x13>
		if (*s == c)
f01041e3:	38 ca                	cmp    %cl,%dl
f01041e5:	74 0f                	je     f01041f6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01041e7:	83 c0 01             	add    $0x1,%eax
f01041ea:	0f b6 10             	movzbl (%eax),%edx
f01041ed:	84 d2                	test   %dl,%dl
f01041ef:	75 f2                	jne    f01041e3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01041f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01041f6:	5d                   	pop    %ebp
f01041f7:	c3                   	ret    

f01041f8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01041f8:	55                   	push   %ebp
f01041f9:	89 e5                	mov    %esp,%ebp
f01041fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01041fe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104202:	eb 03                	jmp    f0104207 <strfind+0xf>
f0104204:	83 c0 01             	add    $0x1,%eax
f0104207:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010420a:	38 ca                	cmp    %cl,%dl
f010420c:	74 04                	je     f0104212 <strfind+0x1a>
f010420e:	84 d2                	test   %dl,%dl
f0104210:	75 f2                	jne    f0104204 <strfind+0xc>
			break;
	return (char *) s;
}
f0104212:	5d                   	pop    %ebp
f0104213:	c3                   	ret    

f0104214 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104214:	55                   	push   %ebp
f0104215:	89 e5                	mov    %esp,%ebp
f0104217:	57                   	push   %edi
f0104218:	56                   	push   %esi
f0104219:	53                   	push   %ebx
f010421a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010421d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104220:	85 c9                	test   %ecx,%ecx
f0104222:	74 36                	je     f010425a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104224:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010422a:	75 28                	jne    f0104254 <memset+0x40>
f010422c:	f6 c1 03             	test   $0x3,%cl
f010422f:	75 23                	jne    f0104254 <memset+0x40>
		c &= 0xFF;
f0104231:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104235:	89 d3                	mov    %edx,%ebx
f0104237:	c1 e3 08             	shl    $0x8,%ebx
f010423a:	89 d6                	mov    %edx,%esi
f010423c:	c1 e6 18             	shl    $0x18,%esi
f010423f:	89 d0                	mov    %edx,%eax
f0104241:	c1 e0 10             	shl    $0x10,%eax
f0104244:	09 f0                	or     %esi,%eax
f0104246:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104248:	89 d8                	mov    %ebx,%eax
f010424a:	09 d0                	or     %edx,%eax
f010424c:	c1 e9 02             	shr    $0x2,%ecx
f010424f:	fc                   	cld    
f0104250:	f3 ab                	rep stos %eax,%es:(%edi)
f0104252:	eb 06                	jmp    f010425a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104254:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104257:	fc                   	cld    
f0104258:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010425a:	89 f8                	mov    %edi,%eax
f010425c:	5b                   	pop    %ebx
f010425d:	5e                   	pop    %esi
f010425e:	5f                   	pop    %edi
f010425f:	5d                   	pop    %ebp
f0104260:	c3                   	ret    

f0104261 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104261:	55                   	push   %ebp
f0104262:	89 e5                	mov    %esp,%ebp
f0104264:	57                   	push   %edi
f0104265:	56                   	push   %esi
f0104266:	8b 45 08             	mov    0x8(%ebp),%eax
f0104269:	8b 75 0c             	mov    0xc(%ebp),%esi
f010426c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010426f:	39 c6                	cmp    %eax,%esi
f0104271:	73 35                	jae    f01042a8 <memmove+0x47>
f0104273:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104276:	39 d0                	cmp    %edx,%eax
f0104278:	73 2e                	jae    f01042a8 <memmove+0x47>
		s += n;
		d += n;
f010427a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010427d:	89 d6                	mov    %edx,%esi
f010427f:	09 fe                	or     %edi,%esi
f0104281:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104287:	75 13                	jne    f010429c <memmove+0x3b>
f0104289:	f6 c1 03             	test   $0x3,%cl
f010428c:	75 0e                	jne    f010429c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010428e:	83 ef 04             	sub    $0x4,%edi
f0104291:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104294:	c1 e9 02             	shr    $0x2,%ecx
f0104297:	fd                   	std    
f0104298:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010429a:	eb 09                	jmp    f01042a5 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010429c:	83 ef 01             	sub    $0x1,%edi
f010429f:	8d 72 ff             	lea    -0x1(%edx),%esi
f01042a2:	fd                   	std    
f01042a3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01042a5:	fc                   	cld    
f01042a6:	eb 1d                	jmp    f01042c5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01042a8:	89 f2                	mov    %esi,%edx
f01042aa:	09 c2                	or     %eax,%edx
f01042ac:	f6 c2 03             	test   $0x3,%dl
f01042af:	75 0f                	jne    f01042c0 <memmove+0x5f>
f01042b1:	f6 c1 03             	test   $0x3,%cl
f01042b4:	75 0a                	jne    f01042c0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01042b6:	c1 e9 02             	shr    $0x2,%ecx
f01042b9:	89 c7                	mov    %eax,%edi
f01042bb:	fc                   	cld    
f01042bc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042be:	eb 05                	jmp    f01042c5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01042c0:	89 c7                	mov    %eax,%edi
f01042c2:	fc                   	cld    
f01042c3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01042c5:	5e                   	pop    %esi
f01042c6:	5f                   	pop    %edi
f01042c7:	5d                   	pop    %ebp
f01042c8:	c3                   	ret    

f01042c9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01042c9:	55                   	push   %ebp
f01042ca:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01042cc:	ff 75 10             	pushl  0x10(%ebp)
f01042cf:	ff 75 0c             	pushl  0xc(%ebp)
f01042d2:	ff 75 08             	pushl  0x8(%ebp)
f01042d5:	e8 87 ff ff ff       	call   f0104261 <memmove>
}
f01042da:	c9                   	leave  
f01042db:	c3                   	ret    

f01042dc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01042dc:	55                   	push   %ebp
f01042dd:	89 e5                	mov    %esp,%ebp
f01042df:	56                   	push   %esi
f01042e0:	53                   	push   %ebx
f01042e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01042e4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042e7:	89 c6                	mov    %eax,%esi
f01042e9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01042ec:	eb 1a                	jmp    f0104308 <memcmp+0x2c>
		if (*s1 != *s2)
f01042ee:	0f b6 08             	movzbl (%eax),%ecx
f01042f1:	0f b6 1a             	movzbl (%edx),%ebx
f01042f4:	38 d9                	cmp    %bl,%cl
f01042f6:	74 0a                	je     f0104302 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01042f8:	0f b6 c1             	movzbl %cl,%eax
f01042fb:	0f b6 db             	movzbl %bl,%ebx
f01042fe:	29 d8                	sub    %ebx,%eax
f0104300:	eb 0f                	jmp    f0104311 <memcmp+0x35>
		s1++, s2++;
f0104302:	83 c0 01             	add    $0x1,%eax
f0104305:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104308:	39 f0                	cmp    %esi,%eax
f010430a:	75 e2                	jne    f01042ee <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010430c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104311:	5b                   	pop    %ebx
f0104312:	5e                   	pop    %esi
f0104313:	5d                   	pop    %ebp
f0104314:	c3                   	ret    

f0104315 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104315:	55                   	push   %ebp
f0104316:	89 e5                	mov    %esp,%ebp
f0104318:	53                   	push   %ebx
f0104319:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010431c:	89 c1                	mov    %eax,%ecx
f010431e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104321:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104325:	eb 0a                	jmp    f0104331 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104327:	0f b6 10             	movzbl (%eax),%edx
f010432a:	39 da                	cmp    %ebx,%edx
f010432c:	74 07                	je     f0104335 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010432e:	83 c0 01             	add    $0x1,%eax
f0104331:	39 c8                	cmp    %ecx,%eax
f0104333:	72 f2                	jb     f0104327 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104335:	5b                   	pop    %ebx
f0104336:	5d                   	pop    %ebp
f0104337:	c3                   	ret    

f0104338 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104338:	55                   	push   %ebp
f0104339:	89 e5                	mov    %esp,%ebp
f010433b:	57                   	push   %edi
f010433c:	56                   	push   %esi
f010433d:	53                   	push   %ebx
f010433e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104341:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104344:	eb 03                	jmp    f0104349 <strtol+0x11>
		s++;
f0104346:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104349:	0f b6 01             	movzbl (%ecx),%eax
f010434c:	3c 20                	cmp    $0x20,%al
f010434e:	74 f6                	je     f0104346 <strtol+0xe>
f0104350:	3c 09                	cmp    $0x9,%al
f0104352:	74 f2                	je     f0104346 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104354:	3c 2b                	cmp    $0x2b,%al
f0104356:	75 0a                	jne    f0104362 <strtol+0x2a>
		s++;
f0104358:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010435b:	bf 00 00 00 00       	mov    $0x0,%edi
f0104360:	eb 11                	jmp    f0104373 <strtol+0x3b>
f0104362:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104367:	3c 2d                	cmp    $0x2d,%al
f0104369:	75 08                	jne    f0104373 <strtol+0x3b>
		s++, neg = 1;
f010436b:	83 c1 01             	add    $0x1,%ecx
f010436e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104373:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104379:	75 15                	jne    f0104390 <strtol+0x58>
f010437b:	80 39 30             	cmpb   $0x30,(%ecx)
f010437e:	75 10                	jne    f0104390 <strtol+0x58>
f0104380:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104384:	75 7c                	jne    f0104402 <strtol+0xca>
		s += 2, base = 16;
f0104386:	83 c1 02             	add    $0x2,%ecx
f0104389:	bb 10 00 00 00       	mov    $0x10,%ebx
f010438e:	eb 16                	jmp    f01043a6 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104390:	85 db                	test   %ebx,%ebx
f0104392:	75 12                	jne    f01043a6 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104394:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104399:	80 39 30             	cmpb   $0x30,(%ecx)
f010439c:	75 08                	jne    f01043a6 <strtol+0x6e>
		s++, base = 8;
f010439e:	83 c1 01             	add    $0x1,%ecx
f01043a1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01043a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01043ab:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01043ae:	0f b6 11             	movzbl (%ecx),%edx
f01043b1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01043b4:	89 f3                	mov    %esi,%ebx
f01043b6:	80 fb 09             	cmp    $0x9,%bl
f01043b9:	77 08                	ja     f01043c3 <strtol+0x8b>
			dig = *s - '0';
f01043bb:	0f be d2             	movsbl %dl,%edx
f01043be:	83 ea 30             	sub    $0x30,%edx
f01043c1:	eb 22                	jmp    f01043e5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01043c3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01043c6:	89 f3                	mov    %esi,%ebx
f01043c8:	80 fb 19             	cmp    $0x19,%bl
f01043cb:	77 08                	ja     f01043d5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01043cd:	0f be d2             	movsbl %dl,%edx
f01043d0:	83 ea 57             	sub    $0x57,%edx
f01043d3:	eb 10                	jmp    f01043e5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01043d5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01043d8:	89 f3                	mov    %esi,%ebx
f01043da:	80 fb 19             	cmp    $0x19,%bl
f01043dd:	77 16                	ja     f01043f5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01043df:	0f be d2             	movsbl %dl,%edx
f01043e2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01043e5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01043e8:	7d 0b                	jge    f01043f5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01043ea:	83 c1 01             	add    $0x1,%ecx
f01043ed:	0f af 45 10          	imul   0x10(%ebp),%eax
f01043f1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01043f3:	eb b9                	jmp    f01043ae <strtol+0x76>

	if (endptr)
f01043f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01043f9:	74 0d                	je     f0104408 <strtol+0xd0>
		*endptr = (char *) s;
f01043fb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043fe:	89 0e                	mov    %ecx,(%esi)
f0104400:	eb 06                	jmp    f0104408 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104402:	85 db                	test   %ebx,%ebx
f0104404:	74 98                	je     f010439e <strtol+0x66>
f0104406:	eb 9e                	jmp    f01043a6 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104408:	89 c2                	mov    %eax,%edx
f010440a:	f7 da                	neg    %edx
f010440c:	85 ff                	test   %edi,%edi
f010440e:	0f 45 c2             	cmovne %edx,%eax
}
f0104411:	5b                   	pop    %ebx
f0104412:	5e                   	pop    %esi
f0104413:	5f                   	pop    %edi
f0104414:	5d                   	pop    %ebp
f0104415:	c3                   	ret    
f0104416:	66 90                	xchg   %ax,%ax
f0104418:	66 90                	xchg   %ax,%ax
f010441a:	66 90                	xchg   %ax,%ax
f010441c:	66 90                	xchg   %ax,%ax
f010441e:	66 90                	xchg   %ax,%ax

f0104420 <__udivdi3>:
f0104420:	55                   	push   %ebp
f0104421:	57                   	push   %edi
f0104422:	56                   	push   %esi
f0104423:	53                   	push   %ebx
f0104424:	83 ec 1c             	sub    $0x1c,%esp
f0104427:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010442b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010442f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104433:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104437:	85 f6                	test   %esi,%esi
f0104439:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010443d:	89 ca                	mov    %ecx,%edx
f010443f:	89 f8                	mov    %edi,%eax
f0104441:	75 3d                	jne    f0104480 <__udivdi3+0x60>
f0104443:	39 cf                	cmp    %ecx,%edi
f0104445:	0f 87 c5 00 00 00    	ja     f0104510 <__udivdi3+0xf0>
f010444b:	85 ff                	test   %edi,%edi
f010444d:	89 fd                	mov    %edi,%ebp
f010444f:	75 0b                	jne    f010445c <__udivdi3+0x3c>
f0104451:	b8 01 00 00 00       	mov    $0x1,%eax
f0104456:	31 d2                	xor    %edx,%edx
f0104458:	f7 f7                	div    %edi
f010445a:	89 c5                	mov    %eax,%ebp
f010445c:	89 c8                	mov    %ecx,%eax
f010445e:	31 d2                	xor    %edx,%edx
f0104460:	f7 f5                	div    %ebp
f0104462:	89 c1                	mov    %eax,%ecx
f0104464:	89 d8                	mov    %ebx,%eax
f0104466:	89 cf                	mov    %ecx,%edi
f0104468:	f7 f5                	div    %ebp
f010446a:	89 c3                	mov    %eax,%ebx
f010446c:	89 d8                	mov    %ebx,%eax
f010446e:	89 fa                	mov    %edi,%edx
f0104470:	83 c4 1c             	add    $0x1c,%esp
f0104473:	5b                   	pop    %ebx
f0104474:	5e                   	pop    %esi
f0104475:	5f                   	pop    %edi
f0104476:	5d                   	pop    %ebp
f0104477:	c3                   	ret    
f0104478:	90                   	nop
f0104479:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104480:	39 ce                	cmp    %ecx,%esi
f0104482:	77 74                	ja     f01044f8 <__udivdi3+0xd8>
f0104484:	0f bd fe             	bsr    %esi,%edi
f0104487:	83 f7 1f             	xor    $0x1f,%edi
f010448a:	0f 84 98 00 00 00    	je     f0104528 <__udivdi3+0x108>
f0104490:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104495:	89 f9                	mov    %edi,%ecx
f0104497:	89 c5                	mov    %eax,%ebp
f0104499:	29 fb                	sub    %edi,%ebx
f010449b:	d3 e6                	shl    %cl,%esi
f010449d:	89 d9                	mov    %ebx,%ecx
f010449f:	d3 ed                	shr    %cl,%ebp
f01044a1:	89 f9                	mov    %edi,%ecx
f01044a3:	d3 e0                	shl    %cl,%eax
f01044a5:	09 ee                	or     %ebp,%esi
f01044a7:	89 d9                	mov    %ebx,%ecx
f01044a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01044ad:	89 d5                	mov    %edx,%ebp
f01044af:	8b 44 24 08          	mov    0x8(%esp),%eax
f01044b3:	d3 ed                	shr    %cl,%ebp
f01044b5:	89 f9                	mov    %edi,%ecx
f01044b7:	d3 e2                	shl    %cl,%edx
f01044b9:	89 d9                	mov    %ebx,%ecx
f01044bb:	d3 e8                	shr    %cl,%eax
f01044bd:	09 c2                	or     %eax,%edx
f01044bf:	89 d0                	mov    %edx,%eax
f01044c1:	89 ea                	mov    %ebp,%edx
f01044c3:	f7 f6                	div    %esi
f01044c5:	89 d5                	mov    %edx,%ebp
f01044c7:	89 c3                	mov    %eax,%ebx
f01044c9:	f7 64 24 0c          	mull   0xc(%esp)
f01044cd:	39 d5                	cmp    %edx,%ebp
f01044cf:	72 10                	jb     f01044e1 <__udivdi3+0xc1>
f01044d1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01044d5:	89 f9                	mov    %edi,%ecx
f01044d7:	d3 e6                	shl    %cl,%esi
f01044d9:	39 c6                	cmp    %eax,%esi
f01044db:	73 07                	jae    f01044e4 <__udivdi3+0xc4>
f01044dd:	39 d5                	cmp    %edx,%ebp
f01044df:	75 03                	jne    f01044e4 <__udivdi3+0xc4>
f01044e1:	83 eb 01             	sub    $0x1,%ebx
f01044e4:	31 ff                	xor    %edi,%edi
f01044e6:	89 d8                	mov    %ebx,%eax
f01044e8:	89 fa                	mov    %edi,%edx
f01044ea:	83 c4 1c             	add    $0x1c,%esp
f01044ed:	5b                   	pop    %ebx
f01044ee:	5e                   	pop    %esi
f01044ef:	5f                   	pop    %edi
f01044f0:	5d                   	pop    %ebp
f01044f1:	c3                   	ret    
f01044f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044f8:	31 ff                	xor    %edi,%edi
f01044fa:	31 db                	xor    %ebx,%ebx
f01044fc:	89 d8                	mov    %ebx,%eax
f01044fe:	89 fa                	mov    %edi,%edx
f0104500:	83 c4 1c             	add    $0x1c,%esp
f0104503:	5b                   	pop    %ebx
f0104504:	5e                   	pop    %esi
f0104505:	5f                   	pop    %edi
f0104506:	5d                   	pop    %ebp
f0104507:	c3                   	ret    
f0104508:	90                   	nop
f0104509:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104510:	89 d8                	mov    %ebx,%eax
f0104512:	f7 f7                	div    %edi
f0104514:	31 ff                	xor    %edi,%edi
f0104516:	89 c3                	mov    %eax,%ebx
f0104518:	89 d8                	mov    %ebx,%eax
f010451a:	89 fa                	mov    %edi,%edx
f010451c:	83 c4 1c             	add    $0x1c,%esp
f010451f:	5b                   	pop    %ebx
f0104520:	5e                   	pop    %esi
f0104521:	5f                   	pop    %edi
f0104522:	5d                   	pop    %ebp
f0104523:	c3                   	ret    
f0104524:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104528:	39 ce                	cmp    %ecx,%esi
f010452a:	72 0c                	jb     f0104538 <__udivdi3+0x118>
f010452c:	31 db                	xor    %ebx,%ebx
f010452e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104532:	0f 87 34 ff ff ff    	ja     f010446c <__udivdi3+0x4c>
f0104538:	bb 01 00 00 00       	mov    $0x1,%ebx
f010453d:	e9 2a ff ff ff       	jmp    f010446c <__udivdi3+0x4c>
f0104542:	66 90                	xchg   %ax,%ax
f0104544:	66 90                	xchg   %ax,%ax
f0104546:	66 90                	xchg   %ax,%ax
f0104548:	66 90                	xchg   %ax,%ax
f010454a:	66 90                	xchg   %ax,%ax
f010454c:	66 90                	xchg   %ax,%ax
f010454e:	66 90                	xchg   %ax,%ax

f0104550 <__umoddi3>:
f0104550:	55                   	push   %ebp
f0104551:	57                   	push   %edi
f0104552:	56                   	push   %esi
f0104553:	53                   	push   %ebx
f0104554:	83 ec 1c             	sub    $0x1c,%esp
f0104557:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010455b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010455f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104563:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104567:	85 d2                	test   %edx,%edx
f0104569:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010456d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104571:	89 f3                	mov    %esi,%ebx
f0104573:	89 3c 24             	mov    %edi,(%esp)
f0104576:	89 74 24 04          	mov    %esi,0x4(%esp)
f010457a:	75 1c                	jne    f0104598 <__umoddi3+0x48>
f010457c:	39 f7                	cmp    %esi,%edi
f010457e:	76 50                	jbe    f01045d0 <__umoddi3+0x80>
f0104580:	89 c8                	mov    %ecx,%eax
f0104582:	89 f2                	mov    %esi,%edx
f0104584:	f7 f7                	div    %edi
f0104586:	89 d0                	mov    %edx,%eax
f0104588:	31 d2                	xor    %edx,%edx
f010458a:	83 c4 1c             	add    $0x1c,%esp
f010458d:	5b                   	pop    %ebx
f010458e:	5e                   	pop    %esi
f010458f:	5f                   	pop    %edi
f0104590:	5d                   	pop    %ebp
f0104591:	c3                   	ret    
f0104592:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104598:	39 f2                	cmp    %esi,%edx
f010459a:	89 d0                	mov    %edx,%eax
f010459c:	77 52                	ja     f01045f0 <__umoddi3+0xa0>
f010459e:	0f bd ea             	bsr    %edx,%ebp
f01045a1:	83 f5 1f             	xor    $0x1f,%ebp
f01045a4:	75 5a                	jne    f0104600 <__umoddi3+0xb0>
f01045a6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01045aa:	0f 82 e0 00 00 00    	jb     f0104690 <__umoddi3+0x140>
f01045b0:	39 0c 24             	cmp    %ecx,(%esp)
f01045b3:	0f 86 d7 00 00 00    	jbe    f0104690 <__umoddi3+0x140>
f01045b9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045bd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01045c1:	83 c4 1c             	add    $0x1c,%esp
f01045c4:	5b                   	pop    %ebx
f01045c5:	5e                   	pop    %esi
f01045c6:	5f                   	pop    %edi
f01045c7:	5d                   	pop    %ebp
f01045c8:	c3                   	ret    
f01045c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045d0:	85 ff                	test   %edi,%edi
f01045d2:	89 fd                	mov    %edi,%ebp
f01045d4:	75 0b                	jne    f01045e1 <__umoddi3+0x91>
f01045d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01045db:	31 d2                	xor    %edx,%edx
f01045dd:	f7 f7                	div    %edi
f01045df:	89 c5                	mov    %eax,%ebp
f01045e1:	89 f0                	mov    %esi,%eax
f01045e3:	31 d2                	xor    %edx,%edx
f01045e5:	f7 f5                	div    %ebp
f01045e7:	89 c8                	mov    %ecx,%eax
f01045e9:	f7 f5                	div    %ebp
f01045eb:	89 d0                	mov    %edx,%eax
f01045ed:	eb 99                	jmp    f0104588 <__umoddi3+0x38>
f01045ef:	90                   	nop
f01045f0:	89 c8                	mov    %ecx,%eax
f01045f2:	89 f2                	mov    %esi,%edx
f01045f4:	83 c4 1c             	add    $0x1c,%esp
f01045f7:	5b                   	pop    %ebx
f01045f8:	5e                   	pop    %esi
f01045f9:	5f                   	pop    %edi
f01045fa:	5d                   	pop    %ebp
f01045fb:	c3                   	ret    
f01045fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104600:	8b 34 24             	mov    (%esp),%esi
f0104603:	bf 20 00 00 00       	mov    $0x20,%edi
f0104608:	89 e9                	mov    %ebp,%ecx
f010460a:	29 ef                	sub    %ebp,%edi
f010460c:	d3 e0                	shl    %cl,%eax
f010460e:	89 f9                	mov    %edi,%ecx
f0104610:	89 f2                	mov    %esi,%edx
f0104612:	d3 ea                	shr    %cl,%edx
f0104614:	89 e9                	mov    %ebp,%ecx
f0104616:	09 c2                	or     %eax,%edx
f0104618:	89 d8                	mov    %ebx,%eax
f010461a:	89 14 24             	mov    %edx,(%esp)
f010461d:	89 f2                	mov    %esi,%edx
f010461f:	d3 e2                	shl    %cl,%edx
f0104621:	89 f9                	mov    %edi,%ecx
f0104623:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104627:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010462b:	d3 e8                	shr    %cl,%eax
f010462d:	89 e9                	mov    %ebp,%ecx
f010462f:	89 c6                	mov    %eax,%esi
f0104631:	d3 e3                	shl    %cl,%ebx
f0104633:	89 f9                	mov    %edi,%ecx
f0104635:	89 d0                	mov    %edx,%eax
f0104637:	d3 e8                	shr    %cl,%eax
f0104639:	89 e9                	mov    %ebp,%ecx
f010463b:	09 d8                	or     %ebx,%eax
f010463d:	89 d3                	mov    %edx,%ebx
f010463f:	89 f2                	mov    %esi,%edx
f0104641:	f7 34 24             	divl   (%esp)
f0104644:	89 d6                	mov    %edx,%esi
f0104646:	d3 e3                	shl    %cl,%ebx
f0104648:	f7 64 24 04          	mull   0x4(%esp)
f010464c:	39 d6                	cmp    %edx,%esi
f010464e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104652:	89 d1                	mov    %edx,%ecx
f0104654:	89 c3                	mov    %eax,%ebx
f0104656:	72 08                	jb     f0104660 <__umoddi3+0x110>
f0104658:	75 11                	jne    f010466b <__umoddi3+0x11b>
f010465a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010465e:	73 0b                	jae    f010466b <__umoddi3+0x11b>
f0104660:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104664:	1b 14 24             	sbb    (%esp),%edx
f0104667:	89 d1                	mov    %edx,%ecx
f0104669:	89 c3                	mov    %eax,%ebx
f010466b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010466f:	29 da                	sub    %ebx,%edx
f0104671:	19 ce                	sbb    %ecx,%esi
f0104673:	89 f9                	mov    %edi,%ecx
f0104675:	89 f0                	mov    %esi,%eax
f0104677:	d3 e0                	shl    %cl,%eax
f0104679:	89 e9                	mov    %ebp,%ecx
f010467b:	d3 ea                	shr    %cl,%edx
f010467d:	89 e9                	mov    %ebp,%ecx
f010467f:	d3 ee                	shr    %cl,%esi
f0104681:	09 d0                	or     %edx,%eax
f0104683:	89 f2                	mov    %esi,%edx
f0104685:	83 c4 1c             	add    $0x1c,%esp
f0104688:	5b                   	pop    %ebx
f0104689:	5e                   	pop    %esi
f010468a:	5f                   	pop    %edi
f010468b:	5d                   	pop    %ebp
f010468c:	c3                   	ret    
f010468d:	8d 76 00             	lea    0x0(%esi),%esi
f0104690:	29 f9                	sub    %edi,%ecx
f0104692:	19 d6                	sbb    %edx,%esi
f0104694:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104698:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010469c:	e9 18 ff ff ff       	jmp    f01045b9 <__umoddi3+0x69>
