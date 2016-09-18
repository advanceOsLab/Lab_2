
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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
}
>>>>>>> lab1
*/
void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 39 11 f0       	mov    $0xf0113970,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 33 11 f0 	movl   $0xf0113300,(%esp)
f0100063:	e8 8f 1a 00 00       	call   f0101af7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 92 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 1f 10 f0 	movl   $0xf0101fa0,(%esp)
f010007c:	e8 ac 0e 00 00       	call   f0100f2d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 fd 08 00 00       	call   f0100983 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 14 07 00 00       	call   f01007a6 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 bb 1f 10 f0 	movl   $0xf0101fbb,(%esp)
f01000c8:	e8 60 0e 00 00       	call   f0100f2d <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 21 0e 00 00       	call   f0100efa <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 9e 22 10 f0 	movl   $0xf010229e,(%esp)
f01000e0:	e8 48 0e 00 00       	call   f0100f2d <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 b5 06 00 00       	call   f01007a6 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 d3 1f 10 f0 	movl   $0xf0101fd3,(%esp)
f0100112:	e8 16 0e 00 00       	call   f0100f2d <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 d4 0d 00 00       	call   f0100efa <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 9e 22 10 f0 	movl   $0xf010229e,(%esp)
f010012d:	e8 fb 0d 00 00       	call   f0100f2d <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 35 11 f0       	mov    0xf0113524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 35 11 f0    	mov    %ecx,0xf0113524
f0100179:	88 90 20 33 11 f0    	mov    %dl,-0xfeecce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 ef 00 00 00    	je     f010029d <kbd_proc_data+0xfd>
f01001ae:	b2 60                	mov    $0x60,%dl
f01001b0:	ec                   	in     (%dx),%al
f01001b1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b3:	3c e0                	cmp    $0xe0,%al
f01001b5:	75 0d                	jne    f01001c4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001b7:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
		return 0;
f01001be:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001c3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	53                   	push   %ebx
f01001c8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001cb:	84 c0                	test   %al,%al
f01001cd:	79 37                	jns    f0100206 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cf:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f01001d5:	89 cb                	mov    %ecx,%ebx
f01001d7:	83 e3 40             	and    $0x40,%ebx
f01001da:	83 e0 7f             	and    $0x7f,%eax
f01001dd:	85 db                	test   %ebx,%ebx
f01001df:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e2:	0f b6 d2             	movzbl %dl,%edx
f01001e5:	0f b6 82 40 21 10 f0 	movzbl -0xfefdec0(%edx),%eax
f01001ec:	83 c8 40             	or     $0x40,%eax
f01001ef:	0f b6 c0             	movzbl %al,%eax
f01001f2:	f7 d0                	not    %eax
f01001f4:	21 c1                	and    %eax,%ecx
f01001f6:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
		return 0;
f01001fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100201:	e9 9d 00 00 00       	jmp    f01002a3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100206:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f010020c:	f6 c1 40             	test   $0x40,%cl
f010020f:	74 0e                	je     f010021f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100211:	83 c8 80             	or     $0xffffff80,%eax
f0100214:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100216:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100219:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	}

	shift |= shiftcode[data];
f010021f:	0f b6 d2             	movzbl %dl,%edx
f0100222:	0f b6 82 40 21 10 f0 	movzbl -0xfefdec0(%edx),%eax
f0100229:	0b 05 00 33 11 f0    	or     0xf0113300,%eax
	shift ^= togglecode[data];
f010022f:	0f b6 8a 40 20 10 f0 	movzbl -0xfefdfc0(%edx),%ecx
f0100236:	31 c8                	xor    %ecx,%eax
f0100238:	a3 00 33 11 f0       	mov    %eax,0xf0113300

	c = charcode[shift & (CTL | SHIFT)][data];
f010023d:	89 c1                	mov    %eax,%ecx
f010023f:	83 e1 03             	and    $0x3,%ecx
f0100242:	8b 0c 8d 20 20 10 f0 	mov    -0xfefdfe0(,%ecx,4),%ecx
f0100249:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100250:	a8 08                	test   $0x8,%al
f0100252:	74 1b                	je     f010026f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100254:	89 da                	mov    %ebx,%edx
f0100256:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100259:	83 f9 19             	cmp    $0x19,%ecx
f010025c:	77 05                	ja     f0100263 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010025e:	83 eb 20             	sub    $0x20,%ebx
f0100261:	eb 0c                	jmp    f010026f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100263:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100266:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100269:	83 fa 19             	cmp    $0x19,%edx
f010026c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026f:	f7 d0                	not    %eax
f0100271:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100273:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100275:	f6 c2 06             	test   $0x6,%dl
f0100278:	75 29                	jne    f01002a3 <kbd_proc_data+0x103>
f010027a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100280:	75 21                	jne    f01002a3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100282:	c7 04 24 ed 1f 10 f0 	movl   $0xf0101fed,(%esp)
f0100289:	e8 9f 0c 00 00       	call   f0100f2d <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100293:	b8 03 00 00 00       	mov    $0x3,%eax
f0100298:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100299:	89 d8                	mov    %ebx,%eax
f010029b:	eb 06                	jmp    f01002a3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010029d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002a3:	83 c4 14             	add    $0x14,%esp
f01002a6:	5b                   	pop    %ebx
f01002a7:	5d                   	pop    %ebp
f01002a8:	c3                   	ret    

f01002a9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a9:	55                   	push   %ebp
f01002aa:	89 e5                	mov    %esp,%ebp
f01002ac:	57                   	push   %edi
f01002ad:	56                   	push   %esi
f01002ae:	53                   	push   %ebx
f01002af:	83 ec 1c             	sub    $0x1c,%esp
f01002b2:	89 c7                	mov    %eax,%edi
f01002b4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002be:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c3:	eb 06                	jmp    f01002cb <cons_putc+0x22>
f01002c5:	89 ca                	mov    %ecx,%edx
f01002c7:	ec                   	in     (%dx),%al
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	ec                   	in     (%dx),%al
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	89 f2                	mov    %esi,%edx
f01002cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ce:	a8 20                	test   $0x20,%al
f01002d0:	75 05                	jne    f01002d7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d2:	83 eb 01             	sub    $0x1,%ebx
f01002d5:	75 ee                	jne    f01002c5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002d7:	89 f8                	mov    %edi,%eax
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002df:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e4:	ee                   	out    %al,(%dx)
f01002e5:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ea:	be 79 03 00 00       	mov    $0x379,%esi
f01002ef:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f4:	eb 06                	jmp    f01002fc <cons_putc+0x53>
f01002f6:	89 ca                	mov    %ecx,%edx
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	ec                   	in     (%dx),%al
f01002fb:	ec                   	in     (%dx),%al
f01002fc:	89 f2                	mov    %esi,%edx
f01002fe:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ff:	84 c0                	test   %al,%al
f0100301:	78 05                	js     f0100308 <cons_putc+0x5f>
f0100303:	83 eb 01             	sub    $0x1,%ebx
f0100306:	75 ee                	jne    f01002f6 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100308:	ba 78 03 00 00       	mov    $0x378,%edx
f010030d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100311:	ee                   	out    %al,(%dx)
f0100312:	b2 7a                	mov    $0x7a,%dl
f0100314:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100319:	ee                   	out    %al,(%dx)
f010031a:	b8 08 00 00 00       	mov    $0x8,%eax
f010031f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100328:	89 f8                	mov    %edi,%eax
f010032a:	80 cc 07             	or     $0x7,%ah
f010032d:	85 d2                	test   %edx,%edx
f010032f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	0f b6 c0             	movzbl %al,%eax
f0100337:	83 f8 09             	cmp    $0x9,%eax
f010033a:	74 76                	je     f01003b2 <cons_putc+0x109>
f010033c:	83 f8 09             	cmp    $0x9,%eax
f010033f:	7f 0a                	jg     f010034b <cons_putc+0xa2>
f0100341:	83 f8 08             	cmp    $0x8,%eax
f0100344:	74 16                	je     f010035c <cons_putc+0xb3>
f0100346:	e9 9b 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
f010034b:	83 f8 0a             	cmp    $0xa,%eax
f010034e:	66 90                	xchg   %ax,%ax
f0100350:	74 3a                	je     f010038c <cons_putc+0xe3>
f0100352:	83 f8 0d             	cmp    $0xd,%eax
f0100355:	74 3d                	je     f0100394 <cons_putc+0xeb>
f0100357:	e9 8a 00 00 00       	jmp    f01003e6 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010035c:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100363:	66 85 c0             	test   %ax,%ax
f0100366:	0f 84 e5 00 00 00    	je     f0100451 <cons_putc+0x1a8>
			crt_pos--;
f010036c:	83 e8 01             	sub    $0x1,%eax
f010036f:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100375:	0f b7 c0             	movzwl %ax,%eax
f0100378:	66 81 e7 00 ff       	and    $0xff00,%di
f010037d:	83 cf 20             	or     $0x20,%edi
f0100380:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100386:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010038a:	eb 78                	jmp    f0100404 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038c:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f0100393:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100394:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f010039b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a1:	c1 e8 16             	shr    $0x16,%eax
f01003a4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a7:	c1 e0 04             	shl    $0x4,%eax
f01003aa:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
f01003b0:	eb 52                	jmp    f0100404 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b7:	e8 ed fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c1:	e8 e3 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cb:	e8 d9 fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d5:	e8 cf fe ff ff       	call   f01002a9 <cons_putc>
		cons_putc(' ');
f01003da:	b8 20 00 00 00       	mov    $0x20,%eax
f01003df:	e8 c5 fe ff ff       	call   f01002a9 <cons_putc>
f01003e4:	eb 1e                	jmp    f0100404 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e6:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f01003ed:	8d 50 01             	lea    0x1(%eax),%edx
f01003f0:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
f01003f7:	0f b7 c0             	movzwl %ax,%eax
f01003fa:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100400:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100404:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f010040b:	cf 07 
f010040d:	76 42                	jbe    f0100451 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040f:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f0100414:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010041b:	00 
f010041c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100422:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100426:	89 04 24             	mov    %eax,(%esp)
f0100429:	e8 16 17 00 00       	call   f0101b44 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010042e:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100434:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100439:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043f:	83 c0 01             	add    $0x1,%eax
f0100442:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100447:	75 f0                	jne    f0100439 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	83 c4 1c             	add    $0x1c,%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f010049b:	e8 bc fc ff ff       	call   f010015c <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004ae:	e8 a9 fc ff ff       	call   f010015c <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 35 11 f0       	mov    0xf0113520,%eax
f01004ca:	3b 05 24 35 11 f0    	cmp    0xf0113524,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 35 11 f0    	mov    %edx,0xf0113520
f01004db:	0f b6 88 20 33 11 f0 	movzbl -0xfeecce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 0d 30 35 11 f0    	mov    0xf0113530,%ecx
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 ca                	mov    %ecx,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 f0             	movzbl %al,%esi
f0100563:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 ca                	mov    %ecx,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 3d 2c 35 11 f0    	mov    %edi,0xf011352c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100577:	0f b6 d8             	movzbl %al,%ebx
f010057a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010057c:	66 89 35 28 35 11 f0 	mov    %si,0xf0113528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100583:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100588:	b8 00 00 00 00       	mov    $0x0,%eax
f010058d:	89 f2                	mov    %esi,%edx
f010058f:	ee                   	out    %al,(%dx)
f0100590:	b2 fb                	mov    $0xfb,%dl
f0100592:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100597:	ee                   	out    %al,(%dx)
f0100598:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059d:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a2:	89 da                	mov    %ebx,%edx
f01005a4:	ee                   	out    %al,(%dx)
f01005a5:	b2 f9                	mov    $0xf9,%dl
f01005a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 fb                	mov    $0xfb,%dl
f01005af:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 fc                	mov    $0xfc,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 f9                	mov    $0xf9,%dl
f01005bf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c5:	b2 fd                	mov    $0xfd,%dl
f01005c7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c8:	3c ff                	cmp    $0xff,%al
f01005ca:	0f 95 c1             	setne  %cl
f01005cd:	88 0d 34 35 11 f0    	mov    %cl,0xf0113534
f01005d3:	89 f2                	mov    %esi,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	84 c9                	test   %cl,%cl
f01005db:	75 0c                	jne    f01005e9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005dd:	c7 04 24 f9 1f 10 f0 	movl   $0xf0101ff9,(%esp)
f01005e4:	e8 44 09 00 00       	call   f0100f2d <cprintf>
}
f01005e9:	83 c4 1c             	add    $0x1c,%esp
f01005ec:	5b                   	pop    %ebx
f01005ed:	5e                   	pop    %esi
f01005ee:	5f                   	pop    %edi
f01005ef:	5d                   	pop    %ebp
f01005f0:	c3                   	ret    

f01005f1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fa:	e8 aa fc ff ff       	call   f01002a9 <cons_putc>
}
f01005ff:	c9                   	leave  
f0100600:	c3                   	ret    

f0100601 <getchar>:

int
getchar(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100607:	e8 a9 fe ff ff       	call   f01004b5 <cons_getc>
f010060c:	85 c0                	test   %eax,%eax
f010060e:	74 f7                	je     f0100607 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <iscons>:

int
iscons(int fdnum)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100615:	b8 01 00 00 00       	mov    $0x1,%eax
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    
f010061c:	66 90                	xchg   %ax,%ax
f010061e:	66 90                	xchg   %ax,%ax

f0100620 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100626:	c7 44 24 08 40 22 10 	movl   $0xf0102240,0x8(%esp)
f010062d:	f0 
f010062e:	c7 44 24 04 5e 22 10 	movl   $0xf010225e,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 63 22 10 f0 	movl   $0xf0102263,(%esp)
f010063d:	e8 eb 08 00 00       	call   f0100f2d <cprintf>
f0100642:	c7 44 24 08 dc 22 10 	movl   $0xf01022dc,0x8(%esp)
f0100649:	f0 
f010064a:	c7 44 24 04 6c 22 10 	movl   $0xf010226c,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 63 22 10 f0 	movl   $0xf0102263,(%esp)
f0100659:	e8 cf 08 00 00       	call   f0100f2d <cprintf>
	return 0;
}
f010065e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100663:	c9                   	leave  
f0100664:	c3                   	ret    

f0100665 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100665:	55                   	push   %ebp
f0100666:	89 e5                	mov    %esp,%ebp
f0100668:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010066b:	c7 04 24 75 22 10 f0 	movl   $0xf0102275,(%esp)
f0100672:	e8 b6 08 00 00       	call   f0100f2d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100677:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010067e:	00 
f010067f:	c7 04 24 04 23 10 f0 	movl   $0xf0102304,(%esp)
f0100686:	e8 a2 08 00 00       	call   f0100f2d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068b:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100692:	00 
f0100693:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010069a:	f0 
f010069b:	c7 04 24 2c 23 10 f0 	movl   $0xf010232c,(%esp)
f01006a2:	e8 86 08 00 00       	call   f0100f2d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a7:	c7 44 24 08 87 1f 10 	movl   $0x101f87,0x8(%esp)
f01006ae:	00 
f01006af:	c7 44 24 04 87 1f 10 	movl   $0xf0101f87,0x4(%esp)
f01006b6:	f0 
f01006b7:	c7 04 24 50 23 10 f0 	movl   $0xf0102350,(%esp)
f01006be:	e8 6a 08 00 00       	call   f0100f2d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c3:	c7 44 24 08 00 33 11 	movl   $0x113300,0x8(%esp)
f01006ca:	00 
f01006cb:	c7 44 24 04 00 33 11 	movl   $0xf0113300,0x4(%esp)
f01006d2:	f0 
f01006d3:	c7 04 24 74 23 10 f0 	movl   $0xf0102374,(%esp)
f01006da:	e8 4e 08 00 00       	call   f0100f2d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	c7 44 24 08 70 39 11 	movl   $0x113970,0x8(%esp)
f01006e6:	00 
f01006e7:	c7 44 24 04 70 39 11 	movl   $0xf0113970,0x4(%esp)
f01006ee:	f0 
f01006ef:	c7 04 24 98 23 10 f0 	movl   $0xf0102398,(%esp)
f01006f6:	e8 32 08 00 00       	call   f0100f2d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006fb:	b8 6f 3d 11 f0       	mov    $0xf0113d6f,%eax
f0100700:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071c:	c7 04 24 bc 23 10 f0 	movl   $0xf01023bc,(%esp)
f0100723:	e8 05 08 00 00       	call   f0100f2d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100728:	b8 00 00 00 00       	mov    $0x0,%eax
f010072d:	c9                   	leave  
f010072e:	c3                   	ret    

f010072f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072f:	55                   	push   %ebp
f0100730:	89 e5                	mov    %esp,%ebp
f0100732:	56                   	push   %esi
f0100733:	53                   	push   %ebx
f0100734:	83 ec 40             	sub    $0x40,%esp
	uint32_t ebpr = 1;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
f0100737:	89 eb                	mov    %ebp,%ebx
	
	//__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	//ptr= (uint32_t*)ebpr;	
	cprintf("EBPR :%08x  ,EIP %08x  ,args:  %08x , %08x \n",ptr,*(ptr+1),*(ptr+2),*(ptr+3));
	address	= *(ptr+1);
	debuginfo_eip(address, &eipinfo);
f0100739:	8d 75 e0             	lea    -0x20(%ebp),%esi
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
	uint32_t *temp;
	uint32_t address;
	struct Eipdebuginfo eipinfo;
	while(*ptr!=0)
f010073c:	eb 57                	jmp    f0100795 <mon_backtrace+0x66>
	{
	
	//__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	//ptr= (uint32_t*)ebpr;	
	cprintf("EBPR :%08x  ,EIP %08x  ,args:  %08x , %08x \n",ptr,*(ptr+1),*(ptr+2),*(ptr+3));
f010073e:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100741:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100745:	8b 43 08             	mov    0x8(%ebx),%eax
f0100748:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010074c:	8b 43 04             	mov    0x4(%ebx),%eax
f010074f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100753:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100757:	c7 04 24 e8 23 10 f0 	movl   $0xf01023e8,(%esp)
f010075e:	e8 ca 07 00 00       	call   f0100f2d <cprintf>
	address	= *(ptr+1);
	debuginfo_eip(address, &eipinfo);
f0100763:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100767:	8b 43 04             	mov    0x4(%ebx),%eax
f010076a:	89 04 24             	mov    %eax,(%esp)
f010076d:	e8 b2 08 00 00       	call   f0101024 <debuginfo_eip>
	cprintf("%s  , %d  ,  %s \n",eipinfo.eip_file,eipinfo.eip_line,eipinfo.eip_fn_name);
f0100772:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100775:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100779:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010077c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100780:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100783:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100787:	c7 04 24 8e 22 10 f0 	movl   $0xf010228e,(%esp)
f010078e:	e8 9a 07 00 00       	call   f0100f2d <cprintf>
	temp = ptr;
	ptr = (uint32_t*) *temp;	
f0100793:	8b 1b                	mov    (%ebx),%ebx
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
	uint32_t *temp;
	uint32_t address;
	struct Eipdebuginfo eipinfo;
	while(*ptr!=0)
f0100795:	83 3b 00             	cmpl   $0x0,(%ebx)
f0100798:	75 a4                	jne    f010073e <mon_backtrace+0xf>
	cprintf("%s  , %d  ,  %s \n",eipinfo.eip_file,eipinfo.eip_line,eipinfo.eip_fn_name);
	temp = ptr;
	ptr = (uint32_t*) *temp;	
	}	
	return 0;
}
f010079a:	b8 00 00 00 00       	mov    $0x0,%eax
f010079f:	83 c4 40             	add    $0x40,%esp
f01007a2:	5b                   	pop    %ebx
f01007a3:	5e                   	pop    %esi
f01007a4:	5d                   	pop    %ebp
f01007a5:	c3                   	ret    

f01007a6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
f01007a9:	57                   	push   %edi
f01007aa:	56                   	push   %esi
f01007ab:	53                   	push   %ebx
f01007ac:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007af:	c7 04 24 18 24 10 f0 	movl   $0xf0102418,(%esp)
f01007b6:	e8 72 07 00 00       	call   f0100f2d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007bb:	c7 04 24 3c 24 10 f0 	movl   $0xf010243c,(%esp)
f01007c2:	e8 66 07 00 00       	call   f0100f2d <cprintf>


	while (1) {
		buf = readline("K> ");
f01007c7:	c7 04 24 a0 22 10 f0 	movl   $0xf01022a0,(%esp)
f01007ce:	e8 cd 10 00 00       	call   f01018a0 <readline>
f01007d3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d5:	85 c0                	test   %eax,%eax
f01007d7:	74 ee                	je     f01007c7 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007d9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e0:	be 00 00 00 00       	mov    $0x0,%esi
f01007e5:	eb 0a                	jmp    f01007f1 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007e7:	c6 03 00             	movb   $0x0,(%ebx)
f01007ea:	89 f7                	mov    %esi,%edi
f01007ec:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007ef:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f1:	0f b6 03             	movzbl (%ebx),%eax
f01007f4:	84 c0                	test   %al,%al
f01007f6:	74 63                	je     f010085b <monitor+0xb5>
f01007f8:	0f be c0             	movsbl %al,%eax
f01007fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ff:	c7 04 24 a4 22 10 f0 	movl   $0xf01022a4,(%esp)
f0100806:	e8 af 12 00 00       	call   f0101aba <strchr>
f010080b:	85 c0                	test   %eax,%eax
f010080d:	75 d8                	jne    f01007e7 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010080f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100812:	74 47                	je     f010085b <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100814:	83 fe 0f             	cmp    $0xf,%esi
f0100817:	75 16                	jne    f010082f <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100819:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100820:	00 
f0100821:	c7 04 24 a9 22 10 f0 	movl   $0xf01022a9,(%esp)
f0100828:	e8 00 07 00 00       	call   f0100f2d <cprintf>
f010082d:	eb 98                	jmp    f01007c7 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010082f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100832:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100836:	eb 03                	jmp    f010083b <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100838:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083b:	0f b6 03             	movzbl (%ebx),%eax
f010083e:	84 c0                	test   %al,%al
f0100840:	74 ad                	je     f01007ef <monitor+0x49>
f0100842:	0f be c0             	movsbl %al,%eax
f0100845:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100849:	c7 04 24 a4 22 10 f0 	movl   $0xf01022a4,(%esp)
f0100850:	e8 65 12 00 00       	call   f0101aba <strchr>
f0100855:	85 c0                	test   %eax,%eax
f0100857:	74 df                	je     f0100838 <monitor+0x92>
f0100859:	eb 94                	jmp    f01007ef <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010085b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100862:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100863:	85 f6                	test   %esi,%esi
f0100865:	0f 84 5c ff ff ff    	je     f01007c7 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010086b:	c7 44 24 04 5e 22 10 	movl   $0xf010225e,0x4(%esp)
f0100872:	f0 
f0100873:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100876:	89 04 24             	mov    %eax,(%esp)
f0100879:	e8 de 11 00 00       	call   f0101a5c <strcmp>
f010087e:	85 c0                	test   %eax,%eax
f0100880:	74 1b                	je     f010089d <monitor+0xf7>
f0100882:	c7 44 24 04 6c 22 10 	movl   $0xf010226c,0x4(%esp)
f0100889:	f0 
f010088a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010088d:	89 04 24             	mov    %eax,(%esp)
f0100890:	e8 c7 11 00 00       	call   f0101a5c <strcmp>
f0100895:	85 c0                	test   %eax,%eax
f0100897:	75 2f                	jne    f01008c8 <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100899:	b0 01                	mov    $0x1,%al
f010089b:	eb 05                	jmp    f01008a2 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f010089d:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a2:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a5:	01 d0                	add    %edx,%eax
f01008a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008aa:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008ae:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008b5:	89 34 24             	mov    %esi,(%esp)
f01008b8:	ff 14 85 6c 24 10 f0 	call   *-0xfefdb94(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	78 1d                	js     f01008e0 <monitor+0x13a>
f01008c3:	e9 ff fe ff ff       	jmp    f01007c7 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008c8:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cf:	c7 04 24 c6 22 10 f0 	movl   $0xf01022c6,(%esp)
f01008d6:	e8 52 06 00 00       	call   f0100f2d <cprintf>
f01008db:	e9 e7 fe ff ff       	jmp    f01007c7 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e0:	83 c4 5c             	add    $0x5c,%esp
f01008e3:	5b                   	pop    %ebx
f01008e4:	5e                   	pop    %esi
f01008e5:	5f                   	pop    %edi
f01008e6:	5d                   	pop    %ebp
f01008e7:	c3                   	ret    

f01008e8 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008e8:	55                   	push   %ebp
f01008e9:	89 e5                	mov    %esp,%ebp
f01008eb:	53                   	push   %ebx
f01008ec:	83 ec 14             	sub    $0x14,%esp
f01008ef:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008f1:	83 3d 38 35 11 f0 00 	cmpl   $0x0,0xf0113538
f01008f8:	75 23                	jne    f010091d <boot_alloc+0x35>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008fa:	b8 6f 49 11 f0       	mov    $0xf011496f,%eax
f01008ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100904:	a3 38 35 11 f0       	mov    %eax,0xf0113538
		cprintf("End:%x\n",end);
f0100909:	c7 44 24 04 70 39 11 	movl   $0xf0113970,0x4(%esp)
f0100910:	f0 
f0100911:	c7 04 24 7c 24 10 f0 	movl   $0xf010247c,(%esp)
f0100918:	e8 10 06 00 00       	call   f0100f2d <cprintf>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	//return NULL;
	next = nextfree;
f010091d:	a1 38 35 11 f0       	mov    0xf0113538,%eax
	nextfree = ROUNDUP((char*)(nextfree + n) , PGSIZE);	
f0100922:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f0100929:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010092f:	89 15 38 35 11 f0    	mov    %edx,0xf0113538
	return next;
}
f0100935:	83 c4 14             	add    $0x14,%esp
f0100938:	5b                   	pop    %ebx
f0100939:	5d                   	pop    %ebp
f010093a:	c3                   	ret    

f010093b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010093b:	55                   	push   %ebp
f010093c:	89 e5                	mov    %esp,%ebp
f010093e:	56                   	push   %esi
f010093f:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem ; i++) {
f0100940:	8b 35 40 35 11 f0    	mov    0xf0113540,%esi
f0100946:	8b 1d 3c 35 11 f0    	mov    0xf011353c,%ebx
f010094c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100951:	eb 22                	jmp    f0100975 <page_init+0x3a>
f0100953:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f010095a:	89 d1                	mov    %edx,%ecx
f010095c:	03 0d 6c 39 11 f0    	add    0xf011396c,%ecx
f0100962:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100968:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem ; i++) {
f010096a:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f010096d:	89 d3                	mov    %edx,%ebx
f010096f:	03 1d 6c 39 11 f0    	add    0xf011396c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem ; i++) {
f0100975:	39 f0                	cmp    %esi,%eax
f0100977:	72 da                	jb     f0100953 <page_init+0x18>
f0100979:	89 1d 3c 35 11 f0    	mov    %ebx,0xf011353c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f010097f:	5b                   	pop    %ebx
f0100980:	5e                   	pop    %esi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010098c:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0100993:	e8 25 05 00 00       	call   f0100ebd <mc146818_read>
f0100998:	89 c3                	mov    %eax,%ebx
f010099a:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01009a1:	e8 17 05 00 00       	call   f0100ebd <mc146818_read>
f01009a6:	c1 e0 08             	shl    $0x8,%eax
f01009a9:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01009ab:	89 d8                	mov    %ebx,%eax
f01009ad:	c1 e0 0a             	shl    $0xa,%eax
f01009b0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01009b6:	85 c0                	test   %eax,%eax
f01009b8:	0f 48 c2             	cmovs  %edx,%eax
f01009bb:	c1 f8 0c             	sar    $0xc,%eax
f01009be:	a3 40 35 11 f0       	mov    %eax,0xf0113540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009c3:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01009ca:	e8 ee 04 00 00       	call   f0100ebd <mc146818_read>
f01009cf:	89 c3                	mov    %eax,%ebx
f01009d1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01009d8:	e8 e0 04 00 00       	call   f0100ebd <mc146818_read>
f01009dd:	c1 e0 08             	shl    $0x8,%eax
f01009e0:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01009e2:	89 d8                	mov    %ebx,%eax
f01009e4:	c1 e0 0a             	shl    $0xa,%eax
f01009e7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01009ed:	85 c0                	test   %eax,%eax
f01009ef:	0f 48 c2             	cmovs  %edx,%eax
f01009f2:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01009f5:	85 c0                	test   %eax,%eax
f01009f7:	74 0e                	je     f0100a07 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01009f9:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01009ff:	89 15 64 39 11 f0    	mov    %edx,0xf0113964
f0100a05:	eb 0c                	jmp    f0100a13 <mem_init+0x90>
	else
		npages = npages_basemem;//npages = 16639
f0100a07:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
f0100a0d:	89 15 64 39 11 f0    	mov    %edx,0xf0113964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100a13:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;//npages = 16639

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a16:	c1 e8 0a             	shr    $0xa,%eax
f0100a19:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100a1d:	a1 40 35 11 f0       	mov    0xf0113540,%eax
f0100a22:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;//npages = 16639

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a25:	c1 e8 0a             	shr    $0xa,%eax
f0100a28:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100a2c:	a1 64 39 11 f0       	mov    0xf0113964,%eax
f0100a31:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;//npages = 16639

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a34:	c1 e8 0a             	shr    $0xa,%eax
f0100a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3b:	c7 04 24 84 25 10 f0 	movl   $0xf0102584,(%esp)
f0100a42:	e8 e6 04 00 00       	call   f0100f2d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100a47:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100a4c:	e8 97 fe ff ff       	call   f01008e8 <boot_alloc>
f0100a51:	a3 68 39 11 f0       	mov    %eax,0xf0113968
	memset(kern_pgdir, 0, PGSIZE);
f0100a56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100a5d:	00 
f0100a5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100a65:	00 
f0100a66:	89 04 24             	mov    %eax,(%esp)
f0100a69:	e8 89 10 00 00       	call   f0101af7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;//How its recursion?
f0100a6e:	a1 68 39 11 f0       	mov    0xf0113968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a73:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100a78:	77 20                	ja     f0100a9a <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a7a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a7e:	c7 44 24 08 c0 25 10 	movl   $0xf01025c0,0x8(%esp)
f0100a85:	f0 
f0100a86:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0100a8d:	00 
f0100a8e:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100a95:	e8 fa f5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100a9a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100aa0:	83 ca 05             	or     $0x5,%edx
f0100aa3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("kern_pgdir: %x,kern_pgdir[PDX(UVPT)]: %x,PDX(UVPT): %x\n",kern_pgdir,kern_pgdir[PDX(UVPT)],PDX(UVPT));
f0100aa9:	c7 44 24 0c bd 03 00 	movl   $0x3bd,0xc(%esp)
f0100ab0:	00 
f0100ab1:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ab5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ab9:	c7 04 24 e4 25 10 f0 	movl   $0xf01025e4,(%esp)
f0100ac0:	e8 68 04 00 00       	call   f0100f2d <cprintf>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100ac5:	e8 71 fe ff ff       	call   f010093b <page_init>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100aca:	a1 3c 35 11 f0       	mov    0xf011353c,%eax
f0100acf:	85 c0                	test   %eax,%eax
f0100ad1:	75 1c                	jne    f0100aef <mem_init+0x16c>
		panic("'page_free_list' is a null pointer!");
f0100ad3:	c7 44 24 08 1c 26 10 	movl   $0xf010261c,0x8(%esp)
f0100ada:	f0 
f0100adb:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
f0100ae2:	00 
f0100ae3:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100aea:	e8 a5 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aef:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100af2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100af5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100afb:	89 c2                	mov    %eax,%edx
f0100afd:	2b 15 6c 39 11 f0    	sub    0xf011396c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b03:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b09:	0f 95 c2             	setne  %dl
f0100b0c:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b0f:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b13:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b15:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b19:	8b 00                	mov    (%eax),%eax
f0100b1b:	85 c0                	test   %eax,%eax
f0100b1d:	75 dc                	jne    f0100afb <mem_init+0x178>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b1f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b22:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b28:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b2b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b2e:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b30:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100b33:	89 1d 3c 35 11 f0    	mov    %ebx,0xf011353c
f0100b39:	eb 64                	jmp    f0100b9f <mem_init+0x21c>
f0100b3b:	89 d8                	mov    %ebx,%eax
f0100b3d:	2b 05 6c 39 11 f0    	sub    0xf011396c,%eax
f0100b43:	c1 f8 03             	sar    $0x3,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b46:	89 c2                	mov    %eax,%edx
f0100b48:	c1 e2 0c             	shl    $0xc,%edx
f0100b4b:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100b50:	75 4b                	jne    f0100b9d <mem_init+0x21a>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b52:	89 d0                	mov    %edx,%eax
f0100b54:	c1 e8 0c             	shr    $0xc,%eax
f0100b57:	3b 05 64 39 11 f0    	cmp    0xf0113964,%eax
f0100b5d:	72 20                	jb     f0100b7f <mem_init+0x1fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b63:	c7 44 24 08 40 26 10 	movl   $0xf0102640,0x8(%esp)
f0100b6a:	f0 
f0100b6b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b72:	00 
f0100b73:	c7 04 24 90 24 10 f0 	movl   $0xf0102490,(%esp)
f0100b7a:	e8 15 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b7f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b86:	00 
f0100b87:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b8e:	00 
	return (void *)(pa + KERNBASE);
f0100b8f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100b95:	89 14 24             	mov    %edx,(%esp)
f0100b98:	e8 5a 0f 00 00       	call   f0101af7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b9d:	8b 1b                	mov    (%ebx),%ebx
f0100b9f:	85 db                	test   %ebx,%ebx
f0100ba1:	75 98                	jne    f0100b3b <mem_init+0x1b8>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ba3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ba8:	e8 3b fd ff ff       	call   f01008e8 <boot_alloc>
f0100bad:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bb0:	a1 3c 35 11 f0       	mov    0xf011353c,%eax
f0100bb5:	89 45 c0             	mov    %eax,-0x40(%ebp)
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb8:	8b 0d 6c 39 11 f0    	mov    0xf011396c,%ecx
		assert(pp < pages + npages);
f0100bbe:	8b 3d 64 39 11 f0    	mov    0xf0113964,%edi
f0100bc4:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bc7:	8d 3c f9             	lea    (%ecx,%edi,8),%edi
f0100bca:	89 7d d4             	mov    %edi,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bcd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd0:	89 c2                	mov    %eax,%edx
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bd2:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bd7:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100bda:	e9 97 01 00 00       	jmp    f0100d76 <mem_init+0x3f3>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bdf:	39 d1                	cmp    %edx,%ecx
f0100be1:	76 24                	jbe    f0100c07 <mem_init+0x284>
f0100be3:	c7 44 24 0c 9e 24 10 	movl   $0xf010249e,0xc(%esp)
f0100bea:	f0 
f0100beb:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100bf2:	f0 
f0100bf3:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
f0100bfa:	00 
f0100bfb:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100c02:	e8 8d f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100c07:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c0a:	72 24                	jb     f0100c30 <mem_init+0x2ad>
f0100c0c:	c7 44 24 0c bf 24 10 	movl   $0xf01024bf,0xc(%esp)
f0100c13:	f0 
f0100c14:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100c1b:	f0 
f0100c1c:	c7 44 24 04 f0 01 00 	movl   $0x1f0,0x4(%esp)
f0100c23:	00 
f0100c24:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100c2b:	e8 64 f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c30:	89 d0                	mov    %edx,%eax
f0100c32:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c35:	a8 07                	test   $0x7,%al
f0100c37:	74 24                	je     f0100c5d <mem_init+0x2da>
f0100c39:	c7 44 24 0c 64 26 10 	movl   $0xf0102664,0xc(%esp)
f0100c40:	f0 
f0100c41:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100c48:	f0 
f0100c49:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
f0100c50:	00 
f0100c51:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100c58:	e8 37 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c5d:	c1 f8 03             	sar    $0x3,%eax
f0100c60:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c63:	85 c0                	test   %eax,%eax
f0100c65:	75 24                	jne    f0100c8b <mem_init+0x308>
f0100c67:	c7 44 24 0c d3 24 10 	movl   $0xf01024d3,0xc(%esp)
f0100c6e:	f0 
f0100c6f:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100c76:	f0 
f0100c77:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
f0100c7e:	00 
f0100c7f:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100c86:	e8 09 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c8b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c90:	75 24                	jne    f0100cb6 <mem_init+0x333>
f0100c92:	c7 44 24 0c e4 24 10 	movl   $0xf01024e4,0xc(%esp)
f0100c99:	f0 
f0100c9a:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100cb1:	e8 de f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cbb:	75 24                	jne    f0100ce1 <mem_init+0x35e>
f0100cbd:	c7 44 24 0c 98 26 10 	movl   $0xf0102698,0xc(%esp)
f0100cc4:	f0 
f0100cc5:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
f0100cd4:	00 
f0100cd5:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100cdc:	e8 b3 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ce1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ce6:	75 24                	jne    f0100d0c <mem_init+0x389>
f0100ce8:	c7 44 24 0c fd 24 10 	movl   $0xf01024fd,0xc(%esp)
f0100cef:	f0 
f0100cf0:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100cf7:	f0 
f0100cf8:	c7 44 24 04 f7 01 00 	movl   $0x1f7,0x4(%esp)
f0100cff:	00 
f0100d00:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100d07:	e8 88 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d0c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d11:	76 58                	jbe    f0100d6b <mem_init+0x3e8>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d13:	89 c3                	mov    %eax,%ebx
f0100d15:	c1 eb 0c             	shr    $0xc,%ebx
f0100d18:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d1b:	77 20                	ja     f0100d3d <mem_init+0x3ba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d21:	c7 44 24 08 40 26 10 	movl   $0xf0102640,0x8(%esp)
f0100d28:	f0 
f0100d29:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d30:	00 
f0100d31:	c7 04 24 90 24 10 f0 	movl   $0xf0102490,(%esp)
f0100d38:	e8 57 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d42:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d45:	76 2a                	jbe    f0100d71 <mem_init+0x3ee>
f0100d47:	c7 44 24 0c bc 26 10 	movl   $0xf01026bc,0xc(%esp)
f0100d4e:	f0 
f0100d4f:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100d56:	f0 
f0100d57:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
f0100d5e:	00 
f0100d5f:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100d66:	e8 29 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d6b:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d6f:	eb 03                	jmp    f0100d74 <mem_init+0x3f1>
		else
			++nfree_extmem;
f0100d71:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d74:	8b 12                	mov    (%edx),%edx
f0100d76:	85 d2                	test   %edx,%edx
f0100d78:	0f 85 61 fe ff ff    	jne    f0100bdf <mem_init+0x25c>
f0100d7e:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d81:	85 db                	test   %ebx,%ebx
f0100d83:	7f 24                	jg     f0100da9 <mem_init+0x426>
f0100d85:	c7 44 24 0c 17 25 10 	movl   $0xf0102517,0xc(%esp)
f0100d8c:	f0 
f0100d8d:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100d94:	f0 
f0100d95:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
f0100d9c:	00 
f0100d9d:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100da4:	e8 eb f2 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100da9:	85 ff                	test   %edi,%edi
f0100dab:	7f 24                	jg     f0100dd1 <mem_init+0x44e>
f0100dad:	c7 44 24 0c 29 25 10 	movl   $0xf0102529,0xc(%esp)
f0100db4:	f0 
f0100db5:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100dbc:	f0 
f0100dbd:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
f0100dc4:	00 
f0100dc5:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100dcc:	e8 c3 f2 ff ff       	call   f0100094 <_panic>
f0100dd1:	8b 45 c0             	mov    -0x40(%ebp),%eax
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100dd4:	85 c9                	test   %ecx,%ecx
f0100dd6:	75 20                	jne    f0100df8 <mem_init+0x475>
		panic("'pages' is a null pointer!");
f0100dd8:	c7 44 24 08 3a 25 10 	movl   $0xf010253a,0x8(%esp)
f0100ddf:	f0 
f0100de0:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
f0100de7:	00 
f0100de8:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100def:	e8 a0 f2 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100df4:	8b 00                	mov    (%eax),%eax
f0100df6:	eb 00                	jmp    f0100df8 <mem_init+0x475>
f0100df8:	85 c0                	test   %eax,%eax
f0100dfa:	75 f8                	jne    f0100df4 <mem_init+0x471>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100dfc:	c7 44 24 0c 55 25 10 	movl   $0xf0102555,0xc(%esp)
f0100e03:	f0 
f0100e04:	c7 44 24 08 aa 24 10 	movl   $0xf01024aa,0x8(%esp)
f0100e0b:	f0 
f0100e0c:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0100e13:	00 
f0100e14:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100e1b:	e8 74 f2 ff ff       	call   f0100094 <_panic>

f0100e20 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e20:	55                   	push   %ebp
f0100e21:	89 e5                	mov    %esp,%ebp
        	if (alloc_flags & ALLOC_ZERO) 
            	memset(page2kva(ret), 0, PGSIZE);
        	return ret;
   	}*/
    	return NULL;
}
f0100e23:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e28:	5d                   	pop    %ebp
f0100e29:	c3                   	ret    

f0100e2a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e2a:	55                   	push   %ebp
f0100e2b:	89 e5                	mov    %esp,%ebp
f0100e2d:	83 ec 18             	sub    $0x18,%esp
f0100e30:	8b 45 08             	mov    0x8(%ebp),%eax
	if((pp->pp_ref == 0) && (pp->pp_link==NULL))
f0100e33:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e38:	75 14                	jne    f0100e4e <page_free+0x24>
f0100e3a:	83 38 00             	cmpl   $0x0,(%eax)
f0100e3d:	75 0f                	jne    f0100e4e <page_free+0x24>
	{
		pp->pp_link = page_free_list;							//page_free_list->pp_link = pp;
f0100e3f:	8b 15 3c 35 11 f0    	mov    0xf011353c,%edx
f0100e45:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;			//Inserting the free page in the beginning	
f0100e47:	a3 3c 35 11 f0       	mov    %eax,0xf011353c
f0100e4c:	eb 1c                	jmp    f0100e6a <page_free+0x40>
	}
	else
	{
		panic("The page is not free!");
f0100e4e:	c7 44 24 08 6b 25 10 	movl   $0xf010256b,0x8(%esp)
f0100e55:	f0 
f0100e56:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
f0100e5d:	00 
f0100e5e:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f0100e65:	e8 2a f2 ff ff       	call   f0100094 <_panic>
	}	
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100e6a:	c9                   	leave  
f0100e6b:	c3                   	ret    

f0100e6c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e6c:	55                   	push   %ebp
f0100e6d:	89 e5                	mov    %esp,%ebp
f0100e6f:	83 ec 18             	sub    $0x18,%esp
f0100e72:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100e75:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100e79:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100e7c:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100e80:	66 85 d2             	test   %dx,%dx
f0100e83:	75 08                	jne    f0100e8d <page_decref+0x21>
		page_free(pp);
f0100e85:	89 04 24             	mov    %eax,(%esp)
f0100e88:	e8 9d ff ff ff       	call   f0100e2a <page_free>
}
f0100e8d:	c9                   	leave  
f0100e8e:	c3                   	ret    

f0100e8f <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e8f:	55                   	push   %ebp
f0100e90:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100e92:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e97:	5d                   	pop    %ebp
f0100e98:	c3                   	ret    

f0100e99 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100e99:	55                   	push   %ebp
f0100e9a:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100e9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea1:	5d                   	pop    %ebp
f0100ea2:	c3                   	ret    

f0100ea3 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ea3:	55                   	push   %ebp
f0100ea4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ea6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eab:	5d                   	pop    %ebp
f0100eac:	c3                   	ret    

f0100ead <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ead:	55                   	push   %ebp
f0100eae:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100eb0:	5d                   	pop    %ebp
f0100eb1:	c3                   	ret    

f0100eb2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100eb2:	55                   	push   %ebp
f0100eb3:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eb8:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100ebb:	5d                   	pop    %ebp
f0100ebc:	c3                   	ret    

f0100ebd <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100ebd:	55                   	push   %ebp
f0100ebe:	89 e5                	mov    %esp,%ebp
f0100ec0:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100ec4:	ba 70 00 00 00       	mov    $0x70,%edx
f0100ec9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100eca:	b2 71                	mov    $0x71,%dl
f0100ecc:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100ecd:	0f b6 c0             	movzbl %al,%eax
}
f0100ed0:	5d                   	pop    %ebp
f0100ed1:	c3                   	ret    

f0100ed2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100ed2:	55                   	push   %ebp
f0100ed3:	89 e5                	mov    %esp,%ebp
f0100ed5:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100ed9:	ba 70 00 00 00       	mov    $0x70,%edx
f0100ede:	ee                   	out    %al,(%dx)
f0100edf:	b2 71                	mov    $0x71,%dl
f0100ee1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ee4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100ee5:	5d                   	pop    %ebp
f0100ee6:	c3                   	ret    

f0100ee7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ee7:	55                   	push   %ebp
f0100ee8:	89 e5                	mov    %esp,%ebp
f0100eea:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100eed:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ef0:	89 04 24             	mov    %eax,(%esp)
f0100ef3:	e8 f9 f6 ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0100ef8:	c9                   	leave  
f0100ef9:	c3                   	ret    

f0100efa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100efa:	55                   	push   %ebp
f0100efb:	89 e5                	mov    %esp,%ebp
f0100efd:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100f00:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100f07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f15:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f18:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f1c:	c7 04 24 e7 0e 10 f0 	movl   $0xf0100ee7,(%esp)
f0100f23:	e8 8c 04 00 00       	call   f01013b4 <vprintfmt>
	return cnt;
}
f0100f28:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f2b:	c9                   	leave  
f0100f2c:	c3                   	ret    

f0100f2d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100f2d:	55                   	push   %ebp
f0100f2e:	89 e5                	mov    %esp,%ebp
f0100f30:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100f33:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100f36:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f3d:	89 04 24             	mov    %eax,(%esp)
f0100f40:	e8 b5 ff ff ff       	call   f0100efa <vcprintf>
	va_end(ap);

	return cnt;
}
f0100f45:	c9                   	leave  
f0100f46:	c3                   	ret    

f0100f47 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void 
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100f47:	55                   	push   %ebp
f0100f48:	89 e5                	mov    %esp,%ebp
f0100f4a:	57                   	push   %edi
f0100f4b:	56                   	push   %esi
f0100f4c:	53                   	push   %ebx
f0100f4d:	83 ec 10             	sub    $0x10,%esp
f0100f50:	89 c6                	mov    %eax,%esi
f0100f52:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100f55:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f58:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100f5b:	8b 1a                	mov    (%edx),%ebx
f0100f5d:	8b 01                	mov    (%ecx),%eax
f0100f5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100f62:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100f69:	eb 77                	jmp    f0100fe2 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100f6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f6e:	01 d8                	add    %ebx,%eax
f0100f70:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100f75:	99                   	cltd   
f0100f76:	f7 f9                	idiv   %ecx
f0100f78:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100f7a:	eb 01                	jmp    f0100f7d <stab_binsearch+0x36>
			m--;
f0100f7c:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100f7d:	39 d9                	cmp    %ebx,%ecx
f0100f7f:	7c 1d                	jl     f0100f9e <stab_binsearch+0x57>
f0100f81:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100f84:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100f89:	39 fa                	cmp    %edi,%edx
f0100f8b:	75 ef                	jne    f0100f7c <stab_binsearch+0x35>
f0100f8d:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100f90:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100f93:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100f97:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100f9a:	73 18                	jae    f0100fb4 <stab_binsearch+0x6d>
f0100f9c:	eb 05                	jmp    f0100fa3 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100f9e:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100fa1:	eb 3f                	jmp    f0100fe2 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100fa3:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100fa6:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100fa8:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fab:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100fb2:	eb 2e                	jmp    f0100fe2 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100fb4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100fb7:	73 15                	jae    f0100fce <stab_binsearch+0x87>
			*region_right = m - 1;
f0100fb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100fbc:	48                   	dec    %eax
f0100fbd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100fc0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fc3:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fc5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100fcc:	eb 14                	jmp    f0100fe2 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100fce:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fd1:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100fd4:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100fd6:	ff 45 0c             	incl   0xc(%ebp)
f0100fd9:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fdb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100fe2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100fe5:	7e 84                	jle    f0100f6b <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100fe7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100feb:	75 0d                	jne    f0100ffa <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100fed:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ff0:	8b 00                	mov    (%eax),%eax
f0100ff2:	48                   	dec    %eax
f0100ff3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ff6:	89 07                	mov    %eax,(%edi)
f0100ff8:	eb 22                	jmp    f010101c <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ffd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100fff:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0101002:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101004:	eb 01                	jmp    f0101007 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101006:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101007:	39 c1                	cmp    %eax,%ecx
f0101009:	7d 0c                	jge    f0101017 <stab_binsearch+0xd0>
f010100b:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f010100e:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0101013:	39 fa                	cmp    %edi,%edx
f0101015:	75 ef                	jne    f0101006 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101017:	8b 7d e8             	mov    -0x18(%ebp),%edi
f010101a:	89 07                	mov    %eax,(%edi)
	}
}
f010101c:	83 c4 10             	add    $0x10,%esp
f010101f:	5b                   	pop    %ebx
f0101020:	5e                   	pop    %esi
f0101021:	5f                   	pop    %edi
f0101022:	5d                   	pop    %ebp
f0101023:	c3                   	ret    

f0101024 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101024:	55                   	push   %ebp
f0101025:	89 e5                	mov    %esp,%ebp
f0101027:	57                   	push   %edi
f0101028:	56                   	push   %esi
f0101029:	53                   	push   %ebx
f010102a:	83 ec 3c             	sub    $0x3c,%esp
f010102d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101030:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101033:	c7 03 04 27 10 f0    	movl   $0xf0102704,(%ebx)
	info->eip_line = 0;
f0101039:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101040:	c7 43 08 04 27 10 f0 	movl   $0xf0102704,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101047:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010104e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101051:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101058:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010105e:	76 12                	jbe    f0101072 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101060:	b8 e0 8a 10 f0       	mov    $0xf0108ae0,%eax
f0101065:	3d ad 6e 10 f0       	cmp    $0xf0106ead,%eax
f010106a:	0f 86 e7 01 00 00    	jbe    f0101257 <debuginfo_eip+0x233>
f0101070:	eb 1c                	jmp    f010108e <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101072:	c7 44 24 08 0e 27 10 	movl   $0xf010270e,0x8(%esp)
f0101079:	f0 
f010107a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0101081:	00 
f0101082:	c7 04 24 1b 27 10 f0 	movl   $0xf010271b,(%esp)
f0101089:	e8 06 f0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010108e:	80 3d df 8a 10 f0 00 	cmpb   $0x0,0xf0108adf
f0101095:	0f 85 c3 01 00 00    	jne    f010125e <debuginfo_eip+0x23a>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010109b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01010a2:	b8 ac 6e 10 f0       	mov    $0xf0106eac,%eax
f01010a7:	2d 70 29 10 f0       	sub    $0xf0102970,%eax
f01010ac:	c1 f8 02             	sar    $0x2,%eax
f01010af:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01010b5:	83 e8 01             	sub    $0x1,%eax
f01010b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01010bb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010bf:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01010c6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01010c9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01010cc:	b8 70 29 10 f0       	mov    $0xf0102970,%eax
f01010d1:	e8 71 fe ff ff       	call   f0100f47 <stab_binsearch>
	if (lfile == 0)
f01010d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010d9:	85 c0                	test   %eax,%eax
f01010db:	0f 84 84 01 00 00    	je     f0101265 <debuginfo_eip+0x241>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01010e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01010e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01010ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010ee:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01010f5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01010f8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01010fb:	b8 70 29 10 f0       	mov    $0xf0102970,%eax
f0101100:	e8 42 fe ff ff       	call   f0100f47 <stab_binsearch>

	if (lfun <= rfun) {
f0101105:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101108:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f010110b:	7f 6d                	jg     f010117a <debuginfo_eip+0x156>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		// .stab contains an array of fixed length structures, one struct per stab
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010110d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101110:	8d 90 70 29 10 f0    	lea    -0xfefd690(%eax),%edx
f0101116:	8b 80 70 29 10 f0    	mov    -0xfefd690(%eax),%eax
f010111c:	b9 e0 8a 10 f0       	mov    $0xf0108ae0,%ecx
f0101121:	81 e9 ad 6e 10 f0    	sub    $0xf0106ead,%ecx
f0101127:	39 c8                	cmp    %ecx,%eax
f0101129:	73 08                	jae    f0101133 <debuginfo_eip+0x10f>
		{
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010112b:	05 ad 6e 10 f0       	add    $0xf0106ead,%eax
f0101130:	89 43 08             	mov    %eax,0x8(%ebx)
			//cprintf("info->eip_fn_name%s,stabstr%s,stabs[lfun].n_strx%d\n",info->eip_fn_name,*stabstr,stabs[lfun].n_strx);
		}		
		info->eip_fn_addr = stabs[lfun].n_value;//info->eip_fn_addr have the addres of the function. 
f0101133:	8b 42 08             	mov    0x8(%edx),%eax
f0101136:	89 43 10             	mov    %eax,0x10(%ebx)
		cprintf("info->eip_fn_addr%x\n",info->eip_fn_addr);
f0101139:	89 44 24 04          	mov    %eax,0x4(%esp)
f010113d:	c7 04 24 29 27 10 f0 	movl   $0xf0102729,(%esp)
f0101144:	e8 e4 fd ff ff       	call   f0100f2d <cprintf>
		cprintf("addr_1%x\n",addr);//addr have the eip value.
f0101149:	89 74 24 04          	mov    %esi,0x4(%esp)
f010114d:	c7 04 24 3e 27 10 f0 	movl   $0xf010273e,(%esp)
f0101154:	e8 d4 fd ff ff       	call   f0100f2d <cprintf>
		addr -= info->eip_fn_addr;
f0101159:	2b 73 10             	sub    0x10(%ebx),%esi
		cprintf("addr_2%x\n",addr);
f010115c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101160:	c7 04 24 48 27 10 f0 	movl   $0xf0102748,(%esp)
f0101167:	e8 c1 fd ff ff       	call   f0100f2d <cprintf>
		// Search within the function definition for the line number.
		lline = lfun;
f010116c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010116f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101172:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101175:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101178:	eb 0f                	jmp    f0101189 <debuginfo_eip+0x165>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010117a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010117d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101180:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101183:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101186:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101189:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101190:	00 
f0101191:	8b 43 08             	mov    0x8(%ebx),%eax
f0101194:	89 04 24             	mov    %eax,(%esp)
f0101197:	e8 3f 09 00 00       	call   f0101adb <strfind>
f010119c:	2b 43 08             	sub    0x8(%ebx),%eax
f010119f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01011a2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011a6:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01011ad:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01011b0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01011b3:	b8 70 29 10 f0       	mov    $0xf0102970,%eax
f01011b8:	e8 8a fd ff ff       	call   f0100f47 <stab_binsearch>
	info->eip_line = stabs[lline].n_value;
f01011bd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01011c0:	6b c2 0c             	imul   $0xc,%edx,%eax
f01011c3:	05 70 29 10 f0       	add    $0xf0102970,%eax
f01011c8:	8b 48 08             	mov    0x8(%eax),%ecx
f01011cb:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01011ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01011d1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01011d4:	eb 06                	jmp    f01011dc <debuginfo_eip+0x1b8>
f01011d6:	83 ea 01             	sub    $0x1,%edx
f01011d9:	83 e8 0c             	sub    $0xc,%eax
f01011dc:	89 d6                	mov    %edx,%esi
f01011de:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f01011e1:	7f 33                	jg     f0101216 <debuginfo_eip+0x1f2>
	       && stabs[lline].n_type != N_SOL
f01011e3:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01011e7:	80 f9 84             	cmp    $0x84,%cl
f01011ea:	74 0b                	je     f01011f7 <debuginfo_eip+0x1d3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01011ec:	80 f9 64             	cmp    $0x64,%cl
f01011ef:	75 e5                	jne    f01011d6 <debuginfo_eip+0x1b2>
f01011f1:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01011f5:	74 df                	je     f01011d6 <debuginfo_eip+0x1b2>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01011f7:	6b f6 0c             	imul   $0xc,%esi,%esi
f01011fa:	8b 86 70 29 10 f0    	mov    -0xfefd690(%esi),%eax
f0101200:	ba e0 8a 10 f0       	mov    $0xf0108ae0,%edx
f0101205:	81 ea ad 6e 10 f0    	sub    $0xf0106ead,%edx
f010120b:	39 d0                	cmp    %edx,%eax
f010120d:	73 07                	jae    f0101216 <debuginfo_eip+0x1f2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010120f:	05 ad 6e 10 f0       	add    $0xf0106ead,%eax
f0101214:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101216:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101219:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010121c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101221:	39 ca                	cmp    %ecx,%edx
f0101223:	7d 4c                	jge    f0101271 <debuginfo_eip+0x24d>
		for (lline = lfun + 1;
f0101225:	8d 42 01             	lea    0x1(%edx),%eax
f0101228:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010122b:	89 c2                	mov    %eax,%edx
f010122d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101230:	05 70 29 10 f0       	add    $0xf0102970,%eax
f0101235:	89 ce                	mov    %ecx,%esi
f0101237:	eb 04                	jmp    f010123d <debuginfo_eip+0x219>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101239:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010123d:	39 d6                	cmp    %edx,%esi
f010123f:	7e 2b                	jle    f010126c <debuginfo_eip+0x248>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101241:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101245:	83 c2 01             	add    $0x1,%edx
f0101248:	83 c0 0c             	add    $0xc,%eax
f010124b:	80 f9 a0             	cmp    $0xa0,%cl
f010124e:	74 e9                	je     f0101239 <debuginfo_eip+0x215>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101250:	b8 00 00 00 00       	mov    $0x0,%eax
f0101255:	eb 1a                	jmp    f0101271 <debuginfo_eip+0x24d>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101257:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010125c:	eb 13                	jmp    f0101271 <debuginfo_eip+0x24d>
f010125e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101263:	eb 0c                	jmp    f0101271 <debuginfo_eip+0x24d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101265:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010126a:	eb 05                	jmp    f0101271 <debuginfo_eip+0x24d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010126c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101271:	83 c4 3c             	add    $0x3c,%esp
f0101274:	5b                   	pop    %ebx
f0101275:	5e                   	pop    %esi
f0101276:	5f                   	pop    %edi
f0101277:	5d                   	pop    %ebp
f0101278:	c3                   	ret    
f0101279:	66 90                	xchg   %ax,%ax
f010127b:	66 90                	xchg   %ax,%ax
f010127d:	66 90                	xchg   %ax,%ax
f010127f:	90                   	nop

f0101280 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101280:	55                   	push   %ebp
f0101281:	89 e5                	mov    %esp,%ebp
f0101283:	57                   	push   %edi
f0101284:	56                   	push   %esi
f0101285:	53                   	push   %ebx
f0101286:	83 ec 3c             	sub    $0x3c,%esp
f0101289:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010128c:	89 d7                	mov    %edx,%edi
f010128e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101291:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101294:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101297:	89 c3                	mov    %eax,%ebx
f0101299:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010129c:	8b 45 10             	mov    0x10(%ebp),%eax
f010129f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01012a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012aa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01012ad:	39 d9                	cmp    %ebx,%ecx
f01012af:	72 05                	jb     f01012b6 <printnum+0x36>
f01012b1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01012b4:	77 69                	ja     f010131f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01012b6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01012b9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01012bd:	83 ee 01             	sub    $0x1,%esi
f01012c0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01012c4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01012cc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01012d0:	89 c3                	mov    %eax,%ebx
f01012d2:	89 d6                	mov    %edx,%esi
f01012d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01012d7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01012da:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01012e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012e5:	89 04 24             	mov    %eax,(%esp)
f01012e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012ef:	e8 0c 0a 00 00       	call   f0101d00 <__udivdi3>
f01012f4:	89 d9                	mov    %ebx,%ecx
f01012f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01012fa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01012fe:	89 04 24             	mov    %eax,(%esp)
f0101301:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101305:	89 fa                	mov    %edi,%edx
f0101307:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010130a:	e8 71 ff ff ff       	call   f0101280 <printnum>
f010130f:	eb 1b                	jmp    f010132c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101311:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101315:	8b 45 18             	mov    0x18(%ebp),%eax
f0101318:	89 04 24             	mov    %eax,(%esp)
f010131b:	ff d3                	call   *%ebx
f010131d:	eb 03                	jmp    f0101322 <printnum+0xa2>
f010131f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101322:	83 ee 01             	sub    $0x1,%esi
f0101325:	85 f6                	test   %esi,%esi
f0101327:	7f e8                	jg     f0101311 <printnum+0x91>
f0101329:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010132c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101330:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101334:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101337:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010133a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010133e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101342:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101345:	89 04 24             	mov    %eax,(%esp)
f0101348:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010134b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010134f:	e8 dc 0a 00 00       	call   f0101e30 <__umoddi3>
f0101354:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101358:	0f be 80 52 27 10 f0 	movsbl -0xfefd8ae(%eax),%eax
f010135f:	89 04 24             	mov    %eax,(%esp)
f0101362:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101365:	ff d0                	call   *%eax
}
f0101367:	83 c4 3c             	add    $0x3c,%esp
f010136a:	5b                   	pop    %ebx
f010136b:	5e                   	pop    %esi
f010136c:	5f                   	pop    %edi
f010136d:	5d                   	pop    %ebp
f010136e:	c3                   	ret    

f010136f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010136f:	55                   	push   %ebp
f0101370:	89 e5                	mov    %esp,%ebp
f0101372:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101375:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101379:	8b 10                	mov    (%eax),%edx
f010137b:	3b 50 04             	cmp    0x4(%eax),%edx
f010137e:	73 0a                	jae    f010138a <sprintputch+0x1b>
		*b->buf++ = ch;
f0101380:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101383:	89 08                	mov    %ecx,(%eax)
f0101385:	8b 45 08             	mov    0x8(%ebp),%eax
f0101388:	88 02                	mov    %al,(%edx)
}
f010138a:	5d                   	pop    %ebp
f010138b:	c3                   	ret    

f010138c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010138c:	55                   	push   %ebp
f010138d:	89 e5                	mov    %esp,%ebp
f010138f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101392:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101395:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101399:	8b 45 10             	mov    0x10(%ebp),%eax
f010139c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01013aa:	89 04 24             	mov    %eax,(%esp)
f01013ad:	e8 02 00 00 00       	call   f01013b4 <vprintfmt>
	va_end(ap);
}
f01013b2:	c9                   	leave  
f01013b3:	c3                   	ret    

f01013b4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01013b4:	55                   	push   %ebp
f01013b5:	89 e5                	mov    %esp,%ebp
f01013b7:	57                   	push   %edi
f01013b8:	56                   	push   %esi
f01013b9:	53                   	push   %ebx
f01013ba:	83 ec 3c             	sub    $0x3c,%esp
f01013bd:	8b 75 08             	mov    0x8(%ebp),%esi
f01013c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013c3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01013c6:	eb 11                	jmp    f01013d9 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01013c8:	85 c0                	test   %eax,%eax
f01013ca:	0f 84 48 04 00 00    	je     f0101818 <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f01013d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013d4:	89 04 24             	mov    %eax,(%esp)
f01013d7:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01013d9:	83 c7 01             	add    $0x1,%edi
f01013dc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01013e0:	83 f8 25             	cmp    $0x25,%eax
f01013e3:	75 e3                	jne    f01013c8 <vprintfmt+0x14>
f01013e5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01013e9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01013f0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01013f7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01013fe:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101403:	eb 1f                	jmp    f0101424 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101405:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101408:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f010140c:	eb 16                	jmp    f0101424 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010140e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101411:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101415:	eb 0d                	jmp    f0101424 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101417:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010141a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010141d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101424:	8d 47 01             	lea    0x1(%edi),%eax
f0101427:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010142a:	0f b6 17             	movzbl (%edi),%edx
f010142d:	0f b6 c2             	movzbl %dl,%eax
f0101430:	83 ea 23             	sub    $0x23,%edx
f0101433:	80 fa 55             	cmp    $0x55,%dl
f0101436:	0f 87 bf 03 00 00    	ja     f01017fb <vprintfmt+0x447>
f010143c:	0f b6 d2             	movzbl %dl,%edx
f010143f:	ff 24 95 e0 27 10 f0 	jmp    *-0xfefd820(,%edx,4)
f0101446:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101449:	ba 00 00 00 00       	mov    $0x0,%edx
f010144e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101451:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0101454:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0101458:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f010145b:	8d 48 d0             	lea    -0x30(%eax),%ecx
f010145e:	83 f9 09             	cmp    $0x9,%ecx
f0101461:	77 3c                	ja     f010149f <vprintfmt+0xeb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101463:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101466:	eb e9                	jmp    f0101451 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101468:	8b 45 14             	mov    0x14(%ebp),%eax
f010146b:	8b 00                	mov    (%eax),%eax
f010146d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101470:	8b 45 14             	mov    0x14(%ebp),%eax
f0101473:	8d 40 04             	lea    0x4(%eax),%eax
f0101476:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101479:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010147c:	eb 27                	jmp    f01014a5 <vprintfmt+0xf1>
f010147e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101481:	85 d2                	test   %edx,%edx
f0101483:	b8 00 00 00 00       	mov    $0x0,%eax
f0101488:	0f 49 c2             	cmovns %edx,%eax
f010148b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010148e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101491:	eb 91                	jmp    f0101424 <vprintfmt+0x70>
f0101493:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101496:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010149d:	eb 85                	jmp    f0101424 <vprintfmt+0x70>
f010149f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01014a2:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01014a5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01014a9:	0f 89 75 ff ff ff    	jns    f0101424 <vprintfmt+0x70>
f01014af:	e9 63 ff ff ff       	jmp    f0101417 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01014b4:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01014ba:	e9 65 ff ff ff       	jmp    f0101424 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014bf:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01014c2:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f01014c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014ca:	8b 00                	mov    (%eax),%eax
f01014cc:	89 04 24             	mov    %eax,(%esp)
f01014cf:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01014d4:	e9 00 ff ff ff       	jmp    f01013d9 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014d9:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01014dc:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f01014e0:	8b 00                	mov    (%eax),%eax
f01014e2:	99                   	cltd   
f01014e3:	31 d0                	xor    %edx,%eax
f01014e5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01014e7:	83 f8 07             	cmp    $0x7,%eax
f01014ea:	7f 0b                	jg     f01014f7 <vprintfmt+0x143>
f01014ec:	8b 14 85 40 29 10 f0 	mov    -0xfefd6c0(,%eax,4),%edx
f01014f3:	85 d2                	test   %edx,%edx
f01014f5:	75 20                	jne    f0101517 <vprintfmt+0x163>
				printfmt(putch, putdat, "error %d", err);
f01014f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014fb:	c7 44 24 08 6a 27 10 	movl   $0xf010276a,0x8(%esp)
f0101502:	f0 
f0101503:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101507:	89 34 24             	mov    %esi,(%esp)
f010150a:	e8 7d fe ff ff       	call   f010138c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010150f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101512:	e9 c2 fe ff ff       	jmp    f01013d9 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101517:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010151b:	c7 44 24 08 bc 24 10 	movl   $0xf01024bc,0x8(%esp)
f0101522:	f0 
f0101523:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101527:	89 34 24             	mov    %esi,(%esp)
f010152a:	e8 5d fe ff ff       	call   f010138c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010152f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101532:	e9 a2 fe ff ff       	jmp    f01013d9 <vprintfmt+0x25>
f0101537:	8b 45 14             	mov    0x14(%ebp),%eax
f010153a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010153d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101540:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101543:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101547:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101549:	85 ff                	test   %edi,%edi
f010154b:	b8 63 27 10 f0       	mov    $0xf0102763,%eax
f0101550:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101553:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101557:	0f 84 92 00 00 00    	je     f01015ef <vprintfmt+0x23b>
f010155d:	85 c9                	test   %ecx,%ecx
f010155f:	0f 8e 98 00 00 00    	jle    f01015fd <vprintfmt+0x249>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101565:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101569:	89 3c 24             	mov    %edi,(%esp)
f010156c:	e8 17 04 00 00       	call   f0101988 <strnlen>
f0101571:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101574:	29 c1                	sub    %eax,%ecx
f0101576:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0101579:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010157d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101580:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101583:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101585:	eb 0f                	jmp    f0101596 <vprintfmt+0x1e2>
					putch(padc, putdat);
f0101587:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010158b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010158e:	89 04 24             	mov    %eax,(%esp)
f0101591:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101593:	83 ef 01             	sub    $0x1,%edi
f0101596:	85 ff                	test   %edi,%edi
f0101598:	7f ed                	jg     f0101587 <vprintfmt+0x1d3>
f010159a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010159d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01015a0:	85 c9                	test   %ecx,%ecx
f01015a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01015a7:	0f 49 c1             	cmovns %ecx,%eax
f01015aa:	29 c1                	sub    %eax,%ecx
f01015ac:	89 75 08             	mov    %esi,0x8(%ebp)
f01015af:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01015b2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01015b5:	89 cb                	mov    %ecx,%ebx
f01015b7:	eb 50                	jmp    f0101609 <vprintfmt+0x255>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01015b9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01015bd:	74 1e                	je     f01015dd <vprintfmt+0x229>
f01015bf:	0f be d2             	movsbl %dl,%edx
f01015c2:	83 ea 20             	sub    $0x20,%edx
f01015c5:	83 fa 5e             	cmp    $0x5e,%edx
f01015c8:	76 13                	jbe    f01015dd <vprintfmt+0x229>
					putch('?', putdat);
f01015ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015d1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01015d8:	ff 55 08             	call   *0x8(%ebp)
f01015db:	eb 0d                	jmp    f01015ea <vprintfmt+0x236>
				else
					putch(ch, putdat);
f01015dd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015e0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01015e4:	89 04 24             	mov    %eax,(%esp)
f01015e7:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01015ea:	83 eb 01             	sub    $0x1,%ebx
f01015ed:	eb 1a                	jmp    f0101609 <vprintfmt+0x255>
f01015ef:	89 75 08             	mov    %esi,0x8(%ebp)
f01015f2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01015f5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01015f8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01015fb:	eb 0c                	jmp    f0101609 <vprintfmt+0x255>
f01015fd:	89 75 08             	mov    %esi,0x8(%ebp)
f0101600:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101603:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101606:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101609:	83 c7 01             	add    $0x1,%edi
f010160c:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101610:	0f be c2             	movsbl %dl,%eax
f0101613:	85 c0                	test   %eax,%eax
f0101615:	74 25                	je     f010163c <vprintfmt+0x288>
f0101617:	85 f6                	test   %esi,%esi
f0101619:	78 9e                	js     f01015b9 <vprintfmt+0x205>
f010161b:	83 ee 01             	sub    $0x1,%esi
f010161e:	79 99                	jns    f01015b9 <vprintfmt+0x205>
f0101620:	89 df                	mov    %ebx,%edi
f0101622:	8b 75 08             	mov    0x8(%ebp),%esi
f0101625:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101628:	eb 1a                	jmp    f0101644 <vprintfmt+0x290>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010162a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010162e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101635:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101637:	83 ef 01             	sub    $0x1,%edi
f010163a:	eb 08                	jmp    f0101644 <vprintfmt+0x290>
f010163c:	89 df                	mov    %ebx,%edi
f010163e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101641:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101644:	85 ff                	test   %edi,%edi
f0101646:	7f e2                	jg     f010162a <vprintfmt+0x276>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101648:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010164b:	e9 89 fd ff ff       	jmp    f01013d9 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101650:	83 f9 01             	cmp    $0x1,%ecx
f0101653:	7e 19                	jle    f010166e <vprintfmt+0x2ba>
		return va_arg(*ap, long long);
f0101655:	8b 45 14             	mov    0x14(%ebp),%eax
f0101658:	8b 50 04             	mov    0x4(%eax),%edx
f010165b:	8b 00                	mov    (%eax),%eax
f010165d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101660:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101663:	8b 45 14             	mov    0x14(%ebp),%eax
f0101666:	8d 40 08             	lea    0x8(%eax),%eax
f0101669:	89 45 14             	mov    %eax,0x14(%ebp)
f010166c:	eb 38                	jmp    f01016a6 <vprintfmt+0x2f2>
	else if (lflag)
f010166e:	85 c9                	test   %ecx,%ecx
f0101670:	74 1b                	je     f010168d <vprintfmt+0x2d9>
		return va_arg(*ap, long);
f0101672:	8b 45 14             	mov    0x14(%ebp),%eax
f0101675:	8b 00                	mov    (%eax),%eax
f0101677:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010167a:	89 c1                	mov    %eax,%ecx
f010167c:	c1 f9 1f             	sar    $0x1f,%ecx
f010167f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101682:	8b 45 14             	mov    0x14(%ebp),%eax
f0101685:	8d 40 04             	lea    0x4(%eax),%eax
f0101688:	89 45 14             	mov    %eax,0x14(%ebp)
f010168b:	eb 19                	jmp    f01016a6 <vprintfmt+0x2f2>
	else
		return va_arg(*ap, int);
f010168d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101690:	8b 00                	mov    (%eax),%eax
f0101692:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101695:	89 c1                	mov    %eax,%ecx
f0101697:	c1 f9 1f             	sar    $0x1f,%ecx
f010169a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010169d:	8b 45 14             	mov    0x14(%ebp),%eax
f01016a0:	8d 40 04             	lea    0x4(%eax),%eax
f01016a3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01016a6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01016a9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01016ac:	bf 0a 00 00 00       	mov    $0xa,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01016b1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01016b5:	0f 89 04 01 00 00    	jns    f01017bf <vprintfmt+0x40b>
				putch('-', putdat);
f01016bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016bf:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01016c6:	ff d6                	call   *%esi
				num = -(long long) num;
f01016c8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01016cb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01016ce:	f7 da                	neg    %edx
f01016d0:	83 d1 00             	adc    $0x0,%ecx
f01016d3:	f7 d9                	neg    %ecx
f01016d5:	e9 e5 00 00 00       	jmp    f01017bf <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01016da:	83 f9 01             	cmp    $0x1,%ecx
f01016dd:	7e 10                	jle    f01016ef <vprintfmt+0x33b>
		return va_arg(*ap, unsigned long long);
f01016df:	8b 45 14             	mov    0x14(%ebp),%eax
f01016e2:	8b 10                	mov    (%eax),%edx
f01016e4:	8b 48 04             	mov    0x4(%eax),%ecx
f01016e7:	8d 40 08             	lea    0x8(%eax),%eax
f01016ea:	89 45 14             	mov    %eax,0x14(%ebp)
f01016ed:	eb 26                	jmp    f0101715 <vprintfmt+0x361>
	else if (lflag)
f01016ef:	85 c9                	test   %ecx,%ecx
f01016f1:	74 12                	je     f0101705 <vprintfmt+0x351>
		return va_arg(*ap, unsigned long);
f01016f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01016f6:	8b 10                	mov    (%eax),%edx
f01016f8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01016fd:	8d 40 04             	lea    0x4(%eax),%eax
f0101700:	89 45 14             	mov    %eax,0x14(%ebp)
f0101703:	eb 10                	jmp    f0101715 <vprintfmt+0x361>
	else
		return va_arg(*ap, unsigned int);
f0101705:	8b 45 14             	mov    0x14(%ebp),%eax
f0101708:	8b 10                	mov    (%eax),%edx
f010170a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010170f:	8d 40 04             	lea    0x4(%eax),%eax
f0101712:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101715:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f010171a:	e9 a0 00 00 00       	jmp    f01017bf <vprintfmt+0x40b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010171f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101723:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010172a:	ff d6                	call   *%esi
			putch('X', putdat);
f010172c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101730:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101737:	ff d6                	call   *%esi
			putch('X', putdat);
f0101739:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010173d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101744:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101746:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101749:	e9 8b fc ff ff       	jmp    f01013d9 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010174e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101752:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101759:	ff d6                	call   *%esi
			putch('x', putdat);
f010175b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010175f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101766:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101768:	8b 45 14             	mov    0x14(%ebp),%eax
f010176b:	8b 10                	mov    (%eax),%edx
f010176d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101772:	8d 40 04             	lea    0x4(%eax),%eax
f0101775:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101778:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f010177d:	eb 40                	jmp    f01017bf <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010177f:	83 f9 01             	cmp    $0x1,%ecx
f0101782:	7e 10                	jle    f0101794 <vprintfmt+0x3e0>
		return va_arg(*ap, unsigned long long);
f0101784:	8b 45 14             	mov    0x14(%ebp),%eax
f0101787:	8b 10                	mov    (%eax),%edx
f0101789:	8b 48 04             	mov    0x4(%eax),%ecx
f010178c:	8d 40 08             	lea    0x8(%eax),%eax
f010178f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101792:	eb 26                	jmp    f01017ba <vprintfmt+0x406>
	else if (lflag)
f0101794:	85 c9                	test   %ecx,%ecx
f0101796:	74 12                	je     f01017aa <vprintfmt+0x3f6>
		return va_arg(*ap, unsigned long);
f0101798:	8b 45 14             	mov    0x14(%ebp),%eax
f010179b:	8b 10                	mov    (%eax),%edx
f010179d:	b9 00 00 00 00       	mov    $0x0,%ecx
f01017a2:	8d 40 04             	lea    0x4(%eax),%eax
f01017a5:	89 45 14             	mov    %eax,0x14(%ebp)
f01017a8:	eb 10                	jmp    f01017ba <vprintfmt+0x406>
	else
		return va_arg(*ap, unsigned int);
f01017aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01017ad:	8b 10                	mov    (%eax),%edx
f01017af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01017b4:	8d 40 04             	lea    0x4(%eax),%eax
f01017b7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01017ba:	bf 10 00 00 00       	mov    $0x10,%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
f01017bf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01017c3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01017c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017d2:	89 14 24             	mov    %edx,(%esp)
f01017d5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01017d9:	89 da                	mov    %ebx,%edx
f01017db:	89 f0                	mov    %esi,%eax
f01017dd:	e8 9e fa ff ff       	call   f0101280 <printnum>
			break;
f01017e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01017e5:	e9 ef fb ff ff       	jmp    f01013d9 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01017ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017ee:	89 04 24             	mov    %eax,(%esp)
f01017f1:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01017f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01017f6:	e9 de fb ff ff       	jmp    f01013d9 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01017fb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017ff:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101806:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101808:	eb 03                	jmp    f010180d <vprintfmt+0x459>
f010180a:	83 ef 01             	sub    $0x1,%edi
f010180d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101811:	75 f7                	jne    f010180a <vprintfmt+0x456>
f0101813:	e9 c1 fb ff ff       	jmp    f01013d9 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101818:	83 c4 3c             	add    $0x3c,%esp
f010181b:	5b                   	pop    %ebx
f010181c:	5e                   	pop    %esi
f010181d:	5f                   	pop    %edi
f010181e:	5d                   	pop    %ebp
f010181f:	c3                   	ret    

f0101820 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101820:	55                   	push   %ebp
f0101821:	89 e5                	mov    %esp,%ebp
f0101823:	83 ec 28             	sub    $0x28,%esp
f0101826:	8b 45 08             	mov    0x8(%ebp),%eax
f0101829:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010182c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010182f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101833:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101836:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010183d:	85 c0                	test   %eax,%eax
f010183f:	74 30                	je     f0101871 <vsnprintf+0x51>
f0101841:	85 d2                	test   %edx,%edx
f0101843:	7e 2c                	jle    f0101871 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101845:	8b 45 14             	mov    0x14(%ebp),%eax
f0101848:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010184c:	8b 45 10             	mov    0x10(%ebp),%eax
f010184f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101853:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101856:	89 44 24 04          	mov    %eax,0x4(%esp)
f010185a:	c7 04 24 6f 13 10 f0 	movl   $0xf010136f,(%esp)
f0101861:	e8 4e fb ff ff       	call   f01013b4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101866:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101869:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010186c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010186f:	eb 05                	jmp    f0101876 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101871:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101876:	c9                   	leave  
f0101877:	c3                   	ret    

f0101878 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101878:	55                   	push   %ebp
f0101879:	89 e5                	mov    %esp,%ebp
f010187b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010187e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101881:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101885:	8b 45 10             	mov    0x10(%ebp),%eax
f0101888:	89 44 24 08          	mov    %eax,0x8(%esp)
f010188c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010188f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101893:	8b 45 08             	mov    0x8(%ebp),%eax
f0101896:	89 04 24             	mov    %eax,(%esp)
f0101899:	e8 82 ff ff ff       	call   f0101820 <vsnprintf>
	va_end(ap);

	return rc;
}
f010189e:	c9                   	leave  
f010189f:	c3                   	ret    

f01018a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01018a0:	55                   	push   %ebp
f01018a1:	89 e5                	mov    %esp,%ebp
f01018a3:	57                   	push   %edi
f01018a4:	56                   	push   %esi
f01018a5:	53                   	push   %ebx
f01018a6:	83 ec 1c             	sub    $0x1c,%esp
f01018a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01018ac:	85 c0                	test   %eax,%eax
f01018ae:	74 10                	je     f01018c0 <readline+0x20>
		cprintf("%s", prompt);
f01018b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018b4:	c7 04 24 bc 24 10 f0 	movl   $0xf01024bc,(%esp)
f01018bb:	e8 6d f6 ff ff       	call   f0100f2d <cprintf>

	i = 0;
	echoing = iscons(0);
f01018c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018c7:	e8 46 ed ff ff       	call   f0100612 <iscons>
f01018cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01018ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01018d3:	e8 29 ed ff ff       	call   f0100601 <getchar>
f01018d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01018da:	85 c0                	test   %eax,%eax
f01018dc:	79 17                	jns    f01018f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01018de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018e2:	c7 04 24 60 29 10 f0 	movl   $0xf0102960,(%esp)
f01018e9:	e8 3f f6 ff ff       	call   f0100f2d <cprintf>
			return NULL;
f01018ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01018f3:	eb 6d                	jmp    f0101962 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01018f5:	83 f8 7f             	cmp    $0x7f,%eax
f01018f8:	74 05                	je     f01018ff <readline+0x5f>
f01018fa:	83 f8 08             	cmp    $0x8,%eax
f01018fd:	75 19                	jne    f0101918 <readline+0x78>
f01018ff:	85 f6                	test   %esi,%esi
f0101901:	7e 15                	jle    f0101918 <readline+0x78>
			if (echoing)
f0101903:	85 ff                	test   %edi,%edi
f0101905:	74 0c                	je     f0101913 <readline+0x73>
				cputchar('\b');
f0101907:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010190e:	e8 de ec ff ff       	call   f01005f1 <cputchar>
			i--;
f0101913:	83 ee 01             	sub    $0x1,%esi
f0101916:	eb bb                	jmp    f01018d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101918:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010191e:	7f 1c                	jg     f010193c <readline+0x9c>
f0101920:	83 fb 1f             	cmp    $0x1f,%ebx
f0101923:	7e 17                	jle    f010193c <readline+0x9c>
			if (echoing)
f0101925:	85 ff                	test   %edi,%edi
f0101927:	74 08                	je     f0101931 <readline+0x91>
				cputchar(c);
f0101929:	89 1c 24             	mov    %ebx,(%esp)
f010192c:	e8 c0 ec ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0101931:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101937:	8d 76 01             	lea    0x1(%esi),%esi
f010193a:	eb 97                	jmp    f01018d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010193c:	83 fb 0d             	cmp    $0xd,%ebx
f010193f:	74 05                	je     f0101946 <readline+0xa6>
f0101941:	83 fb 0a             	cmp    $0xa,%ebx
f0101944:	75 8d                	jne    f01018d3 <readline+0x33>
			if (echoing)
f0101946:	85 ff                	test   %edi,%edi
f0101948:	74 0c                	je     f0101956 <readline+0xb6>
				cputchar('\n');
f010194a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101951:	e8 9b ec ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0101956:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010195d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101962:	83 c4 1c             	add    $0x1c,%esp
f0101965:	5b                   	pop    %ebx
f0101966:	5e                   	pop    %esi
f0101967:	5f                   	pop    %edi
f0101968:	5d                   	pop    %ebp
f0101969:	c3                   	ret    
f010196a:	66 90                	xchg   %ax,%ax
f010196c:	66 90                	xchg   %ax,%ax
f010196e:	66 90                	xchg   %ax,%ax

f0101970 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101970:	55                   	push   %ebp
f0101971:	89 e5                	mov    %esp,%ebp
f0101973:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101976:	b8 00 00 00 00       	mov    $0x0,%eax
f010197b:	eb 03                	jmp    f0101980 <strlen+0x10>
		n++;
f010197d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101980:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101984:	75 f7                	jne    f010197d <strlen+0xd>
		n++;
	return n;
}
f0101986:	5d                   	pop    %ebp
f0101987:	c3                   	ret    

f0101988 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101988:	55                   	push   %ebp
f0101989:	89 e5                	mov    %esp,%ebp
f010198b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010198e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101991:	b8 00 00 00 00       	mov    $0x0,%eax
f0101996:	eb 03                	jmp    f010199b <strnlen+0x13>
		n++;
f0101998:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010199b:	39 d0                	cmp    %edx,%eax
f010199d:	74 06                	je     f01019a5 <strnlen+0x1d>
f010199f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01019a3:	75 f3                	jne    f0101998 <strnlen+0x10>
		n++;
	return n;
}
f01019a5:	5d                   	pop    %ebp
f01019a6:	c3                   	ret    

f01019a7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01019a7:	55                   	push   %ebp
f01019a8:	89 e5                	mov    %esp,%ebp
f01019aa:	53                   	push   %ebx
f01019ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01019ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01019b1:	89 c2                	mov    %eax,%edx
f01019b3:	83 c2 01             	add    $0x1,%edx
f01019b6:	83 c1 01             	add    $0x1,%ecx
f01019b9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01019bd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01019c0:	84 db                	test   %bl,%bl
f01019c2:	75 ef                	jne    f01019b3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01019c4:	5b                   	pop    %ebx
f01019c5:	5d                   	pop    %ebp
f01019c6:	c3                   	ret    

f01019c7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01019c7:	55                   	push   %ebp
f01019c8:	89 e5                	mov    %esp,%ebp
f01019ca:	53                   	push   %ebx
f01019cb:	83 ec 08             	sub    $0x8,%esp
f01019ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01019d1:	89 1c 24             	mov    %ebx,(%esp)
f01019d4:	e8 97 ff ff ff       	call   f0101970 <strlen>
	strcpy(dst + len, src);
f01019d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019dc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01019e0:	01 d8                	add    %ebx,%eax
f01019e2:	89 04 24             	mov    %eax,(%esp)
f01019e5:	e8 bd ff ff ff       	call   f01019a7 <strcpy>
	return dst;
}
f01019ea:	89 d8                	mov    %ebx,%eax
f01019ec:	83 c4 08             	add    $0x8,%esp
f01019ef:	5b                   	pop    %ebx
f01019f0:	5d                   	pop    %ebp
f01019f1:	c3                   	ret    

f01019f2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01019f2:	55                   	push   %ebp
f01019f3:	89 e5                	mov    %esp,%ebp
f01019f5:	56                   	push   %esi
f01019f6:	53                   	push   %ebx
f01019f7:	8b 75 08             	mov    0x8(%ebp),%esi
f01019fa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01019fd:	89 f3                	mov    %esi,%ebx
f01019ff:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101a02:	89 f2                	mov    %esi,%edx
f0101a04:	eb 0f                	jmp    f0101a15 <strncpy+0x23>
		*dst++ = *src;
f0101a06:	83 c2 01             	add    $0x1,%edx
f0101a09:	0f b6 01             	movzbl (%ecx),%eax
f0101a0c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101a0f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101a12:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101a15:	39 da                	cmp    %ebx,%edx
f0101a17:	75 ed                	jne    f0101a06 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101a19:	89 f0                	mov    %esi,%eax
f0101a1b:	5b                   	pop    %ebx
f0101a1c:	5e                   	pop    %esi
f0101a1d:	5d                   	pop    %ebp
f0101a1e:	c3                   	ret    

f0101a1f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101a1f:	55                   	push   %ebp
f0101a20:	89 e5                	mov    %esp,%ebp
f0101a22:	56                   	push   %esi
f0101a23:	53                   	push   %ebx
f0101a24:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a27:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a2a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101a2d:	89 f0                	mov    %esi,%eax
f0101a2f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101a33:	85 c9                	test   %ecx,%ecx
f0101a35:	75 0b                	jne    f0101a42 <strlcpy+0x23>
f0101a37:	eb 1d                	jmp    f0101a56 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101a39:	83 c0 01             	add    $0x1,%eax
f0101a3c:	83 c2 01             	add    $0x1,%edx
f0101a3f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101a42:	39 d8                	cmp    %ebx,%eax
f0101a44:	74 0b                	je     f0101a51 <strlcpy+0x32>
f0101a46:	0f b6 0a             	movzbl (%edx),%ecx
f0101a49:	84 c9                	test   %cl,%cl
f0101a4b:	75 ec                	jne    f0101a39 <strlcpy+0x1a>
f0101a4d:	89 c2                	mov    %eax,%edx
f0101a4f:	eb 02                	jmp    f0101a53 <strlcpy+0x34>
f0101a51:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101a53:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101a56:	29 f0                	sub    %esi,%eax
}
f0101a58:	5b                   	pop    %ebx
f0101a59:	5e                   	pop    %esi
f0101a5a:	5d                   	pop    %ebp
f0101a5b:	c3                   	ret    

f0101a5c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101a5c:	55                   	push   %ebp
f0101a5d:	89 e5                	mov    %esp,%ebp
f0101a5f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101a62:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101a65:	eb 06                	jmp    f0101a6d <strcmp+0x11>
		p++, q++;
f0101a67:	83 c1 01             	add    $0x1,%ecx
f0101a6a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101a6d:	0f b6 01             	movzbl (%ecx),%eax
f0101a70:	84 c0                	test   %al,%al
f0101a72:	74 04                	je     f0101a78 <strcmp+0x1c>
f0101a74:	3a 02                	cmp    (%edx),%al
f0101a76:	74 ef                	je     f0101a67 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a78:	0f b6 c0             	movzbl %al,%eax
f0101a7b:	0f b6 12             	movzbl (%edx),%edx
f0101a7e:	29 d0                	sub    %edx,%eax
}
f0101a80:	5d                   	pop    %ebp
f0101a81:	c3                   	ret    

f0101a82 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101a82:	55                   	push   %ebp
f0101a83:	89 e5                	mov    %esp,%ebp
f0101a85:	53                   	push   %ebx
f0101a86:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101a8c:	89 c3                	mov    %eax,%ebx
f0101a8e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101a91:	eb 06                	jmp    f0101a99 <strncmp+0x17>
		n--, p++, q++;
f0101a93:	83 c0 01             	add    $0x1,%eax
f0101a96:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101a99:	39 d8                	cmp    %ebx,%eax
f0101a9b:	74 15                	je     f0101ab2 <strncmp+0x30>
f0101a9d:	0f b6 08             	movzbl (%eax),%ecx
f0101aa0:	84 c9                	test   %cl,%cl
f0101aa2:	74 04                	je     f0101aa8 <strncmp+0x26>
f0101aa4:	3a 0a                	cmp    (%edx),%cl
f0101aa6:	74 eb                	je     f0101a93 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101aa8:	0f b6 00             	movzbl (%eax),%eax
f0101aab:	0f b6 12             	movzbl (%edx),%edx
f0101aae:	29 d0                	sub    %edx,%eax
f0101ab0:	eb 05                	jmp    f0101ab7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101ab2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101ab7:	5b                   	pop    %ebx
f0101ab8:	5d                   	pop    %ebp
f0101ab9:	c3                   	ret    

f0101aba <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101aba:	55                   	push   %ebp
f0101abb:	89 e5                	mov    %esp,%ebp
f0101abd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ac0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101ac4:	eb 07                	jmp    f0101acd <strchr+0x13>
		if (*s == c)
f0101ac6:	38 ca                	cmp    %cl,%dl
f0101ac8:	74 0f                	je     f0101ad9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101aca:	83 c0 01             	add    $0x1,%eax
f0101acd:	0f b6 10             	movzbl (%eax),%edx
f0101ad0:	84 d2                	test   %dl,%dl
f0101ad2:	75 f2                	jne    f0101ac6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101ad4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ad9:	5d                   	pop    %ebp
f0101ada:	c3                   	ret    

f0101adb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101adb:	55                   	push   %ebp
f0101adc:	89 e5                	mov    %esp,%ebp
f0101ade:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ae1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101ae5:	eb 07                	jmp    f0101aee <strfind+0x13>
		if (*s == c)
f0101ae7:	38 ca                	cmp    %cl,%dl
f0101ae9:	74 0a                	je     f0101af5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101aeb:	83 c0 01             	add    $0x1,%eax
f0101aee:	0f b6 10             	movzbl (%eax),%edx
f0101af1:	84 d2                	test   %dl,%dl
f0101af3:	75 f2                	jne    f0101ae7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101af5:	5d                   	pop    %ebp
f0101af6:	c3                   	ret    

f0101af7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101af7:	55                   	push   %ebp
f0101af8:	89 e5                	mov    %esp,%ebp
f0101afa:	57                   	push   %edi
f0101afb:	56                   	push   %esi
f0101afc:	53                   	push   %ebx
f0101afd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101b00:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101b03:	85 c9                	test   %ecx,%ecx
f0101b05:	74 36                	je     f0101b3d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101b07:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101b0d:	75 28                	jne    f0101b37 <memset+0x40>
f0101b0f:	f6 c1 03             	test   $0x3,%cl
f0101b12:	75 23                	jne    f0101b37 <memset+0x40>
		c &= 0xFF;
f0101b14:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101b18:	89 d3                	mov    %edx,%ebx
f0101b1a:	c1 e3 08             	shl    $0x8,%ebx
f0101b1d:	89 d6                	mov    %edx,%esi
f0101b1f:	c1 e6 18             	shl    $0x18,%esi
f0101b22:	89 d0                	mov    %edx,%eax
f0101b24:	c1 e0 10             	shl    $0x10,%eax
f0101b27:	09 f0                	or     %esi,%eax
f0101b29:	09 c2                	or     %eax,%edx
f0101b2b:	89 d0                	mov    %edx,%eax
f0101b2d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101b2f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101b32:	fc                   	cld    
f0101b33:	f3 ab                	rep stos %eax,%es:(%edi)
f0101b35:	eb 06                	jmp    f0101b3d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101b37:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b3a:	fc                   	cld    
f0101b3b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101b3d:	89 f8                	mov    %edi,%eax
f0101b3f:	5b                   	pop    %ebx
f0101b40:	5e                   	pop    %esi
f0101b41:	5f                   	pop    %edi
f0101b42:	5d                   	pop    %ebp
f0101b43:	c3                   	ret    

f0101b44 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101b44:	55                   	push   %ebp
f0101b45:	89 e5                	mov    %esp,%ebp
f0101b47:	57                   	push   %edi
f0101b48:	56                   	push   %esi
f0101b49:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b4c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b4f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101b52:	39 c6                	cmp    %eax,%esi
f0101b54:	73 35                	jae    f0101b8b <memmove+0x47>
f0101b56:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101b59:	39 d0                	cmp    %edx,%eax
f0101b5b:	73 2e                	jae    f0101b8b <memmove+0x47>
		s += n;
		d += n;
f0101b5d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101b60:	89 d6                	mov    %edx,%esi
f0101b62:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b64:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101b6a:	75 13                	jne    f0101b7f <memmove+0x3b>
f0101b6c:	f6 c1 03             	test   $0x3,%cl
f0101b6f:	75 0e                	jne    f0101b7f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101b71:	83 ef 04             	sub    $0x4,%edi
f0101b74:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101b77:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101b7a:	fd                   	std    
f0101b7b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101b7d:	eb 09                	jmp    f0101b88 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101b7f:	83 ef 01             	sub    $0x1,%edi
f0101b82:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101b85:	fd                   	std    
f0101b86:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101b88:	fc                   	cld    
f0101b89:	eb 1d                	jmp    f0101ba8 <memmove+0x64>
f0101b8b:	89 f2                	mov    %esi,%edx
f0101b8d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b8f:	f6 c2 03             	test   $0x3,%dl
f0101b92:	75 0f                	jne    f0101ba3 <memmove+0x5f>
f0101b94:	f6 c1 03             	test   $0x3,%cl
f0101b97:	75 0a                	jne    f0101ba3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101b99:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101b9c:	89 c7                	mov    %eax,%edi
f0101b9e:	fc                   	cld    
f0101b9f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101ba1:	eb 05                	jmp    f0101ba8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101ba3:	89 c7                	mov    %eax,%edi
f0101ba5:	fc                   	cld    
f0101ba6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101ba8:	5e                   	pop    %esi
f0101ba9:	5f                   	pop    %edi
f0101baa:	5d                   	pop    %ebp
f0101bab:	c3                   	ret    

f0101bac <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101bac:	55                   	push   %ebp
f0101bad:	89 e5                	mov    %esp,%ebp
f0101baf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101bb2:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bb5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bbc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101bc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bc3:	89 04 24             	mov    %eax,(%esp)
f0101bc6:	e8 79 ff ff ff       	call   f0101b44 <memmove>
}
f0101bcb:	c9                   	leave  
f0101bcc:	c3                   	ret    

f0101bcd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101bcd:	55                   	push   %ebp
f0101bce:	89 e5                	mov    %esp,%ebp
f0101bd0:	56                   	push   %esi
f0101bd1:	53                   	push   %ebx
f0101bd2:	8b 55 08             	mov    0x8(%ebp),%edx
f0101bd5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101bd8:	89 d6                	mov    %edx,%esi
f0101bda:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101bdd:	eb 1a                	jmp    f0101bf9 <memcmp+0x2c>
		if (*s1 != *s2)
f0101bdf:	0f b6 02             	movzbl (%edx),%eax
f0101be2:	0f b6 19             	movzbl (%ecx),%ebx
f0101be5:	38 d8                	cmp    %bl,%al
f0101be7:	74 0a                	je     f0101bf3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101be9:	0f b6 c0             	movzbl %al,%eax
f0101bec:	0f b6 db             	movzbl %bl,%ebx
f0101bef:	29 d8                	sub    %ebx,%eax
f0101bf1:	eb 0f                	jmp    f0101c02 <memcmp+0x35>
		s1++, s2++;
f0101bf3:	83 c2 01             	add    $0x1,%edx
f0101bf6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101bf9:	39 f2                	cmp    %esi,%edx
f0101bfb:	75 e2                	jne    f0101bdf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101bfd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101c02:	5b                   	pop    %ebx
f0101c03:	5e                   	pop    %esi
f0101c04:	5d                   	pop    %ebp
f0101c05:	c3                   	ret    

f0101c06 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101c06:	55                   	push   %ebp
f0101c07:	89 e5                	mov    %esp,%ebp
f0101c09:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c0c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101c0f:	89 c2                	mov    %eax,%edx
f0101c11:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101c14:	eb 07                	jmp    f0101c1d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101c16:	38 08                	cmp    %cl,(%eax)
f0101c18:	74 07                	je     f0101c21 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101c1a:	83 c0 01             	add    $0x1,%eax
f0101c1d:	39 d0                	cmp    %edx,%eax
f0101c1f:	72 f5                	jb     f0101c16 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101c21:	5d                   	pop    %ebp
f0101c22:	c3                   	ret    

f0101c23 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101c23:	55                   	push   %ebp
f0101c24:	89 e5                	mov    %esp,%ebp
f0101c26:	57                   	push   %edi
f0101c27:	56                   	push   %esi
f0101c28:	53                   	push   %ebx
f0101c29:	8b 55 08             	mov    0x8(%ebp),%edx
f0101c2c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101c2f:	eb 03                	jmp    f0101c34 <strtol+0x11>
		s++;
f0101c31:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101c34:	0f b6 0a             	movzbl (%edx),%ecx
f0101c37:	80 f9 09             	cmp    $0x9,%cl
f0101c3a:	74 f5                	je     f0101c31 <strtol+0xe>
f0101c3c:	80 f9 20             	cmp    $0x20,%cl
f0101c3f:	74 f0                	je     f0101c31 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101c41:	80 f9 2b             	cmp    $0x2b,%cl
f0101c44:	75 0a                	jne    f0101c50 <strtol+0x2d>
		s++;
f0101c46:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101c49:	bf 00 00 00 00       	mov    $0x0,%edi
f0101c4e:	eb 11                	jmp    f0101c61 <strtol+0x3e>
f0101c50:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101c55:	80 f9 2d             	cmp    $0x2d,%cl
f0101c58:	75 07                	jne    f0101c61 <strtol+0x3e>
		s++, neg = 1;
f0101c5a:	8d 52 01             	lea    0x1(%edx),%edx
f0101c5d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101c61:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101c66:	75 15                	jne    f0101c7d <strtol+0x5a>
f0101c68:	80 3a 30             	cmpb   $0x30,(%edx)
f0101c6b:	75 10                	jne    f0101c7d <strtol+0x5a>
f0101c6d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101c71:	75 0a                	jne    f0101c7d <strtol+0x5a>
		s += 2, base = 16;
f0101c73:	83 c2 02             	add    $0x2,%edx
f0101c76:	b8 10 00 00 00       	mov    $0x10,%eax
f0101c7b:	eb 10                	jmp    f0101c8d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0101c7d:	85 c0                	test   %eax,%eax
f0101c7f:	75 0c                	jne    f0101c8d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101c81:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101c83:	80 3a 30             	cmpb   $0x30,(%edx)
f0101c86:	75 05                	jne    f0101c8d <strtol+0x6a>
		s++, base = 8;
f0101c88:	83 c2 01             	add    $0x1,%edx
f0101c8b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0101c8d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101c92:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101c95:	0f b6 0a             	movzbl (%edx),%ecx
f0101c98:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101c9b:	89 f0                	mov    %esi,%eax
f0101c9d:	3c 09                	cmp    $0x9,%al
f0101c9f:	77 08                	ja     f0101ca9 <strtol+0x86>
			dig = *s - '0';
f0101ca1:	0f be c9             	movsbl %cl,%ecx
f0101ca4:	83 e9 30             	sub    $0x30,%ecx
f0101ca7:	eb 20                	jmp    f0101cc9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101ca9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101cac:	89 f0                	mov    %esi,%eax
f0101cae:	3c 19                	cmp    $0x19,%al
f0101cb0:	77 08                	ja     f0101cba <strtol+0x97>
			dig = *s - 'a' + 10;
f0101cb2:	0f be c9             	movsbl %cl,%ecx
f0101cb5:	83 e9 57             	sub    $0x57,%ecx
f0101cb8:	eb 0f                	jmp    f0101cc9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0101cba:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101cbd:	89 f0                	mov    %esi,%eax
f0101cbf:	3c 19                	cmp    $0x19,%al
f0101cc1:	77 16                	ja     f0101cd9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101cc3:	0f be c9             	movsbl %cl,%ecx
f0101cc6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101cc9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101ccc:	7d 0f                	jge    f0101cdd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0101cce:	83 c2 01             	add    $0x1,%edx
f0101cd1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101cd5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101cd7:	eb bc                	jmp    f0101c95 <strtol+0x72>
f0101cd9:	89 d8                	mov    %ebx,%eax
f0101cdb:	eb 02                	jmp    f0101cdf <strtol+0xbc>
f0101cdd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0101cdf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101ce3:	74 05                	je     f0101cea <strtol+0xc7>
		*endptr = (char *) s;
f0101ce5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ce8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101cea:	f7 d8                	neg    %eax
f0101cec:	85 ff                	test   %edi,%edi
f0101cee:	0f 44 c3             	cmove  %ebx,%eax
}
f0101cf1:	5b                   	pop    %ebx
f0101cf2:	5e                   	pop    %esi
f0101cf3:	5f                   	pop    %edi
f0101cf4:	5d                   	pop    %ebp
f0101cf5:	c3                   	ret    
f0101cf6:	66 90                	xchg   %ax,%ax
f0101cf8:	66 90                	xchg   %ax,%ax
f0101cfa:	66 90                	xchg   %ax,%ax
f0101cfc:	66 90                	xchg   %ax,%ax
f0101cfe:	66 90                	xchg   %ax,%ax

f0101d00 <__udivdi3>:
f0101d00:	55                   	push   %ebp
f0101d01:	57                   	push   %edi
f0101d02:	56                   	push   %esi
f0101d03:	83 ec 0c             	sub    $0xc,%esp
f0101d06:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101d0a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101d0e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101d12:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101d16:	85 c0                	test   %eax,%eax
f0101d18:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101d1c:	89 ea                	mov    %ebp,%edx
f0101d1e:	89 0c 24             	mov    %ecx,(%esp)
f0101d21:	75 2d                	jne    f0101d50 <__udivdi3+0x50>
f0101d23:	39 e9                	cmp    %ebp,%ecx
f0101d25:	77 61                	ja     f0101d88 <__udivdi3+0x88>
f0101d27:	85 c9                	test   %ecx,%ecx
f0101d29:	89 ce                	mov    %ecx,%esi
f0101d2b:	75 0b                	jne    f0101d38 <__udivdi3+0x38>
f0101d2d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d32:	31 d2                	xor    %edx,%edx
f0101d34:	f7 f1                	div    %ecx
f0101d36:	89 c6                	mov    %eax,%esi
f0101d38:	31 d2                	xor    %edx,%edx
f0101d3a:	89 e8                	mov    %ebp,%eax
f0101d3c:	f7 f6                	div    %esi
f0101d3e:	89 c5                	mov    %eax,%ebp
f0101d40:	89 f8                	mov    %edi,%eax
f0101d42:	f7 f6                	div    %esi
f0101d44:	89 ea                	mov    %ebp,%edx
f0101d46:	83 c4 0c             	add    $0xc,%esp
f0101d49:	5e                   	pop    %esi
f0101d4a:	5f                   	pop    %edi
f0101d4b:	5d                   	pop    %ebp
f0101d4c:	c3                   	ret    
f0101d4d:	8d 76 00             	lea    0x0(%esi),%esi
f0101d50:	39 e8                	cmp    %ebp,%eax
f0101d52:	77 24                	ja     f0101d78 <__udivdi3+0x78>
f0101d54:	0f bd e8             	bsr    %eax,%ebp
f0101d57:	83 f5 1f             	xor    $0x1f,%ebp
f0101d5a:	75 3c                	jne    f0101d98 <__udivdi3+0x98>
f0101d5c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101d60:	39 34 24             	cmp    %esi,(%esp)
f0101d63:	0f 86 9f 00 00 00    	jbe    f0101e08 <__udivdi3+0x108>
f0101d69:	39 d0                	cmp    %edx,%eax
f0101d6b:	0f 82 97 00 00 00    	jb     f0101e08 <__udivdi3+0x108>
f0101d71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101d78:	31 d2                	xor    %edx,%edx
f0101d7a:	31 c0                	xor    %eax,%eax
f0101d7c:	83 c4 0c             	add    $0xc,%esp
f0101d7f:	5e                   	pop    %esi
f0101d80:	5f                   	pop    %edi
f0101d81:	5d                   	pop    %ebp
f0101d82:	c3                   	ret    
f0101d83:	90                   	nop
f0101d84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d88:	89 f8                	mov    %edi,%eax
f0101d8a:	f7 f1                	div    %ecx
f0101d8c:	31 d2                	xor    %edx,%edx
f0101d8e:	83 c4 0c             	add    $0xc,%esp
f0101d91:	5e                   	pop    %esi
f0101d92:	5f                   	pop    %edi
f0101d93:	5d                   	pop    %ebp
f0101d94:	c3                   	ret    
f0101d95:	8d 76 00             	lea    0x0(%esi),%esi
f0101d98:	89 e9                	mov    %ebp,%ecx
f0101d9a:	8b 3c 24             	mov    (%esp),%edi
f0101d9d:	d3 e0                	shl    %cl,%eax
f0101d9f:	89 c6                	mov    %eax,%esi
f0101da1:	b8 20 00 00 00       	mov    $0x20,%eax
f0101da6:	29 e8                	sub    %ebp,%eax
f0101da8:	89 c1                	mov    %eax,%ecx
f0101daa:	d3 ef                	shr    %cl,%edi
f0101dac:	89 e9                	mov    %ebp,%ecx
f0101dae:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101db2:	8b 3c 24             	mov    (%esp),%edi
f0101db5:	09 74 24 08          	or     %esi,0x8(%esp)
f0101db9:	89 d6                	mov    %edx,%esi
f0101dbb:	d3 e7                	shl    %cl,%edi
f0101dbd:	89 c1                	mov    %eax,%ecx
f0101dbf:	89 3c 24             	mov    %edi,(%esp)
f0101dc2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101dc6:	d3 ee                	shr    %cl,%esi
f0101dc8:	89 e9                	mov    %ebp,%ecx
f0101dca:	d3 e2                	shl    %cl,%edx
f0101dcc:	89 c1                	mov    %eax,%ecx
f0101dce:	d3 ef                	shr    %cl,%edi
f0101dd0:	09 d7                	or     %edx,%edi
f0101dd2:	89 f2                	mov    %esi,%edx
f0101dd4:	89 f8                	mov    %edi,%eax
f0101dd6:	f7 74 24 08          	divl   0x8(%esp)
f0101dda:	89 d6                	mov    %edx,%esi
f0101ddc:	89 c7                	mov    %eax,%edi
f0101dde:	f7 24 24             	mull   (%esp)
f0101de1:	39 d6                	cmp    %edx,%esi
f0101de3:	89 14 24             	mov    %edx,(%esp)
f0101de6:	72 30                	jb     f0101e18 <__udivdi3+0x118>
f0101de8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101dec:	89 e9                	mov    %ebp,%ecx
f0101dee:	d3 e2                	shl    %cl,%edx
f0101df0:	39 c2                	cmp    %eax,%edx
f0101df2:	73 05                	jae    f0101df9 <__udivdi3+0xf9>
f0101df4:	3b 34 24             	cmp    (%esp),%esi
f0101df7:	74 1f                	je     f0101e18 <__udivdi3+0x118>
f0101df9:	89 f8                	mov    %edi,%eax
f0101dfb:	31 d2                	xor    %edx,%edx
f0101dfd:	e9 7a ff ff ff       	jmp    f0101d7c <__udivdi3+0x7c>
f0101e02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101e08:	31 d2                	xor    %edx,%edx
f0101e0a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e0f:	e9 68 ff ff ff       	jmp    f0101d7c <__udivdi3+0x7c>
f0101e14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e18:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101e1b:	31 d2                	xor    %edx,%edx
f0101e1d:	83 c4 0c             	add    $0xc,%esp
f0101e20:	5e                   	pop    %esi
f0101e21:	5f                   	pop    %edi
f0101e22:	5d                   	pop    %ebp
f0101e23:	c3                   	ret    
f0101e24:	66 90                	xchg   %ax,%ax
f0101e26:	66 90                	xchg   %ax,%ax
f0101e28:	66 90                	xchg   %ax,%ax
f0101e2a:	66 90                	xchg   %ax,%ax
f0101e2c:	66 90                	xchg   %ax,%ax
f0101e2e:	66 90                	xchg   %ax,%ax

f0101e30 <__umoddi3>:
f0101e30:	55                   	push   %ebp
f0101e31:	57                   	push   %edi
f0101e32:	56                   	push   %esi
f0101e33:	83 ec 14             	sub    $0x14,%esp
f0101e36:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101e3a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101e3e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101e42:	89 c7                	mov    %eax,%edi
f0101e44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e48:	8b 44 24 30          	mov    0x30(%esp),%eax
f0101e4c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101e50:	89 34 24             	mov    %esi,(%esp)
f0101e53:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101e57:	85 c0                	test   %eax,%eax
f0101e59:	89 c2                	mov    %eax,%edx
f0101e5b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101e5f:	75 17                	jne    f0101e78 <__umoddi3+0x48>
f0101e61:	39 fe                	cmp    %edi,%esi
f0101e63:	76 4b                	jbe    f0101eb0 <__umoddi3+0x80>
f0101e65:	89 c8                	mov    %ecx,%eax
f0101e67:	89 fa                	mov    %edi,%edx
f0101e69:	f7 f6                	div    %esi
f0101e6b:	89 d0                	mov    %edx,%eax
f0101e6d:	31 d2                	xor    %edx,%edx
f0101e6f:	83 c4 14             	add    $0x14,%esp
f0101e72:	5e                   	pop    %esi
f0101e73:	5f                   	pop    %edi
f0101e74:	5d                   	pop    %ebp
f0101e75:	c3                   	ret    
f0101e76:	66 90                	xchg   %ax,%ax
f0101e78:	39 f8                	cmp    %edi,%eax
f0101e7a:	77 54                	ja     f0101ed0 <__umoddi3+0xa0>
f0101e7c:	0f bd e8             	bsr    %eax,%ebp
f0101e7f:	83 f5 1f             	xor    $0x1f,%ebp
f0101e82:	75 5c                	jne    f0101ee0 <__umoddi3+0xb0>
f0101e84:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101e88:	39 3c 24             	cmp    %edi,(%esp)
f0101e8b:	0f 87 e7 00 00 00    	ja     f0101f78 <__umoddi3+0x148>
f0101e91:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101e95:	29 f1                	sub    %esi,%ecx
f0101e97:	19 c7                	sbb    %eax,%edi
f0101e99:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101e9d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ea1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ea5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101ea9:	83 c4 14             	add    $0x14,%esp
f0101eac:	5e                   	pop    %esi
f0101ead:	5f                   	pop    %edi
f0101eae:	5d                   	pop    %ebp
f0101eaf:	c3                   	ret    
f0101eb0:	85 f6                	test   %esi,%esi
f0101eb2:	89 f5                	mov    %esi,%ebp
f0101eb4:	75 0b                	jne    f0101ec1 <__umoddi3+0x91>
f0101eb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ebb:	31 d2                	xor    %edx,%edx
f0101ebd:	f7 f6                	div    %esi
f0101ebf:	89 c5                	mov    %eax,%ebp
f0101ec1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101ec5:	31 d2                	xor    %edx,%edx
f0101ec7:	f7 f5                	div    %ebp
f0101ec9:	89 c8                	mov    %ecx,%eax
f0101ecb:	f7 f5                	div    %ebp
f0101ecd:	eb 9c                	jmp    f0101e6b <__umoddi3+0x3b>
f0101ecf:	90                   	nop
f0101ed0:	89 c8                	mov    %ecx,%eax
f0101ed2:	89 fa                	mov    %edi,%edx
f0101ed4:	83 c4 14             	add    $0x14,%esp
f0101ed7:	5e                   	pop    %esi
f0101ed8:	5f                   	pop    %edi
f0101ed9:	5d                   	pop    %ebp
f0101eda:	c3                   	ret    
f0101edb:	90                   	nop
f0101edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ee0:	8b 04 24             	mov    (%esp),%eax
f0101ee3:	be 20 00 00 00       	mov    $0x20,%esi
f0101ee8:	89 e9                	mov    %ebp,%ecx
f0101eea:	29 ee                	sub    %ebp,%esi
f0101eec:	d3 e2                	shl    %cl,%edx
f0101eee:	89 f1                	mov    %esi,%ecx
f0101ef0:	d3 e8                	shr    %cl,%eax
f0101ef2:	89 e9                	mov    %ebp,%ecx
f0101ef4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ef8:	8b 04 24             	mov    (%esp),%eax
f0101efb:	09 54 24 04          	or     %edx,0x4(%esp)
f0101eff:	89 fa                	mov    %edi,%edx
f0101f01:	d3 e0                	shl    %cl,%eax
f0101f03:	89 f1                	mov    %esi,%ecx
f0101f05:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f09:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101f0d:	d3 ea                	shr    %cl,%edx
f0101f0f:	89 e9                	mov    %ebp,%ecx
f0101f11:	d3 e7                	shl    %cl,%edi
f0101f13:	89 f1                	mov    %esi,%ecx
f0101f15:	d3 e8                	shr    %cl,%eax
f0101f17:	89 e9                	mov    %ebp,%ecx
f0101f19:	09 f8                	or     %edi,%eax
f0101f1b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101f1f:	f7 74 24 04          	divl   0x4(%esp)
f0101f23:	d3 e7                	shl    %cl,%edi
f0101f25:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101f29:	89 d7                	mov    %edx,%edi
f0101f2b:	f7 64 24 08          	mull   0x8(%esp)
f0101f2f:	39 d7                	cmp    %edx,%edi
f0101f31:	89 c1                	mov    %eax,%ecx
f0101f33:	89 14 24             	mov    %edx,(%esp)
f0101f36:	72 2c                	jb     f0101f64 <__umoddi3+0x134>
f0101f38:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101f3c:	72 22                	jb     f0101f60 <__umoddi3+0x130>
f0101f3e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101f42:	29 c8                	sub    %ecx,%eax
f0101f44:	19 d7                	sbb    %edx,%edi
f0101f46:	89 e9                	mov    %ebp,%ecx
f0101f48:	89 fa                	mov    %edi,%edx
f0101f4a:	d3 e8                	shr    %cl,%eax
f0101f4c:	89 f1                	mov    %esi,%ecx
f0101f4e:	d3 e2                	shl    %cl,%edx
f0101f50:	89 e9                	mov    %ebp,%ecx
f0101f52:	d3 ef                	shr    %cl,%edi
f0101f54:	09 d0                	or     %edx,%eax
f0101f56:	89 fa                	mov    %edi,%edx
f0101f58:	83 c4 14             	add    $0x14,%esp
f0101f5b:	5e                   	pop    %esi
f0101f5c:	5f                   	pop    %edi
f0101f5d:	5d                   	pop    %ebp
f0101f5e:	c3                   	ret    
f0101f5f:	90                   	nop
f0101f60:	39 d7                	cmp    %edx,%edi
f0101f62:	75 da                	jne    f0101f3e <__umoddi3+0x10e>
f0101f64:	8b 14 24             	mov    (%esp),%edx
f0101f67:	89 c1                	mov    %eax,%ecx
f0101f69:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101f6d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101f71:	eb cb                	jmp    f0101f3e <__umoddi3+0x10e>
f0101f73:	90                   	nop
f0101f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f78:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101f7c:	0f 82 0f ff ff ff    	jb     f0101e91 <__umoddi3+0x61>
f0101f82:	e9 1a ff ff ff       	jmp    f0101ea1 <__umoddi3+0x71>
