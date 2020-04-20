
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
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
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
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 60 f9 11 f0       	mov    $0xf011f960,%eax
f010004b:	2d 00 f3 11 f0       	sub    $0xf011f300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 f3 11 f0 	movl   $0xf011f300,(%esp)
f0100063:	e8 ca 37 00 00       	call   f0103832 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 70 04 00 00       	call   f01004dd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 3c 10 f0 	movl   $0xf0103c80,(%esp)
f010007c:	e8 65 2d 00 00       	call   f0102de6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 ca 10 00 00       	call   f0101150 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 fe 06 00 00       	call   f0100790 <monitor>
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
f010009f:	83 3d 64 f9 11 f0 00 	cmpl   $0x0,0xf011f964
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 64 f9 11 f0    	mov    %esi,0xf011f964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 9b 3c 10 f0 	movl   $0xf0103c9b,(%esp)
f01000c8:	e8 19 2d 00 00       	call   f0102de6 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 da 2c 00 00       	call   f0102db3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d3 4c 10 f0 	movl   $0xf0104cd3,(%esp)
f01000e0:	e8 01 2d 00 00       	call   f0102de6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 9f 06 00 00       	call   f0100790 <monitor>
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
f010010b:	c7 04 24 b3 3c 10 f0 	movl   $0xf0103cb3,(%esp)
f0100112:	e8 cf 2c 00 00       	call   f0102de6 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 8d 2c 00 00       	call   f0102db3 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 d3 4c 10 f0 	movl   $0xf0104cd3,(%esp)
f010012d:	e8 b4 2c 00 00       	call   f0102de6 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

f0100138 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100138:	55                   	push   %ebp
f0100139:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013b:	ba 84 00 00 00       	mov    $0x84,%edx
f0100140:	ec                   	in     (%dx),%al
f0100141:	ec                   	in     (%dx),%al
f0100142:	ec                   	in     (%dx),%al
f0100143:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100144:	5d                   	pop    %ebp
f0100145:	c3                   	ret    

f0100146 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100146:	55                   	push   %ebp
f0100147:	89 e5                	mov    %esp,%ebp
f0100149:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010014e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010014f:	a8 01                	test   $0x1,%al
f0100151:	74 08                	je     f010015b <serial_proc_data+0x15>
f0100153:	b2 f8                	mov    $0xf8,%dl
f0100155:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100156:	0f b6 c0             	movzbl %al,%eax
f0100159:	eb 05                	jmp    f0100160 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010015b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    

f0100162 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100162:	55                   	push   %ebp
f0100163:	89 e5                	mov    %esp,%ebp
f0100165:	53                   	push   %ebx
f0100166:	83 ec 04             	sub    $0x4,%esp
f0100169:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010016b:	eb 29                	jmp    f0100196 <cons_intr+0x34>
		if (c == 0)
f010016d:	85 c0                	test   %eax,%eax
f010016f:	74 25                	je     f0100196 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f0100171:	8b 15 24 f5 11 f0    	mov    0xf011f524,%edx
f0100177:	88 82 20 f3 11 f0    	mov    %al,-0xfee0ce0(%edx)
f010017d:	8d 42 01             	lea    0x1(%edx),%eax
f0100180:	a3 24 f5 11 f0       	mov    %eax,0xf011f524
		if (cons.wpos == CONSBUFSIZE)
f0100185:	3d 00 02 00 00       	cmp    $0x200,%eax
f010018a:	75 0a                	jne    f0100196 <cons_intr+0x34>
			cons.wpos = 0;
f010018c:	c7 05 24 f5 11 f0 00 	movl   $0x0,0xf011f524
f0100193:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100196:	ff d3                	call   *%ebx
f0100198:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019b:	75 d0                	jne    f010016d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019d:	83 c4 04             	add    $0x4,%esp
f01001a0:	5b                   	pop    %ebx
f01001a1:	5d                   	pop    %ebp
f01001a2:	c3                   	ret    

f01001a3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a3:	55                   	push   %ebp
f01001a4:	89 e5                	mov    %esp,%ebp
f01001a6:	57                   	push   %edi
f01001a7:	56                   	push   %esi
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 2c             	sub    $0x2c,%esp
f01001ac:	89 c6                	mov    %eax,%esi
f01001ae:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b3:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01001b8:	eb 05                	jmp    f01001bf <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ba:	e8 79 ff ff ff       	call   f0100138 <delay>
f01001bf:	89 fa                	mov    %edi,%edx
f01001c1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c2:	a8 20                	test   $0x20,%al
f01001c4:	75 03                	jne    f01001c9 <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001c6:	4b                   	dec    %ebx
f01001c7:	75 f1                	jne    f01001ba <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001c9:	89 f2                	mov    %esi,%edx
f01001cb:	89 f0                	mov    %esi,%eax
f01001cd:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d5:	ee                   	out    %al,(%dx)
f01001d6:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001db:	bf 79 03 00 00       	mov    $0x379,%edi
f01001e0:	eb 05                	jmp    f01001e7 <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01001e2:	e8 51 ff ff ff       	call   f0100138 <delay>
f01001e7:	89 fa                	mov    %edi,%edx
f01001e9:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001ea:	84 c0                	test   %al,%al
f01001ec:	78 03                	js     f01001f1 <cons_putc+0x4e>
f01001ee:	4b                   	dec    %ebx
f01001ef:	75 f1                	jne    f01001e2 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01001f6:	8a 45 e7             	mov    -0x19(%ebp),%al
f01001f9:	ee                   	out    %al,(%dx)
f01001fa:	b2 7a                	mov    $0x7a,%dl
f01001fc:	b0 0d                	mov    $0xd,%al
f01001fe:	ee                   	out    %al,(%dx)
f01001ff:	b0 08                	mov    $0x8,%al
f0100201:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100202:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f0100208:	75 06                	jne    f0100210 <cons_putc+0x6d>
		c |= 0x0700;
f010020a:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100210:	89 f0                	mov    %esi,%eax
f0100212:	25 ff 00 00 00       	and    $0xff,%eax
f0100217:	83 f8 09             	cmp    $0x9,%eax
f010021a:	74 78                	je     f0100294 <cons_putc+0xf1>
f010021c:	83 f8 09             	cmp    $0x9,%eax
f010021f:	7f 0b                	jg     f010022c <cons_putc+0x89>
f0100221:	83 f8 08             	cmp    $0x8,%eax
f0100224:	0f 85 9e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010022a:	eb 10                	jmp    f010023c <cons_putc+0x99>
f010022c:	83 f8 0a             	cmp    $0xa,%eax
f010022f:	74 39                	je     f010026a <cons_putc+0xc7>
f0100231:	83 f8 0d             	cmp    $0xd,%eax
f0100234:	0f 85 8e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010023a:	eb 36                	jmp    f0100272 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f010023c:	66 a1 34 f5 11 f0    	mov    0xf011f534,%ax
f0100242:	66 85 c0             	test   %ax,%ax
f0100245:	0f 84 e2 00 00 00    	je     f010032d <cons_putc+0x18a>
			crt_pos--;
f010024b:	48                   	dec    %eax
f010024c:	66 a3 34 f5 11 f0    	mov    %ax,0xf011f534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100252:	0f b7 c0             	movzwl %ax,%eax
f0100255:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f010025b:	83 ce 20             	or     $0x20,%esi
f010025e:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
f0100264:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f0100268:	eb 78                	jmp    f01002e2 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010026a:	66 83 05 34 f5 11 f0 	addw   $0x50,0xf011f534
f0100271:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100272:	66 8b 0d 34 f5 11 f0 	mov    0xf011f534,%cx
f0100279:	bb 50 00 00 00       	mov    $0x50,%ebx
f010027e:	89 c8                	mov    %ecx,%eax
f0100280:	ba 00 00 00 00       	mov    $0x0,%edx
f0100285:	66 f7 f3             	div    %bx
f0100288:	66 29 d1             	sub    %dx,%cx
f010028b:	66 89 0d 34 f5 11 f0 	mov    %cx,0xf011f534
f0100292:	eb 4e                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f0100294:	b8 20 00 00 00       	mov    $0x20,%eax
f0100299:	e8 05 ff ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f010029e:	b8 20 00 00 00       	mov    $0x20,%eax
f01002a3:	e8 fb fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ad:	e8 f1 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b7:	e8 e7 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c1:	e8 dd fe ff ff       	call   f01001a3 <cons_putc>
f01002c6:	eb 1a                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002c8:	66 a1 34 f5 11 f0    	mov    0xf011f534,%ax
f01002ce:	0f b7 c8             	movzwl %ax,%ecx
f01002d1:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
f01002d7:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f01002db:	40                   	inc    %eax
f01002dc:	66 a3 34 f5 11 f0    	mov    %ax,0xf011f534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002e2:	66 81 3d 34 f5 11 f0 	cmpw   $0x7cf,0xf011f534
f01002e9:	cf 07 
f01002eb:	76 40                	jbe    f010032d <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01002ed:	a1 30 f5 11 f0       	mov    0xf011f530,%eax
f01002f2:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01002f9:	00 
f01002fa:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100300:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100304:	89 04 24             	mov    %eax,(%esp)
f0100307:	e8 70 35 00 00       	call   f010387c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010030c:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100312:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100317:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010031d:	40                   	inc    %eax
f010031e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100323:	75 f2                	jne    f0100317 <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100325:	66 83 2d 34 f5 11 f0 	subw   $0x50,0xf011f534
f010032c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010032d:	8b 0d 2c f5 11 f0    	mov    0xf011f52c,%ecx
f0100333:	b0 0e                	mov    $0xe,%al
f0100335:	89 ca                	mov    %ecx,%edx
f0100337:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100338:	66 8b 35 34 f5 11 f0 	mov    0xf011f534,%si
f010033f:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100342:	89 f0                	mov    %esi,%eax
f0100344:	66 c1 e8 08          	shr    $0x8,%ax
f0100348:	89 da                	mov    %ebx,%edx
f010034a:	ee                   	out    %al,(%dx)
f010034b:	b0 0f                	mov    $0xf,%al
f010034d:	89 ca                	mov    %ecx,%edx
f010034f:	ee                   	out    %al,(%dx)
f0100350:	89 f0                	mov    %esi,%eax
f0100352:	89 da                	mov    %ebx,%edx
f0100354:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100355:	83 c4 2c             	add    $0x2c,%esp
f0100358:	5b                   	pop    %ebx
f0100359:	5e                   	pop    %esi
f010035a:	5f                   	pop    %edi
f010035b:	5d                   	pop    %ebp
f010035c:	c3                   	ret    

f010035d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010035d:	55                   	push   %ebp
f010035e:	89 e5                	mov    %esp,%ebp
f0100360:	53                   	push   %ebx
f0100361:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100364:	ba 64 00 00 00       	mov    $0x64,%edx
f0100369:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010036a:	0f b6 c0             	movzbl %al,%eax
f010036d:	a8 01                	test   $0x1,%al
f010036f:	0f 84 e0 00 00 00    	je     f0100455 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100375:	a8 20                	test   $0x20,%al
f0100377:	0f 85 df 00 00 00    	jne    f010045c <kbd_proc_data+0xff>
f010037d:	b2 60                	mov    $0x60,%dl
f010037f:	ec                   	in     (%dx),%al
f0100380:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100382:	3c e0                	cmp    $0xe0,%al
f0100384:	75 11                	jne    f0100397 <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f0100386:	83 0d 28 f5 11 f0 40 	orl    $0x40,0xf011f528
		return 0;
f010038d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100392:	e9 ca 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f0100397:	84 c0                	test   %al,%al
f0100399:	79 33                	jns    f01003ce <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010039b:	8b 0d 28 f5 11 f0    	mov    0xf011f528,%ecx
f01003a1:	f6 c1 40             	test   $0x40,%cl
f01003a4:	75 05                	jne    f01003ab <kbd_proc_data+0x4e>
f01003a6:	88 c2                	mov    %al,%dl
f01003a8:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003ab:	0f b6 d2             	movzbl %dl,%edx
f01003ae:	8a 82 00 3d 10 f0    	mov    -0xfefc300(%edx),%al
f01003b4:	83 c8 40             	or     $0x40,%eax
f01003b7:	0f b6 c0             	movzbl %al,%eax
f01003ba:	f7 d0                	not    %eax
f01003bc:	21 c1                	and    %eax,%ecx
f01003be:	89 0d 28 f5 11 f0    	mov    %ecx,0xf011f528
		return 0;
f01003c4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003c9:	e9 93 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f01003ce:	8b 0d 28 f5 11 f0    	mov    0xf011f528,%ecx
f01003d4:	f6 c1 40             	test   $0x40,%cl
f01003d7:	74 0e                	je     f01003e7 <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003d9:	88 c2                	mov    %al,%dl
f01003db:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003de:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003e1:	89 0d 28 f5 11 f0    	mov    %ecx,0xf011f528
	}

	shift |= shiftcode[data];
f01003e7:	0f b6 d2             	movzbl %dl,%edx
f01003ea:	0f b6 82 00 3d 10 f0 	movzbl -0xfefc300(%edx),%eax
f01003f1:	0b 05 28 f5 11 f0    	or     0xf011f528,%eax
	shift ^= togglecode[data];
f01003f7:	0f b6 8a 00 3e 10 f0 	movzbl -0xfefc200(%edx),%ecx
f01003fe:	31 c8                	xor    %ecx,%eax
f0100400:	a3 28 f5 11 f0       	mov    %eax,0xf011f528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100405:	89 c1                	mov    %eax,%ecx
f0100407:	83 e1 03             	and    $0x3,%ecx
f010040a:	8b 0c 8d 00 3f 10 f0 	mov    -0xfefc100(,%ecx,4),%ecx
f0100411:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100415:	a8 08                	test   $0x8,%al
f0100417:	74 18                	je     f0100431 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f0100419:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010041c:	83 fa 19             	cmp    $0x19,%edx
f010041f:	77 05                	ja     f0100426 <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100421:	83 eb 20             	sub    $0x20,%ebx
f0100424:	eb 0b                	jmp    f0100431 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f0100426:	8d 53 bf             	lea    -0x41(%ebx),%edx
f0100429:	83 fa 19             	cmp    $0x19,%edx
f010042c:	77 03                	ja     f0100431 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f010042e:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100431:	f7 d0                	not    %eax
f0100433:	a8 06                	test   $0x6,%al
f0100435:	75 2a                	jne    f0100461 <kbd_proc_data+0x104>
f0100437:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010043d:	75 22                	jne    f0100461 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010043f:	c7 04 24 cd 3c 10 f0 	movl   $0xf0103ccd,(%esp)
f0100446:	e8 9b 29 00 00       	call   f0102de6 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100450:	b0 03                	mov    $0x3,%al
f0100452:	ee                   	out    %al,(%dx)
f0100453:	eb 0c                	jmp    f0100461 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100455:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010045a:	eb 05                	jmp    f0100461 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010045c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100461:	89 d8                	mov    %ebx,%eax
f0100463:	83 c4 14             	add    $0x14,%esp
f0100466:	5b                   	pop    %ebx
f0100467:	5d                   	pop    %ebp
f0100468:	c3                   	ret    

f0100469 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100469:	55                   	push   %ebp
f010046a:	89 e5                	mov    %esp,%ebp
f010046c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010046f:	80 3d 00 f3 11 f0 00 	cmpb   $0x0,0xf011f300
f0100476:	74 0a                	je     f0100482 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100478:	b8 46 01 10 f0       	mov    $0xf0100146,%eax
f010047d:	e8 e0 fc ff ff       	call   f0100162 <cons_intr>
}
f0100482:	c9                   	leave  
f0100483:	c3                   	ret    

f0100484 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100484:	55                   	push   %ebp
f0100485:	89 e5                	mov    %esp,%ebp
f0100487:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010048a:	b8 5d 03 10 f0       	mov    $0xf010035d,%eax
f010048f:	e8 ce fc ff ff       	call   f0100162 <cons_intr>
}
f0100494:	c9                   	leave  
f0100495:	c3                   	ret    

f0100496 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100496:	55                   	push   %ebp
f0100497:	89 e5                	mov    %esp,%ebp
f0100499:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010049c:	e8 c8 ff ff ff       	call   f0100469 <serial_intr>
	kbd_intr();
f01004a1:	e8 de ff ff ff       	call   f0100484 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004a6:	8b 15 20 f5 11 f0    	mov    0xf011f520,%edx
f01004ac:	3b 15 24 f5 11 f0    	cmp    0xf011f524,%edx
f01004b2:	74 22                	je     f01004d6 <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f01004b4:	0f b6 82 20 f3 11 f0 	movzbl -0xfee0ce0(%edx),%eax
f01004bb:	42                   	inc    %edx
f01004bc:	89 15 20 f5 11 f0    	mov    %edx,0xf011f520
		if (cons.rpos == CONSBUFSIZE)
f01004c2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004c8:	75 11                	jne    f01004db <cons_getc+0x45>
			cons.rpos = 0;
f01004ca:	c7 05 20 f5 11 f0 00 	movl   $0x0,0xf011f520
f01004d1:	00 00 00 
f01004d4:	eb 05                	jmp    f01004db <cons_getc+0x45>
		return c;
	}
	return 0;
f01004d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004db:	c9                   	leave  
f01004dc:	c3                   	ret    

f01004dd <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004dd:	55                   	push   %ebp
f01004de:	89 e5                	mov    %esp,%ebp
f01004e0:	57                   	push   %edi
f01004e1:	56                   	push   %esi
f01004e2:	53                   	push   %ebx
f01004e3:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004e6:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004ed:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004f4:	5a a5 
	if (*cp != 0xA55A) {
f01004f6:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01004fc:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100500:	74 11                	je     f0100513 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100502:	c7 05 2c f5 11 f0 b4 	movl   $0x3b4,0xf011f52c
f0100509:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010050c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100511:	eb 16                	jmp    f0100529 <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100513:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010051a:	c7 05 2c f5 11 f0 d4 	movl   $0x3d4,0xf011f52c
f0100521:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100524:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100529:	8b 0d 2c f5 11 f0    	mov    0xf011f52c,%ecx
f010052f:	b0 0e                	mov    $0xe,%al
f0100531:	89 ca                	mov    %ecx,%edx
f0100533:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100534:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100537:	89 da                	mov    %ebx,%edx
f0100539:	ec                   	in     (%dx),%al
f010053a:	0f b6 f8             	movzbl %al,%edi
f010053d:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100540:	b0 0f                	mov    $0xf,%al
f0100542:	89 ca                	mov    %ecx,%edx
f0100544:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100545:	89 da                	mov    %ebx,%edx
f0100547:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100548:	89 35 30 f5 11 f0    	mov    %esi,0xf011f530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010054e:	0f b6 d8             	movzbl %al,%ebx
f0100551:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100553:	66 89 3d 34 f5 11 f0 	mov    %di,0xf011f534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055a:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010055f:	b0 00                	mov    $0x0,%al
f0100561:	89 da                	mov    %ebx,%edx
f0100563:	ee                   	out    %al,(%dx)
f0100564:	b2 fb                	mov    $0xfb,%dl
f0100566:	b0 80                	mov    $0x80,%al
f0100568:	ee                   	out    %al,(%dx)
f0100569:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010056e:	b0 0c                	mov    $0xc,%al
f0100570:	89 ca                	mov    %ecx,%edx
f0100572:	ee                   	out    %al,(%dx)
f0100573:	b2 f9                	mov    $0xf9,%dl
f0100575:	b0 00                	mov    $0x0,%al
f0100577:	ee                   	out    %al,(%dx)
f0100578:	b2 fb                	mov    $0xfb,%dl
f010057a:	b0 03                	mov    $0x3,%al
f010057c:	ee                   	out    %al,(%dx)
f010057d:	b2 fc                	mov    $0xfc,%dl
f010057f:	b0 00                	mov    $0x0,%al
f0100581:	ee                   	out    %al,(%dx)
f0100582:	b2 f9                	mov    $0xf9,%dl
f0100584:	b0 01                	mov    $0x1,%al
f0100586:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100587:	b2 fd                	mov    $0xfd,%dl
f0100589:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010058a:	3c ff                	cmp    $0xff,%al
f010058c:	0f 95 45 e7          	setne  -0x19(%ebp)
f0100590:	8a 45 e7             	mov    -0x19(%ebp),%al
f0100593:	a2 00 f3 11 f0       	mov    %al,0xf011f300
f0100598:	89 da                	mov    %ebx,%edx
f010059a:	ec                   	in     (%dx),%al
f010059b:	89 ca                	mov    %ecx,%edx
f010059d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010059e:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f01005a2:	75 0c                	jne    f01005b0 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f01005a4:	c7 04 24 d9 3c 10 f0 	movl   $0xf0103cd9,(%esp)
f01005ab:	e8 36 28 00 00       	call   f0102de6 <cprintf>
}
f01005b0:	83 c4 2c             	add    $0x2c,%esp
f01005b3:	5b                   	pop    %ebx
f01005b4:	5e                   	pop    %esi
f01005b5:	5f                   	pop    %edi
f01005b6:	5d                   	pop    %ebp
f01005b7:	c3                   	ret    

f01005b8 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005be:	8b 45 08             	mov    0x8(%ebp),%eax
f01005c1:	e8 dd fb ff ff       	call   f01001a3 <cons_putc>
}
f01005c6:	c9                   	leave  
f01005c7:	c3                   	ret    

f01005c8 <getchar>:

int
getchar(void)
{
f01005c8:	55                   	push   %ebp
f01005c9:	89 e5                	mov    %esp,%ebp
f01005cb:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005ce:	e8 c3 fe ff ff       	call   f0100496 <cons_getc>
f01005d3:	85 c0                	test   %eax,%eax
f01005d5:	74 f7                	je     f01005ce <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005d7:	c9                   	leave  
f01005d8:	c3                   	ret    

f01005d9 <iscons>:

int
iscons(int fdnum)
{
f01005d9:	55                   	push   %ebp
f01005da:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005dc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e1:	5d                   	pop    %ebp
f01005e2:	c3                   	ret    
	...

f01005e4 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01005e4:	55                   	push   %ebp
f01005e5:	89 e5                	mov    %esp,%ebp
f01005e7:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01005ea:	c7 04 24 10 3f 10 f0 	movl   $0xf0103f10,(%esp)
f01005f1:	e8 f0 27 00 00       	call   f0102de6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01005f6:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01005fd:	00 
f01005fe:	c7 04 24 c8 3f 10 f0 	movl   $0xf0103fc8,(%esp)
f0100605:	e8 dc 27 00 00       	call   f0102de6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010060a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100611:	00 
f0100612:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100619:	f0 
f010061a:	c7 04 24 f0 3f 10 f0 	movl   $0xf0103ff0,(%esp)
f0100621:	e8 c0 27 00 00       	call   f0102de6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100626:	c7 44 24 08 76 3c 10 	movl   $0x103c76,0x8(%esp)
f010062d:	00 
f010062e:	c7 44 24 04 76 3c 10 	movl   $0xf0103c76,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 14 40 10 f0 	movl   $0xf0104014,(%esp)
f010063d:	e8 a4 27 00 00       	call   f0102de6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100642:	c7 44 24 08 00 f3 11 	movl   $0x11f300,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 00 f3 11 	movl   $0xf011f300,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 38 40 10 f0 	movl   $0xf0104038,(%esp)
f0100659:	e8 88 27 00 00       	call   f0102de6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010065e:	c7 44 24 08 60 f9 11 	movl   $0x11f960,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 60 f9 11 	movl   $0xf011f960,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 5c 40 10 f0 	movl   $0xf010405c,(%esp)
f0100675:	e8 6c 27 00 00       	call   f0102de6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010067a:	b8 5f fd 11 f0       	mov    $0xf011fd5f,%eax
f010067f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100684:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	85 c0                	test   %eax,%eax
f010068d:	79 06                	jns    f0100695 <mon_kerninfo+0xb1>
f010068f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100695:	c1 fa 0a             	sar    $0xa,%edx
f0100698:	89 54 24 04          	mov    %edx,0x4(%esp)
f010069c:	c7 04 24 80 40 10 f0 	movl   $0xf0104080,(%esp)
f01006a3:	e8 3e 27 00 00       	call   f0102de6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ad:	c9                   	leave  
f01006ae:	c3                   	ret    

f01006af <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006af:	55                   	push   %ebp
f01006b0:	89 e5                	mov    %esp,%ebp
f01006b2:	53                   	push   %ebx
f01006b3:	83 ec 14             	sub    $0x14,%esp
f01006b6:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006bb:	8b 83 64 41 10 f0    	mov    -0xfefbe9c(%ebx),%eax
f01006c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006c5:	8b 83 60 41 10 f0    	mov    -0xfefbea0(%ebx),%eax
f01006cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006cf:	c7 04 24 29 3f 10 f0 	movl   $0xf0103f29,(%esp)
f01006d6:	e8 0b 27 00 00       	call   f0102de6 <cprintf>
f01006db:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f01006de:	83 fb 24             	cmp    $0x24,%ebx
f01006e1:	75 d8                	jne    f01006bb <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01006e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e8:	83 c4 14             	add    $0x14,%esp
f01006eb:	5b                   	pop    %ebx
f01006ec:	5d                   	pop    %ebp
f01006ed:	c3                   	ret    

f01006ee <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006ee:	55                   	push   %ebp
f01006ef:	89 e5                	mov    %esp,%ebp
f01006f1:	57                   	push   %edi
f01006f2:	56                   	push   %esi
f01006f3:	53                   	push   %ebx
f01006f4:	83 ec 4c             	sub    $0x4c,%esp
        ebp = (uint32_t *)*ebp;
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
f01006f7:	89 eb                	mov    %ebp,%ebx
    while(ebp){
        eip = ebp[1];
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", *ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
        if (debuginfo_eip(eip, &info) == 0){
f01006f9:	8d 7d d0             	lea    -0x30(%ebp),%edi
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
    while(ebp){
f01006fc:	eb 7d                	jmp    f010077b <mon_backtrace+0x8d>
        eip = ebp[1];
f01006fe:	8b 73 04             	mov    0x4(%ebx),%esi
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", *ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f0100701:	8b 43 18             	mov    0x18(%ebx),%eax
f0100704:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100708:	8b 43 14             	mov    0x14(%ebx),%eax
f010070b:	89 44 24 18          	mov    %eax,0x18(%esp)
f010070f:	8b 43 10             	mov    0x10(%ebx),%eax
f0100712:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100716:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100719:	89 44 24 10          	mov    %eax,0x10(%esp)
f010071d:	8b 43 08             	mov    0x8(%ebx),%eax
f0100720:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100724:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100728:	8b 03                	mov    (%ebx),%eax
f010072a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010072e:	c7 04 24 ac 40 10 f0 	movl   $0xf01040ac,(%esp)
f0100735:	e8 ac 26 00 00       	call   f0102de6 <cprintf>
        if (debuginfo_eip(eip, &info) == 0){
f010073a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010073e:	89 34 24             	mov    %esi,(%esp)
f0100741:	e8 9a 27 00 00       	call   f0102ee0 <debuginfo_eip>
f0100746:	85 c0                	test   %eax,%eax
f0100748:	75 2f                	jne    f0100779 <mon_backtrace+0x8b>
            int fn_offset = eip - info.eip_fn_addr;
f010074a:	2b 75 e0             	sub    -0x20(%ebp),%esi
            cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);
f010074d:	89 74 24 14          	mov    %esi,0x14(%esp)
f0100751:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100754:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100758:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010075b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010075f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100762:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100766:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100769:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076d:	c7 04 24 32 3f 10 f0 	movl   $0xf0103f32,(%esp)
f0100774:	e8 6d 26 00 00       	call   f0102de6 <cprintf>
        }
        ebp = (uint32_t *)*ebp;
f0100779:	8b 1b                	mov    (%ebx),%ebx
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
    while(ebp){
f010077b:	85 db                	test   %ebx,%ebx
f010077d:	0f 85 7b ff ff ff    	jne    f01006fe <mon_backtrace+0x10>
            cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);
        }
        ebp = (uint32_t *)*ebp;
    }
	return 0;
}
f0100783:	b8 00 00 00 00       	mov    $0x0,%eax
f0100788:	83 c4 4c             	add    $0x4c,%esp
f010078b:	5b                   	pop    %ebx
f010078c:	5e                   	pop    %esi
f010078d:	5f                   	pop    %edi
f010078e:	5d                   	pop    %ebp
f010078f:	c3                   	ret    

f0100790 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100790:	55                   	push   %ebp
f0100791:	89 e5                	mov    %esp,%ebp
f0100793:	57                   	push   %edi
f0100794:	56                   	push   %esi
f0100795:	53                   	push   %ebx
f0100796:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100799:	c7 04 24 dc 40 10 f0 	movl   $0xf01040dc,(%esp)
f01007a0:	e8 41 26 00 00       	call   f0102de6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a5:	c7 04 24 00 41 10 f0 	movl   $0xf0104100,(%esp)
f01007ac:	e8 35 26 00 00       	call   f0102de6 <cprintf>

    //cprintf("x=%d y=%d\n", 3);
    //int j = 0xf0116fbc;
    //cprintf("0xf0116fbc:%d\n", j);
	while (1) {
		buf = readline("K> ");
f01007b1:	c7 04 24 43 3f 10 f0 	movl   $0xf0103f43,(%esp)
f01007b8:	e8 4b 2e 00 00       	call   f0103608 <readline>
f01007bd:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	74 ee                	je     f01007b1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ca:	be 00 00 00 00       	mov    $0x0,%esi
f01007cf:	eb 04                	jmp    f01007d5 <monitor+0x45>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007d1:	c6 03 00             	movb   $0x0,(%ebx)
f01007d4:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007d5:	8a 03                	mov    (%ebx),%al
f01007d7:	84 c0                	test   %al,%al
f01007d9:	74 5e                	je     f0100839 <monitor+0xa9>
f01007db:	0f be c0             	movsbl %al,%eax
f01007de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e2:	c7 04 24 47 3f 10 f0 	movl   $0xf0103f47,(%esp)
f01007e9:	e8 0f 30 00 00       	call   f01037fd <strchr>
f01007ee:	85 c0                	test   %eax,%eax
f01007f0:	75 df                	jne    f01007d1 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01007f2:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007f5:	74 42                	je     f0100839 <monitor+0xa9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007f7:	83 fe 0f             	cmp    $0xf,%esi
f01007fa:	75 16                	jne    f0100812 <monitor+0x82>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007fc:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100803:	00 
f0100804:	c7 04 24 4c 3f 10 f0 	movl   $0xf0103f4c,(%esp)
f010080b:	e8 d6 25 00 00       	call   f0102de6 <cprintf>
f0100810:	eb 9f                	jmp    f01007b1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100812:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100816:	46                   	inc    %esi
f0100817:	eb 01                	jmp    f010081a <monitor+0x8a>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100819:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010081a:	8a 03                	mov    (%ebx),%al
f010081c:	84 c0                	test   %al,%al
f010081e:	74 b5                	je     f01007d5 <monitor+0x45>
f0100820:	0f be c0             	movsbl %al,%eax
f0100823:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100827:	c7 04 24 47 3f 10 f0 	movl   $0xf0103f47,(%esp)
f010082e:	e8 ca 2f 00 00       	call   f01037fd <strchr>
f0100833:	85 c0                	test   %eax,%eax
f0100835:	74 e2                	je     f0100819 <monitor+0x89>
f0100837:	eb 9c                	jmp    f01007d5 <monitor+0x45>
			buf++;
	}
	argv[argc] = 0;
f0100839:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100840:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100841:	85 f6                	test   %esi,%esi
f0100843:	0f 84 68 ff ff ff    	je     f01007b1 <monitor+0x21>
f0100849:	bb 60 41 10 f0       	mov    $0xf0104160,%ebx
f010084e:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100853:	8b 03                	mov    (%ebx),%eax
f0100855:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100859:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010085c:	89 04 24             	mov    %eax,(%esp)
f010085f:	e8 46 2f 00 00       	call   f01037aa <strcmp>
f0100864:	85 c0                	test   %eax,%eax
f0100866:	75 24                	jne    f010088c <monitor+0xfc>
			return commands[i].func(argc, argv, tf);
f0100868:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010086b:	8b 55 08             	mov    0x8(%ebp),%edx
f010086e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100872:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100875:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100879:	89 34 24             	mov    %esi,(%esp)
f010087c:	ff 14 85 68 41 10 f0 	call   *-0xfefbe98(,%eax,4)
    //int j = 0xf0116fbc;
    //cprintf("0xf0116fbc:%d\n", j);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100883:	85 c0                	test   %eax,%eax
f0100885:	78 26                	js     f01008ad <monitor+0x11d>
f0100887:	e9 25 ff ff ff       	jmp    f01007b1 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010088c:	47                   	inc    %edi
f010088d:	83 c3 0c             	add    $0xc,%ebx
f0100890:	83 ff 03             	cmp    $0x3,%edi
f0100893:	75 be                	jne    f0100853 <monitor+0xc3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100895:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100898:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089c:	c7 04 24 69 3f 10 f0 	movl   $0xf0103f69,(%esp)
f01008a3:	e8 3e 25 00 00       	call   f0102de6 <cprintf>
f01008a8:	e9 04 ff ff ff       	jmp    f01007b1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ad:	83 c4 5c             	add    $0x5c,%esp
f01008b0:	5b                   	pop    %ebx
f01008b1:	5e                   	pop    %esi
f01008b2:	5f                   	pop    %edi
f01008b3:	5d                   	pop    %ebp
f01008b4:	c3                   	ret    
f01008b5:	00 00                	add    %al,(%eax)
	...

f01008b8 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008b8:	55                   	push   %ebp
f01008b9:	89 e5                	mov    %esp,%ebp
f01008bb:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01008be:	89 d1                	mov    %edx,%ecx
f01008c0:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01008c3:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008c6:	a8 01                	test   $0x1,%al
f01008c8:	74 4d                	je     f0100917 <check_va2pa+0x5f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008ca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008cf:	89 c1                	mov    %eax,%ecx
f01008d1:	c1 e9 0c             	shr    $0xc,%ecx
f01008d4:	3b 0d 68 f9 11 f0    	cmp    0xf011f968,%ecx
f01008da:	72 20                	jb     f01008fc <check_va2pa+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008e0:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f01008e7:	f0 
f01008e8:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f01008ef:	00 
f01008f0:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01008f7:	e8 98 f7 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f01008fc:	c1 ea 0c             	shr    $0xc,%edx
f01008ff:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100905:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010090c:	a8 01                	test   $0x1,%al
f010090e:	74 0e                	je     f010091e <check_va2pa+0x66>
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100910:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100915:	eb 0c                	jmp    f0100923 <check_va2pa+0x6b>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100917:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010091c:	eb 05                	jmp    f0100923 <check_va2pa+0x6b>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
f010091e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return PTE_ADDR(p[PTX(va)]);
}
f0100923:	c9                   	leave  
f0100924:	c3                   	ret    

f0100925 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100925:	55                   	push   %ebp
f0100926:	89 e5                	mov    %esp,%ebp
f0100928:	53                   	push   %ebx
f0100929:	83 ec 14             	sub    $0x14,%esp
f010092c:	89 c3                	mov    %eax,%ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010092e:	83 3d 40 f5 11 f0 00 	cmpl   $0x0,0xf011f540
f0100935:	75 0f                	jne    f0100946 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100937:	b8 5f 09 12 f0       	mov    $0xf012095f,%eax
f010093c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100941:	a3 40 f5 11 f0       	mov    %eax,0xf011f540
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    cprintf("boot_alloc():\n");
f0100946:	c7 04 24 88 49 10 f0 	movl   $0xf0104988,(%esp)
f010094d:	e8 94 24 00 00       	call   f0102de6 <cprintf>
	cprintf("boot_alloc memory at %x\n", nextfree);
f0100952:	a1 40 f5 11 f0       	mov    0xf011f540,%eax
f0100957:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095b:	c7 04 24 97 49 10 f0 	movl   $0xf0104997,(%esp)
f0100962:	e8 7f 24 00 00       	call   f0102de6 <cprintf>
	cprintf("Next free memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
f0100967:	89 d8                	mov    %ebx,%eax
f0100969:	03 05 40 f5 11 f0    	add    0xf011f540,%eax
f010096f:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100974:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100979:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097d:	c7 04 24 b0 49 10 f0 	movl   $0xf01049b0,(%esp)
f0100984:	e8 5d 24 00 00       	call   f0102de6 <cprintf>
    result = nextfree;
f0100989:	a1 40 f5 11 f0       	mov    0xf011f540,%eax
    nextfree = ROUNDUP(nextfree+n, PGSIZE);
f010098e:	8d 94 18 ff 0f 00 00 	lea    0xfff(%eax,%ebx,1),%edx
f0100995:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099b:	89 15 40 f5 11 f0    	mov    %edx,0xf011f540
	return result;
}
f01009a1:	83 c4 14             	add    $0x14,%esp
f01009a4:	5b                   	pop    %ebx
f01009a5:	5d                   	pop    %ebp
f01009a6:	c3                   	ret    

f01009a7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009a7:	55                   	push   %ebp
f01009a8:	89 e5                	mov    %esp,%ebp
f01009aa:	56                   	push   %esi
f01009ab:	53                   	push   %ebx
f01009ac:	83 ec 10             	sub    $0x10,%esp
f01009af:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009b1:	89 04 24             	mov    %eax,(%esp)
f01009b4:	e8 bf 23 00 00       	call   f0102d78 <mc146818_read>
f01009b9:	89 c6                	mov    %eax,%esi
f01009bb:	43                   	inc    %ebx
f01009bc:	89 1c 24             	mov    %ebx,(%esp)
f01009bf:	e8 b4 23 00 00       	call   f0102d78 <mc146818_read>
f01009c4:	c1 e0 08             	shl    $0x8,%eax
f01009c7:	09 f0                	or     %esi,%eax
}
f01009c9:	83 c4 10             	add    $0x10,%esp
f01009cc:	5b                   	pop    %ebx
f01009cd:	5e                   	pop    %esi
f01009ce:	5d                   	pop    %ebp
f01009cf:	c3                   	ret    

f01009d0 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009d0:	55                   	push   %ebp
f01009d1:	89 e5                	mov    %esp,%ebp
f01009d3:	57                   	push   %edi
f01009d4:	56                   	push   %esi
f01009d5:	53                   	push   %ebx
f01009d6:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d9:	3c 01                	cmp    $0x1,%al
f01009db:	19 f6                	sbb    %esi,%esi
f01009dd:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f01009e3:	46                   	inc    %esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01009e4:	8b 15 38 f5 11 f0    	mov    0xf011f538,%edx
f01009ea:	85 d2                	test   %edx,%edx
f01009ec:	75 1c                	jne    f0100a0a <check_page_free_list+0x3a>
		panic("'page_free_list' is a null pointer!");
f01009ee:	c7 44 24 08 a8 41 10 	movl   $0xf01041a8,0x8(%esp)
f01009f5:	f0 
f01009f6:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
f01009fd:	00 
f01009fe:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100a05:	e8 8a f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a0a:	84 c0                	test   %al,%al
f0100a0c:	74 4b                	je     f0100a59 <check_page_free_list+0x89>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a0e:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a11:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a14:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a17:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a1a:	89 d0                	mov    %edx,%eax
f0100a1c:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0100a22:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a25:	c1 e8 16             	shr    $0x16,%eax
f0100a28:	39 c6                	cmp    %eax,%esi
f0100a2a:	0f 96 c0             	setbe  %al
f0100a2d:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100a30:	8b 4c 85 d8          	mov    -0x28(%ebp,%eax,4),%ecx
f0100a34:	89 11                	mov    %edx,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a36:	89 54 85 d8          	mov    %edx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a3a:	8b 12                	mov    (%edx),%edx
f0100a3c:	85 d2                	test   %edx,%edx
f0100a3e:	75 da                	jne    f0100a1a <check_page_free_list+0x4a>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a40:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a43:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a49:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a4c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100a4f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a51:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a54:	a3 38 f5 11 f0       	mov    %eax,0xf011f538
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a59:	8b 1d 38 f5 11 f0    	mov    0xf011f538,%ebx
f0100a5f:	eb 63                	jmp    f0100ac4 <check_page_free_list+0xf4>
f0100a61:	89 d8                	mov    %ebx,%eax
f0100a63:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0100a69:	c1 f8 03             	sar    $0x3,%eax
f0100a6c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a6f:	89 c2                	mov    %eax,%edx
f0100a71:	c1 ea 16             	shr    $0x16,%edx
f0100a74:	39 d6                	cmp    %edx,%esi
f0100a76:	76 4a                	jbe    f0100ac2 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a78:	89 c2                	mov    %eax,%edx
f0100a7a:	c1 ea 0c             	shr    $0xc,%edx
f0100a7d:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0100a83:	72 20                	jb     f0100aa5 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a89:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0100a90:	f0 
f0100a91:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a98:	00 
f0100a99:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0100aa0:	e8 ef f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100aac:	00 
f0100aad:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100ab4:	00 
	return (void *)(pa + KERNBASE);
f0100ab5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aba:	89 04 24             	mov    %eax,(%esp)
f0100abd:	e8 70 2d 00 00       	call   f0103832 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac2:	8b 1b                	mov    (%ebx),%ebx
f0100ac4:	85 db                	test   %ebx,%ebx
f0100ac6:	75 99                	jne    f0100a61 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ac8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100acd:	e8 53 fe ff ff       	call   f0100925 <boot_alloc>
f0100ad2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad5:	8b 15 38 f5 11 f0    	mov    0xf011f538,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100adb:	8b 0d 70 f9 11 f0    	mov    0xf011f970,%ecx
		assert(pp < pages + npages);
f0100ae1:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0100ae6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ae9:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100aec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aef:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100af2:	be 00 00 00 00       	mov    $0x0,%esi
f0100af7:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100afa:	e9 91 01 00 00       	jmp    f0100c90 <check_page_free_list+0x2c0>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aff:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b02:	73 24                	jae    f0100b28 <check_page_free_list+0x158>
f0100b04:	c7 44 24 0c d6 49 10 	movl   $0xf01049d6,0xc(%esp)
f0100b0b:	f0 
f0100b0c:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100b13:	f0 
f0100b14:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100b1b:	00 
f0100b1c:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100b23:	e8 6c f5 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b28:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b2b:	72 24                	jb     f0100b51 <check_page_free_list+0x181>
f0100b2d:	c7 44 24 0c f7 49 10 	movl   $0xf01049f7,0xc(%esp)
f0100b34:	f0 
f0100b35:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100b3c:	f0 
f0100b3d:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100b44:	00 
f0100b45:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100b4c:	e8 43 f5 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b51:	89 d0                	mov    %edx,%eax
f0100b53:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100b56:	a8 07                	test   $0x7,%al
f0100b58:	74 24                	je     f0100b7e <check_page_free_list+0x1ae>
f0100b5a:	c7 44 24 0c cc 41 10 	movl   $0xf01041cc,0xc(%esp)
f0100b61:	f0 
f0100b62:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100b69:	f0 
f0100b6a:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100b71:	00 
f0100b72:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100b79:	e8 16 f5 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b7e:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b81:	c1 e0 0c             	shl    $0xc,%eax
f0100b84:	75 24                	jne    f0100baa <check_page_free_list+0x1da>
f0100b86:	c7 44 24 0c 0b 4a 10 	movl   $0xf0104a0b,0xc(%esp)
f0100b8d:	f0 
f0100b8e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100b95:	f0 
f0100b96:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100b9d:	00 
f0100b9e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100ba5:	e8 ea f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100baa:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100baf:	75 24                	jne    f0100bd5 <check_page_free_list+0x205>
f0100bb1:	c7 44 24 0c 1c 4a 10 	movl   $0xf0104a1c,0xc(%esp)
f0100bb8:	f0 
f0100bb9:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100bc0:	f0 
f0100bc1:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f0100bc8:	00 
f0100bc9:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100bd0:	e8 bf f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bd5:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bda:	75 24                	jne    f0100c00 <check_page_free_list+0x230>
f0100bdc:	c7 44 24 0c 00 42 10 	movl   $0xf0104200,0xc(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100beb:	f0 
f0100bec:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f0100bf3:	00 
f0100bf4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100bfb:	e8 94 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c00:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c05:	75 24                	jne    f0100c2b <check_page_free_list+0x25b>
f0100c07:	c7 44 24 0c 35 4a 10 	movl   $0xf0104a35,0xc(%esp)
f0100c0e:	f0 
f0100c0f:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100c16:	f0 
f0100c17:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100c1e:	00 
f0100c1f:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100c26:	e8 69 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c2b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c30:	76 58                	jbe    f0100c8a <check_page_free_list+0x2ba>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c32:	89 c1                	mov    %eax,%ecx
f0100c34:	c1 e9 0c             	shr    $0xc,%ecx
f0100c37:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100c3a:	77 20                	ja     f0100c5c <check_page_free_list+0x28c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c40:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0100c47:	f0 
f0100c48:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100c4f:	00 
f0100c50:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0100c57:	e8 38 f4 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100c5c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c61:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c64:	76 27                	jbe    f0100c8d <check_page_free_list+0x2bd>
f0100c66:	c7 44 24 0c 24 42 10 	movl   $0xf0104224,0xc(%esp)
f0100c6d:	f0 
f0100c6e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100c75:	f0 
f0100c76:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100c7d:	00 
f0100c7e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100c85:	e8 0a f4 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c8a:	46                   	inc    %esi
f0100c8b:	eb 01                	jmp    f0100c8e <check_page_free_list+0x2be>
		else
			++nfree_extmem;
f0100c8d:	43                   	inc    %ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c8e:	8b 12                	mov    (%edx),%edx
f0100c90:	85 d2                	test   %edx,%edx
f0100c92:	0f 85 67 fe ff ff    	jne    f0100aff <check_page_free_list+0x12f>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c98:	85 f6                	test   %esi,%esi
f0100c9a:	7f 24                	jg     f0100cc0 <check_page_free_list+0x2f0>
f0100c9c:	c7 44 24 0c 4f 4a 10 	movl   $0xf0104a4f,0xc(%esp)
f0100ca3:	f0 
f0100ca4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100cab:	f0 
f0100cac:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0100cb3:	00 
f0100cb4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100cbb:	e8 d4 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100cc0:	85 db                	test   %ebx,%ebx
f0100cc2:	7f 24                	jg     f0100ce8 <check_page_free_list+0x318>
f0100cc4:	c7 44 24 0c 61 4a 10 	movl   $0xf0104a61,0xc(%esp)
f0100ccb:	f0 
f0100ccc:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0100cd3:	f0 
f0100cd4:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f0100cdb:	00 
f0100cdc:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100ce3:	e8 ac f3 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ce8:	c7 04 24 6c 42 10 f0 	movl   $0xf010426c,(%esp)
f0100cef:	e8 f2 20 00 00       	call   f0102de6 <cprintf>
}
f0100cf4:	83 c4 4c             	add    $0x4c,%esp
f0100cf7:	5b                   	pop    %ebx
f0100cf8:	5e                   	pop    %esi
f0100cf9:	5f                   	pop    %edi
f0100cfa:	5d                   	pop    %ebp
f0100cfb:	c3                   	ret    

f0100cfc <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cfc:	55                   	push   %ebp
f0100cfd:	89 e5                	mov    %esp,%ebp
f0100cff:	57                   	push   %edi
f0100d00:	56                   	push   %esi
f0100d01:	53                   	push   %ebx
f0100d02:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
    page_free_list = NULL;   
f0100d05:	c7 05 38 f5 11 f0 00 	movl   $0x0,0xf011f538
f0100d0c:	00 00 00 
    //num_iohole：在IO hole区域占用的页数. (0x100000-0xA0000)/4K=96
	int num_iohole = (EXTPHYSMEM-IOPHYSMEM)/PGSIZE;
    //num_alloc：在extended memory区域已经被占用的页数
	int num_extalloc = ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE;
f0100d0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d14:	e8 0c fc ff ff       	call   f0100925 <boot_alloc>
f0100d19:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100d1f:	c1 eb 0c             	shr    $0xc,%ebx
	cprintf("pageinfo size: %d\n", sizeof(struct PageInfo));
f0100d22:	c7 44 24 04 08 00 00 	movl   $0x8,0x4(%esp)
f0100d29:	00 
f0100d2a:	c7 04 24 72 4a 10 f0 	movl   $0xf0104a72,(%esp)
f0100d31:	e8 b0 20 00 00       	call   f0102de6 <cprintf>
	cprintf("npages_basemem = %d, num_iohol = %d,num_extalloc=%d\n",npages_basemem, num_iohole, num_extalloc);
f0100d36:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d3a:	c7 44 24 08 60 00 00 	movl   $0x60,0x8(%esp)
f0100d41:	00 
f0100d42:	a1 3c f5 11 f0       	mov    0xf011f53c,%eax
f0100d47:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d4b:	c7 04 24 90 42 10 f0 	movl   $0xf0104290,(%esp)
f0100d52:	e8 8f 20 00 00       	call   f0102de6 <cprintf>
	for(i=0; i<npages; i++) {
		if(i==0) {
			pages[i].pp_ref = 1;
		} else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_extalloc) {
f0100d57:	8b 35 3c f5 11 f0    	mov    0xf011f53c,%esi
f0100d5d:	8d 7c 33 60          	lea    0x60(%ebx,%esi,1),%edi
f0100d61:	8b 1d 38 f5 11 f0    	mov    0xf011f538,%ebx
	int num_iohole = (EXTPHYSMEM-IOPHYSMEM)/PGSIZE;
    //num_alloc：在extended memory区域已经被占用的页数
	int num_extalloc = ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE;
	cprintf("pageinfo size: %d\n", sizeof(struct PageInfo));
	cprintf("npages_basemem = %d, num_iohol = %d,num_extalloc=%d\n",npages_basemem, num_iohole, num_extalloc);
	for(i=0; i<npages; i++) {
f0100d67:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d71:	eb 45                	jmp    f0100db8 <page_init+0xbc>
		if(i==0) {
f0100d73:	85 c0                	test   %eax,%eax
f0100d75:	75 0e                	jne    f0100d85 <page_init+0x89>
			pages[i].pp_ref = 1;
f0100d77:	8b 0d 70 f9 11 f0    	mov    0xf011f970,%ecx
f0100d7d:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
f0100d83:	eb 2f                	jmp    f0100db4 <page_init+0xb8>
		} else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_extalloc) {
f0100d85:	39 f0                	cmp    %esi,%eax
f0100d87:	72 13                	jb     f0100d9c <page_init+0xa0>
f0100d89:	39 f8                	cmp    %edi,%eax
f0100d8b:	73 0f                	jae    f0100d9c <page_init+0xa0>
			pages[i].pp_ref = 1;
f0100d8d:	8b 0d 70 f9 11 f0    	mov    0xf011f970,%ecx
f0100d93:	66 c7 44 11 04 01 00 	movw   $0x1,0x4(%ecx,%edx,1)
f0100d9a:	eb 18                	jmp    f0100db4 <page_init+0xb8>
		} else {
			pages[i].pp_ref = 0;
f0100d9c:	89 d1                	mov    %edx,%ecx
f0100d9e:	03 0d 70 f9 11 f0    	add    0xf011f970,%ecx
f0100da4:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100daa:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100dac:	89 d3                	mov    %edx,%ebx
f0100dae:	03 1d 70 f9 11 f0    	add    0xf011f970,%ebx
	int num_iohole = (EXTPHYSMEM-IOPHYSMEM)/PGSIZE;
    //num_alloc：在extended memory区域已经被占用的页数
	int num_extalloc = ((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE;
	cprintf("pageinfo size: %d\n", sizeof(struct PageInfo));
	cprintf("npages_basemem = %d, num_iohol = %d,num_extalloc=%d\n",npages_basemem, num_iohole, num_extalloc);
	for(i=0; i<npages; i++) {
f0100db4:	40                   	inc    %eax
f0100db5:	83 c2 08             	add    $0x8,%edx
f0100db8:	3b 05 68 f9 11 f0    	cmp    0xf011f968,%eax
f0100dbe:	72 b3                	jb     f0100d73 <page_init+0x77>
f0100dc0:	89 1d 38 f5 11 f0    	mov    %ebx,0xf011f538
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}        
}
f0100dc6:	83 c4 1c             	add    $0x1c,%esp
f0100dc9:	5b                   	pop    %ebx
f0100dca:	5e                   	pop    %esi
f0100dcb:	5f                   	pop    %edi
f0100dcc:	5d                   	pop    %ebp
f0100dcd:	c3                   	ret    

f0100dce <page_alloc>:
//
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags) {            
f0100dce:	55                   	push   %ebp
f0100dcf:	89 e5                	mov    %esp,%ebp
f0100dd1:	53                   	push   %ebx
f0100dd2:	83 ec 14             	sub    $0x14,%esp

	// Fill this function in
	struct PageInfo *result;
    if (!page_free_list) return NULL;
f0100dd5:	8b 1d 38 f5 11 f0    	mov    0xf011f538,%ebx
f0100ddb:	85 db                	test   %ebx,%ebx
f0100ddd:	74 6b                	je     f0100e4a <page_alloc+0x7c>

	result= page_free_list;
	page_free_list = page_free_list->pp_link;
f0100ddf:	8b 03                	mov    (%ebx),%eax
f0100de1:	a3 38 f5 11 f0       	mov    %eax,0xf011f538
	result->pp_link = NULL;
f0100de6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

    if (alloc_flags & ALLOC_ZERO)
f0100dec:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100df0:	74 58                	je     f0100e4a <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100df2:	89 d8                	mov    %ebx,%eax
f0100df4:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0100dfa:	c1 f8 03             	sar    $0x3,%eax
f0100dfd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e00:	89 c2                	mov    %eax,%edx
f0100e02:	c1 ea 0c             	shr    $0xc,%edx
f0100e05:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0100e0b:	72 20                	jb     f0100e2d <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e11:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0100e18:	f0 
f0100e19:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100e20:	00 
f0100e21:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0100e28:	e8 67 f2 ff ff       	call   f0100094 <_panic>
        memset(page2kva(result), '\0', PGSIZE); 
f0100e2d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e34:	00 
f0100e35:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e3c:	00 
	return (void *)(pa + KERNBASE);
f0100e3d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e42:	89 04 24             	mov    %eax,(%esp)
f0100e45:	e8 e8 29 00 00       	call   f0103832 <memset>

    return result;
}
f0100e4a:	89 d8                	mov    %ebx,%eax
f0100e4c:	83 c4 14             	add    $0x14,%esp
f0100e4f:	5b                   	pop    %ebx
f0100e50:	5d                   	pop    %ebp
f0100e51:	c3                   	ret    

f0100e52 <page_free>:
//
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp) {
f0100e52:	55                   	push   %ebp
f0100e53:	89 e5                	mov    %esp,%ebp
f0100e55:	83 ec 18             	sub    $0x18,%esp
f0100e58:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
    if(pp->pp_ref  || pp->pp_link )
f0100e5b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e60:	75 05                	jne    f0100e67 <page_free+0x15>
f0100e62:	83 38 00             	cmpl   $0x0,(%eax)
f0100e65:	74 1c                	je     f0100e83 <page_free+0x31>
        panic("page is in use or it is in free list.\n");
f0100e67:	c7 44 24 08 c8 42 10 	movl   $0xf01042c8,0x8(%esp)
f0100e6e:	f0 
f0100e6f:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
f0100e76:	00 
f0100e77:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100e7e:	e8 11 f2 ff ff       	call   f0100094 <_panic>
    pp->pp_link = page_free_list;
f0100e83:	8b 15 38 f5 11 f0    	mov    0xf011f538,%edx
f0100e89:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;
f0100e8b:	a3 38 f5 11 f0       	mov    %eax,0xf011f538
}
f0100e90:	c9                   	leave  
f0100e91:	c3                   	ret    

f0100e92 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e92:	55                   	push   %ebp
f0100e93:	89 e5                	mov    %esp,%ebp
f0100e95:	83 ec 18             	sub    $0x18,%esp
f0100e98:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100e9b:	8b 50 04             	mov    0x4(%eax),%edx
f0100e9e:	4a                   	dec    %edx
f0100e9f:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100ea3:	66 85 d2             	test   %dx,%dx
f0100ea6:	75 08                	jne    f0100eb0 <page_decref+0x1e>
		page_free(pp);
f0100ea8:	89 04 24             	mov    %eax,(%esp)
f0100eab:	e8 a2 ff ff ff       	call   f0100e52 <page_free>
}
f0100eb0:	c9                   	leave  
f0100eb1:	c3                   	ret    

f0100eb2 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100eb2:	55                   	push   %ebp
f0100eb3:	89 e5                	mov    %esp,%ebp
f0100eb5:	57                   	push   %edi
f0100eb6:	56                   	push   %esi
f0100eb7:	53                   	push   %ebx
f0100eb8:	83 ec 1c             	sub    $0x1c,%esp
f0100ebb:	8b 75 0c             	mov    0xc(%ebp),%esi
    //fill this function in
    pde_t *pde = NULL; //page directory entry
    pte_t *pt = NULL; //page table
    uintptr_t pdx = PDX(va); //page directory index
f0100ebe:	89 f3                	mov    %esi,%ebx
f0100ec0:	c1 eb 16             	shr    $0x16,%ebx
    uintptr_t ptx = PTX(va); //page table index
    struct PageInfo *pp; //pysical page
    
    //[x]  *pde = pgdir[pdx]; 错误
    pde = &pgdir[pdx]; 
f0100ec3:	c1 e3 02             	shl    $0x2,%ebx
f0100ec6:	03 5d 08             	add    0x8(%ebp),%ebx
    if((*pde) & PTE_P){ //判断该目录项是否指向某个页表
f0100ec9:	8b 03                	mov    (%ebx),%eax
f0100ecb:	a8 01                	test   $0x1,%al
f0100ecd:	74 3d                	je     f0100f0c <pgdir_walk+0x5a>
    //PTE_ADDR将pde_t类型转为physaddr_t类型,并且清空低12位，以获得物理地址。
        pt = (pte_t *)KADDR(PTE_ADDR(*pde)); //获取pde指向的页表pt的虚拟地址
f0100ecf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ed4:	89 c2                	mov    %eax,%edx
f0100ed6:	c1 ea 0c             	shr    $0xc,%edx
f0100ed9:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0100edf:	72 20                	jb     f0100f01 <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ee5:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0100eec:	f0 
f0100eed:	c7 44 24 04 7c 01 00 	movl   $0x17c,0x4(%esp)
f0100ef4:	00 
f0100ef5:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100efc:	e8 93 f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f01:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100f07:	e9 92 00 00 00       	jmp    f0100f9e <pgdir_walk+0xec>
    }
    else{
        if(!create) //找不到，也不创建
f0100f0c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f10:	0f 84 96 00 00 00    	je     f0100fac <pgdir_walk+0xfa>
            return NULL;

        pp = page_alloc(ALLOC_ZERO); //创建一个页表
f0100f16:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f1d:	e8 ac fe ff ff       	call   f0100dce <page_alloc>
        if(!pp) return NULL; //创建失败
f0100f22:	85 c0                	test   %eax,%eax
f0100f24:	0f 84 89 00 00 00    	je     f0100fb3 <pgdir_walk+0x101>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f2a:	89 c2                	mov    %eax,%edx
f0100f2c:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0100f32:	c1 fa 03             	sar    $0x3,%edx
f0100f35:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f38:	89 d1                	mov    %edx,%ecx
f0100f3a:	c1 e9 0c             	shr    $0xc,%ecx
f0100f3d:	3b 0d 68 f9 11 f0    	cmp    0xf011f968,%ecx
f0100f43:	72 20                	jb     f0100f65 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f45:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f49:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0100f50:	f0 
f0100f51:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f58:	00 
f0100f59:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0100f60:	e8 2f f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f65:	8d ba 00 00 00 f0    	lea    -0x10000000(%edx),%edi
f0100f6b:	89 f9                	mov    %edi,%ecx

        pt = (pte_t *)page2kva(pp); //为该页表pt分配一页空间
        pp->pp_ref++;
f0100f6d:	66 ff 40 04          	incw   0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f71:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100f77:	77 20                	ja     f0100f99 <pgdir_walk+0xe7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f79:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100f7d:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0100f84:	f0 
f0100f85:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0100f8c:	00 
f0100f8d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100f94:	e8 fb f0 ff ff       	call   f0100094 <_panic>
        *pde = PADDR(pt) | PTE_P | PTE_W | PTE_U ; //设置页目录项权限
f0100f99:	83 ca 07             	or     $0x7,%edx
f0100f9c:	89 13                	mov    %edx,(%ebx)
{
    //fill this function in
    pde_t *pde = NULL; //page directory entry
    pte_t *pt = NULL; //page table
    uintptr_t pdx = PDX(va); //page directory index
    uintptr_t ptx = PTX(va); //page table index
f0100f9e:	c1 ee 0a             	shr    $0xa,%esi

        pt = (pte_t *)page2kva(pp); //为该页表pt分配一页空间
        pp->pp_ref++;
        *pde = PADDR(pt) | PTE_P | PTE_W | PTE_U ; //设置页目录项权限
    }
    return &pt[ptx];//返回va内要求的页表项地址。
f0100fa1:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100fa7:	8d 04 31             	lea    (%ecx,%esi,1),%eax
f0100faa:	eb 0c                	jmp    f0100fb8 <pgdir_walk+0x106>
    //PTE_ADDR将pde_t类型转为physaddr_t类型,并且清空低12位，以获得物理地址。
        pt = (pte_t *)KADDR(PTE_ADDR(*pde)); //获取pde指向的页表pt的虚拟地址
    }
    else{
        if(!create) //找不到，也不创建
            return NULL;
f0100fac:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb1:	eb 05                	jmp    f0100fb8 <pgdir_walk+0x106>

        pp = page_alloc(ALLOC_ZERO); //创建一个页表
        if(!pp) return NULL; //创建失败
f0100fb3:	b8 00 00 00 00       	mov    $0x0,%eax
        pt = (pte_t *)page2kva(pp); //为该页表pt分配一页空间
        pp->pp_ref++;
        *pde = PADDR(pt) | PTE_P | PTE_W | PTE_U ; //设置页目录项权限
    }
    return &pt[ptx];//返回va内要求的页表项地址。
}
f0100fb8:	83 c4 1c             	add    $0x1c,%esp
f0100fbb:	5b                   	pop    %ebx
f0100fbc:	5e                   	pop    %esi
f0100fbd:	5f                   	pop    %edi
f0100fbe:	5d                   	pop    %ebp
f0100fbf:	c3                   	ret    

f0100fc0 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100fc0:	55                   	push   %ebp
f0100fc1:	89 e5                	mov    %esp,%ebp
f0100fc3:	57                   	push   %edi
f0100fc4:	56                   	push   %esi
f0100fc5:	53                   	push   %ebx
f0100fc6:	83 ec 2c             	sub    $0x2c,%esp
f0100fc9:	89 c7                	mov    %eax,%edi
f0100fcb:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100fce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
    pte_t *pte = NULL;
    for(size_t i = 0; i < size; i+=PGSIZE){
f0100fd1:	bb 00 00 00 00       	mov    $0x0,%ebx
        pte = pgdir_walk(pgdir, (void *)va, 1); //循环映射，若无页表项就新建一个页表
        *pte = PTE_ADDR(pa) | perm | PTE_P;
f0100fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fd9:	83 c8 01             	or     $0x1,%eax
f0100fdc:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    pte_t *pte = NULL;
    for(size_t i = 0; i < size; i+=PGSIZE){
f0100fdf:	eb 2a                	jmp    f010100b <boot_map_region+0x4b>
        pte = pgdir_walk(pgdir, (void *)va, 1); //循环映射，若无页表项就新建一个页表
f0100fe1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100fe8:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0100fe9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fec:	01 d8                	add    %ebx,%eax
{
	// Fill this function in
    pte_t *pte = NULL;
    for(size_t i = 0; i < size; i+=PGSIZE){
        pte = pgdir_walk(pgdir, (void *)va, 1); //循环映射，若无页表项就新建一个页表
f0100fee:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ff2:	89 3c 24             	mov    %edi,(%esp)
f0100ff5:	e8 b8 fe ff ff       	call   f0100eb2 <pgdir_walk>
        *pte = PTE_ADDR(pa) | perm | PTE_P;
f0100ffa:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
f0101000:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101003:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    pte_t *pte = NULL;
    for(size_t i = 0; i < size; i+=PGSIZE){
f0101005:	81 c3 00 10 00 00    	add    $0x1000,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010100b:	8b 75 08             	mov    0x8(%ebp),%esi
f010100e:	01 de                	add    %ebx,%esi
{
	// Fill this function in
    pte_t *pte = NULL;
    for(size_t i = 0; i < size; i+=PGSIZE){
f0101010:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101013:	72 cc                	jb     f0100fe1 <boot_map_region+0x21>
        pte = pgdir_walk(pgdir, (void *)va, 1); //循环映射，若无页表项就新建一个页表
        *pte = PTE_ADDR(pa) | perm | PTE_P;
        pa += PGSIZE;
        va += PGSIZE;
    }
}
f0101015:	83 c4 2c             	add    $0x2c,%esp
f0101018:	5b                   	pop    %ebx
f0101019:	5e                   	pop    %esi
f010101a:	5f                   	pop    %edi
f010101b:	5d                   	pop    %ebp
f010101c:	c3                   	ret    

f010101d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010101d:	55                   	push   %ebp
f010101e:	89 e5                	mov    %esp,%ebp
f0101020:	53                   	push   %ebx
f0101021:	83 ec 14             	sub    $0x14,%esp
f0101024:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101027:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010102e:	00 
f010102f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101032:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101036:	8b 45 08             	mov    0x8(%ebp),%eax
f0101039:	89 04 24             	mov    %eax,(%esp)
f010103c:	e8 71 fe ff ff       	call   f0100eb2 <pgdir_walk>
    if (!pte) return NULL;
f0101041:	85 c0                	test   %eax,%eax
f0101043:	74 3a                	je     f010107f <page_lookup+0x62>
    if(pte_store)
f0101045:	85 db                	test   %ebx,%ebx
f0101047:	74 02                	je     f010104b <page_lookup+0x2e>
        *pte_store = pte;
f0101049:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));
f010104b:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010104d:	c1 e8 0c             	shr    $0xc,%eax
f0101050:	3b 05 68 f9 11 f0    	cmp    0xf011f968,%eax
f0101056:	72 1c                	jb     f0101074 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101058:	c7 44 24 08 14 43 10 	movl   $0xf0104314,0x8(%esp)
f010105f:	f0 
f0101060:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101067:	00 
f0101068:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f010106f:	e8 20 f0 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101074:	c1 e0 03             	shl    $0x3,%eax
f0101077:	03 05 70 f9 11 f0    	add    0xf011f970,%eax
f010107d:	eb 05                	jmp    f0101084 <page_lookup+0x67>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir, va, 0);
    if (!pte) return NULL;
f010107f:	b8 00 00 00 00       	mov    $0x0,%eax
    if(pte_store)
        *pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0101084:	83 c4 14             	add    $0x14,%esp
f0101087:	5b                   	pop    %ebx
f0101088:	5d                   	pop    %ebp
f0101089:	c3                   	ret    

f010108a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010108a:	55                   	push   %ebp
f010108b:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010108d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101090:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101093:	5d                   	pop    %ebp
f0101094:	c3                   	ret    

f0101095 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101095:	55                   	push   %ebp
f0101096:	89 e5                	mov    %esp,%ebp
f0101098:	56                   	push   %esi
f0101099:	53                   	push   %ebx
f010109a:	83 ec 20             	sub    $0x20,%esp
f010109d:	8b 75 08             	mov    0x8(%ebp),%esi
f01010a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t *pte;
    struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f01010a3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ae:	89 34 24             	mov    %esi,(%esp)
f01010b1:	e8 67 ff ff ff       	call   f010101d <page_lookup>
    if(!pp) return;
f01010b6:	85 c0                	test   %eax,%eax
f01010b8:	74 1d                	je     f01010d7 <page_remove+0x42>

    page_decref(pp); // The physical page will be freed if the refcount reaches 0.
f01010ba:	89 04 24             	mov    %eax,(%esp)
f01010bd:	e8 d0 fd ff ff       	call   f0100e92 <page_decref>
    *pte = 0; // The pg table entry corresponding to 'va' should be set to 0.
f01010c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010c5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    tlb_invalidate(pgdir, va); //The TLB must be invalidated if you remove an entry from the page table.
f01010cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010cf:	89 34 24             	mov    %esi,(%esp)
f01010d2:	e8 b3 ff ff ff       	call   f010108a <tlb_invalidate>
}
f01010d7:	83 c4 20             	add    $0x20,%esp
f01010da:	5b                   	pop    %ebx
f01010db:	5e                   	pop    %esi
f01010dc:	5d                   	pop    %ebp
f01010dd:	c3                   	ret    

f01010de <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010de:	55                   	push   %ebp
f01010df:	89 e5                	mov    %esp,%ebp
f01010e1:	57                   	push   %edi
f01010e2:	56                   	push   %esi
f01010e3:	53                   	push   %ebx
f01010e4:	83 ec 1c             	sub    $0x1c,%esp
f01010e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010ea:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir,va,1); //If necessary, on demand, a page table should be allocated and inserted into 'pgdir'.
f01010ed:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010f4:	00 
f01010f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01010fc:	89 04 24             	mov    %eax,(%esp)
f01010ff:	e8 ae fd ff ff       	call   f0100eb2 <pgdir_walk>
f0101104:	89 c3                	mov    %eax,%ebx
    if(!pte) return -E_NO_MEM;
f0101106:	85 c0                	test   %eax,%eax
f0101108:	74 39                	je     f0101143 <page_insert+0x65>

    pp->pp_ref++; // 放在page_remove()上面，防止删除的是同一个页目录项指向的页表的同一个页表项的页面。
f010110a:	66 ff 46 04          	incw   0x4(%esi)
    // If there is already a page mapped at 'va', it should be page_remove()d.
    // The TLB must be invalidated if a page was formerly present at 'va'.
    if(*pte & PTE_P) page_remove(pgdir,va); 
f010110e:	f6 00 01             	testb  $0x1,(%eax)
f0101111:	74 0f                	je     f0101122 <page_insert+0x44>
f0101113:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101117:	8b 45 08             	mov    0x8(%ebp),%eax
f010111a:	89 04 24             	mov    %eax,(%esp)
f010111d:	e8 73 ff ff ff       	call   f0101095 <page_remove>

    *pte = PTE_ADDR(page2pa(pp)) | perm | PTE_P; //映射新页面
f0101122:	8b 55 14             	mov    0x14(%ebp),%edx
f0101125:	83 ca 01             	or     $0x1,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101128:	2b 35 70 f9 11 f0    	sub    0xf011f970,%esi
f010112e:	c1 fe 03             	sar    $0x3,%esi
f0101131:	89 f0                	mov    %esi,%eax
f0101133:	c1 e0 0c             	shl    $0xc,%eax
f0101136:	89 d6                	mov    %edx,%esi
f0101138:	09 c6                	or     %eax,%esi
f010113a:	89 33                	mov    %esi,(%ebx)
	return 0;
f010113c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101141:	eb 05                	jmp    f0101148 <page_insert+0x6a>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
    pte_t *pte = pgdir_walk(pgdir,va,1); //If necessary, on demand, a page table should be allocated and inserted into 'pgdir'.
    if(!pte) return -E_NO_MEM;
f0101143:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    // The TLB must be invalidated if a page was formerly present at 'va'.
    if(*pte & PTE_P) page_remove(pgdir,va); 

    *pte = PTE_ADDR(page2pa(pp)) | perm | PTE_P; //映射新页面
	return 0;
}
f0101148:	83 c4 1c             	add    $0x1c,%esp
f010114b:	5b                   	pop    %ebx
f010114c:	5e                   	pop    %esi
f010114d:	5f                   	pop    %edi
f010114e:	5d                   	pop    %ebp
f010114f:	c3                   	ret    

f0101150 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101150:	55                   	push   %ebp
f0101151:	89 e5                	mov    %esp,%ebp
f0101153:	57                   	push   %edi
f0101154:	56                   	push   %esi
f0101155:	53                   	push   %ebx
f0101156:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101159:	b8 15 00 00 00       	mov    $0x15,%eax
f010115e:	e8 44 f8 ff ff       	call   f01009a7 <nvram_read>
f0101163:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101165:	b8 17 00 00 00       	mov    $0x17,%eax
f010116a:	e8 38 f8 ff ff       	call   f01009a7 <nvram_read>
f010116f:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101171:	b8 34 00 00 00       	mov    $0x34,%eax
f0101176:	e8 2c f8 ff ff       	call   f01009a7 <nvram_read>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010117b:	c1 e0 06             	shl    $0x6,%eax
f010117e:	74 08                	je     f0101188 <mem_init+0x38>
		totalmem = 16 * 1024 + ext16mem;
f0101180:	8d b0 00 40 00 00    	lea    0x4000(%eax),%esi
f0101186:	eb 0e                	jmp    f0101196 <mem_init+0x46>
	else if (extmem)
f0101188:	85 f6                	test   %esi,%esi
f010118a:	74 08                	je     f0101194 <mem_init+0x44>
		totalmem = 1 * 1024 + extmem;
f010118c:	81 c6 00 04 00 00    	add    $0x400,%esi
f0101192:	eb 02                	jmp    f0101196 <mem_init+0x46>
	else
		totalmem = basemem;
f0101194:	89 de                	mov    %ebx,%esi

	npages = totalmem / (PGSIZE / 1024);
f0101196:	89 f0                	mov    %esi,%eax
f0101198:	c1 e8 02             	shr    $0x2,%eax
f010119b:	a3 68 f9 11 f0       	mov    %eax,0xf011f968
	npages_basemem = basemem / (PGSIZE / 1024);
f01011a0:	89 d8                	mov    %ebx,%eax
f01011a2:	c1 e8 02             	shr    $0x2,%eax
f01011a5:	a3 3c f5 11 f0       	mov    %eax,0xf011f53c

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011aa:	89 f0                	mov    %esi,%eax
f01011ac:	29 d8                	sub    %ebx,%eax
f01011ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011b2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01011b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011ba:	c7 04 24 34 43 10 f0 	movl   $0xf0104334,(%esp)
f01011c1:	e8 20 1c 00 00       	call   f0102de6 <cprintf>
		totalmem, basemem, totalmem - basemem);
    cprintf("i386_detect_memory():\n");
f01011c6:	c7 04 24 85 4a 10 f0 	movl   $0xf0104a85,(%esp)
f01011cd:	e8 14 1c 00 00       	call   f0102de6 <cprintf>
    cprintf("npages:%d, npages_basemem = %d\n", npages, npages_basemem);
f01011d2:	a1 3c f5 11 f0       	mov    0xf011f53c,%eax
f01011d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011db:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f01011e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011e4:	c7 04 24 70 43 10 f0 	movl   $0xf0104370,(%esp)
f01011eb:	e8 f6 1b 00 00       	call   f0102de6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011f0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011f5:	e8 2b f7 ff ff       	call   f0100925 <boot_alloc>
f01011fa:	a3 6c f9 11 f0       	mov    %eax,0xf011f96c
	memset(kern_pgdir, 0, PGSIZE);
f01011ff:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101206:	00 
f0101207:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010120e:	00 
f010120f:	89 04 24             	mov    %eax,(%esp)
f0101212:	e8 1b 26 00 00       	call   f0103832 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101217:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010121c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101221:	77 20                	ja     f0101243 <mem_init+0xf3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101223:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101227:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f010122e:	f0 
f010122f:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
f0101236:	00 
f0101237:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010123e:	e8 51 ee ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101243:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101249:	83 ca 05             	or     $0x5,%edx
f010124c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
    pages =(struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f0101252:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101257:	c1 e0 03             	shl    $0x3,%eax
f010125a:	e8 c6 f6 ff ff       	call   f0100925 <boot_alloc>
f010125f:	a3 70 f9 11 f0       	mov    %eax,0xf011f970
    memset(pages, 0, npages*sizeof(struct PageInfo));
f0101264:	8b 15 68 f9 11 f0    	mov    0xf011f968,%edx
f010126a:	c1 e2 03             	shl    $0x3,%edx
f010126d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101271:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101278:	00 
f0101279:	89 04 24             	mov    %eax,(%esp)
f010127c:	e8 b1 25 00 00       	call   f0103832 <memset>
    cprintf("mem_init():\n");
f0101281:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101288:	e8 59 1b 00 00       	call   f0102de6 <cprintf>
	cprintf("kern_pgdir: %x\n", kern_pgdir);
f010128d:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101292:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101296:	c7 04 24 a9 4a 10 f0 	movl   $0xf0104aa9,(%esp)
f010129d:	e8 44 1b 00 00       	call   f0102de6 <cprintf>
	cprintf("pages: %x\n", pages);
f01012a2:	a1 70 f9 11 f0       	mov    0xf011f970,%eax
f01012a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012ab:	c7 04 24 b9 4a 10 f0 	movl   $0xf0104ab9,(%esp)
f01012b2:	e8 2f 1b 00 00       	call   f0102de6 <cprintf>
	cprintf("page_free_list: %x\n", page_free_list);
f01012b7:	a1 38 f5 11 f0       	mov    0xf011f538,%eax
f01012bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c0:	c7 04 24 c4 4a 10 f0 	movl   $0xf0104ac4,(%esp)
f01012c7:	e8 1a 1b 00 00       	call   f0102de6 <cprintf>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012cc:	e8 2b fa ff ff       	call   f0100cfc <page_init>

	check_page_free_list(1);
f01012d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01012d6:	e8 f5 f6 ff ff       	call   f01009d0 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012db:	83 3d 70 f9 11 f0 00 	cmpl   $0x0,0xf011f970
f01012e2:	75 1c                	jne    f0101300 <mem_init+0x1b0>
		panic("'pages' is a null pointer!");
f01012e4:	c7 44 24 08 d8 4a 10 	movl   $0xf0104ad8,0x8(%esp)
f01012eb:	f0 
f01012ec:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f01012f3:	00 
f01012f4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01012fb:	e8 94 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101300:	a1 38 f5 11 f0       	mov    0xf011f538,%eax
f0101305:	bb 00 00 00 00       	mov    $0x0,%ebx
f010130a:	eb 03                	jmp    f010130f <mem_init+0x1bf>
		++nfree;
f010130c:	43                   	inc    %ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010130d:	8b 00                	mov    (%eax),%eax
f010130f:	85 c0                	test   %eax,%eax
f0101311:	75 f9                	jne    f010130c <mem_init+0x1bc>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101313:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131a:	e8 af fa ff ff       	call   f0100dce <page_alloc>
f010131f:	89 c6                	mov    %eax,%esi
f0101321:	85 c0                	test   %eax,%eax
f0101323:	75 24                	jne    f0101349 <mem_init+0x1f9>
f0101325:	c7 44 24 0c f3 4a 10 	movl   $0xf0104af3,0xc(%esp)
f010132c:	f0 
f010132d:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101334:	f0 
f0101335:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f010133c:	00 
f010133d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101344:	e8 4b ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101349:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101350:	e8 79 fa ff ff       	call   f0100dce <page_alloc>
f0101355:	89 c7                	mov    %eax,%edi
f0101357:	85 c0                	test   %eax,%eax
f0101359:	75 24                	jne    f010137f <mem_init+0x22f>
f010135b:	c7 44 24 0c 09 4b 10 	movl   $0xf0104b09,0xc(%esp)
f0101362:	f0 
f0101363:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010136a:	f0 
f010136b:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101372:	00 
f0101373:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010137a:	e8 15 ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010137f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101386:	e8 43 fa ff ff       	call   f0100dce <page_alloc>
f010138b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010138e:	85 c0                	test   %eax,%eax
f0101390:	75 24                	jne    f01013b6 <mem_init+0x266>
f0101392:	c7 44 24 0c 1f 4b 10 	movl   $0xf0104b1f,0xc(%esp)
f0101399:	f0 
f010139a:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01013a1:	f0 
f01013a2:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f01013a9:	00 
f01013aa:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01013b1:	e8 de ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013b6:	39 fe                	cmp    %edi,%esi
f01013b8:	75 24                	jne    f01013de <mem_init+0x28e>
f01013ba:	c7 44 24 0c 35 4b 10 	movl   $0xf0104b35,0xc(%esp)
f01013c1:	f0 
f01013c2:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01013c9:	f0 
f01013ca:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01013d1:	00 
f01013d2:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01013d9:	e8 b6 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013de:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01013e1:	74 05                	je     f01013e8 <mem_init+0x298>
f01013e3:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01013e6:	75 24                	jne    f010140c <mem_init+0x2bc>
f01013e8:	c7 44 24 0c 90 43 10 	movl   $0xf0104390,0xc(%esp)
f01013ef:	f0 
f01013f0:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01013f7:	f0 
f01013f8:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01013ff:	00 
f0101400:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101407:	e8 88 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010140c:	8b 15 70 f9 11 f0    	mov    0xf011f970,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101412:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101417:	c1 e0 0c             	shl    $0xc,%eax
f010141a:	89 f1                	mov    %esi,%ecx
f010141c:	29 d1                	sub    %edx,%ecx
f010141e:	c1 f9 03             	sar    $0x3,%ecx
f0101421:	c1 e1 0c             	shl    $0xc,%ecx
f0101424:	39 c1                	cmp    %eax,%ecx
f0101426:	72 24                	jb     f010144c <mem_init+0x2fc>
f0101428:	c7 44 24 0c 47 4b 10 	movl   $0xf0104b47,0xc(%esp)
f010142f:	f0 
f0101430:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101437:	f0 
f0101438:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f010143f:	00 
f0101440:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101447:	e8 48 ec ff ff       	call   f0100094 <_panic>
f010144c:	89 f9                	mov    %edi,%ecx
f010144e:	29 d1                	sub    %edx,%ecx
f0101450:	c1 f9 03             	sar    $0x3,%ecx
f0101453:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101456:	39 c8                	cmp    %ecx,%eax
f0101458:	77 24                	ja     f010147e <mem_init+0x32e>
f010145a:	c7 44 24 0c 64 4b 10 	movl   $0xf0104b64,0xc(%esp)
f0101461:	f0 
f0101462:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101469:	f0 
f010146a:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0101471:	00 
f0101472:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101479:	e8 16 ec ff ff       	call   f0100094 <_panic>
f010147e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101481:	29 d1                	sub    %edx,%ecx
f0101483:	89 ca                	mov    %ecx,%edx
f0101485:	c1 fa 03             	sar    $0x3,%edx
f0101488:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010148b:	39 d0                	cmp    %edx,%eax
f010148d:	77 24                	ja     f01014b3 <mem_init+0x363>
f010148f:	c7 44 24 0c 81 4b 10 	movl   $0xf0104b81,0xc(%esp)
f0101496:	f0 
f0101497:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010149e:	f0 
f010149f:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f01014a6:	00 
f01014a7:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01014ae:	e8 e1 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014b3:	a1 38 f5 11 f0       	mov    0xf011f538,%eax
f01014b8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014bb:	c7 05 38 f5 11 f0 00 	movl   $0x0,0xf011f538
f01014c2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014cc:	e8 fd f8 ff ff       	call   f0100dce <page_alloc>
f01014d1:	85 c0                	test   %eax,%eax
f01014d3:	74 24                	je     f01014f9 <mem_init+0x3a9>
f01014d5:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f01014dc:	f0 
f01014dd:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01014e4:	f0 
f01014e5:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01014ec:	00 
f01014ed:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01014f4:	e8 9b eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014f9:	89 34 24             	mov    %esi,(%esp)
f01014fc:	e8 51 f9 ff ff       	call   f0100e52 <page_free>
	page_free(pp1);
f0101501:	89 3c 24             	mov    %edi,(%esp)
f0101504:	e8 49 f9 ff ff       	call   f0100e52 <page_free>
	page_free(pp2);
f0101509:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010150c:	89 04 24             	mov    %eax,(%esp)
f010150f:	e8 3e f9 ff ff       	call   f0100e52 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101514:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010151b:	e8 ae f8 ff ff       	call   f0100dce <page_alloc>
f0101520:	89 c6                	mov    %eax,%esi
f0101522:	85 c0                	test   %eax,%eax
f0101524:	75 24                	jne    f010154a <mem_init+0x3fa>
f0101526:	c7 44 24 0c f3 4a 10 	movl   $0xf0104af3,0xc(%esp)
f010152d:	f0 
f010152e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101535:	f0 
f0101536:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f010153d:	00 
f010153e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101545:	e8 4a eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010154a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101551:	e8 78 f8 ff ff       	call   f0100dce <page_alloc>
f0101556:	89 c7                	mov    %eax,%edi
f0101558:	85 c0                	test   %eax,%eax
f010155a:	75 24                	jne    f0101580 <mem_init+0x430>
f010155c:	c7 44 24 0c 09 4b 10 	movl   $0xf0104b09,0xc(%esp)
f0101563:	f0 
f0101564:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010156b:	f0 
f010156c:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101573:	00 
f0101574:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010157b:	e8 14 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101580:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101587:	e8 42 f8 ff ff       	call   f0100dce <page_alloc>
f010158c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010158f:	85 c0                	test   %eax,%eax
f0101591:	75 24                	jne    f01015b7 <mem_init+0x467>
f0101593:	c7 44 24 0c 1f 4b 10 	movl   $0xf0104b1f,0xc(%esp)
f010159a:	f0 
f010159b:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01015a2:	f0 
f01015a3:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01015aa:	00 
f01015ab:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01015b2:	e8 dd ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015b7:	39 fe                	cmp    %edi,%esi
f01015b9:	75 24                	jne    f01015df <mem_init+0x48f>
f01015bb:	c7 44 24 0c 35 4b 10 	movl   $0xf0104b35,0xc(%esp)
f01015c2:	f0 
f01015c3:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01015ca:	f0 
f01015cb:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01015d2:	00 
f01015d3:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01015da:	e8 b5 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015df:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015e2:	74 05                	je     f01015e9 <mem_init+0x499>
f01015e4:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01015e7:	75 24                	jne    f010160d <mem_init+0x4bd>
f01015e9:	c7 44 24 0c 90 43 10 	movl   $0xf0104390,0xc(%esp)
f01015f0:	f0 
f01015f1:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01015f8:	f0 
f01015f9:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101600:	00 
f0101601:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101608:	e8 87 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010160d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101614:	e8 b5 f7 ff ff       	call   f0100dce <page_alloc>
f0101619:	85 c0                	test   %eax,%eax
f010161b:	74 24                	je     f0101641 <mem_init+0x4f1>
f010161d:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f0101624:	f0 
f0101625:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010162c:	f0 
f010162d:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101634:	00 
f0101635:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010163c:	e8 53 ea ff ff       	call   f0100094 <_panic>
f0101641:	89 f0                	mov    %esi,%eax
f0101643:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0101649:	c1 f8 03             	sar    $0x3,%eax
f010164c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164f:	89 c2                	mov    %eax,%edx
f0101651:	c1 ea 0c             	shr    $0xc,%edx
f0101654:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f010165a:	72 20                	jb     f010167c <mem_init+0x52c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010165c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101660:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0101667:	f0 
f0101668:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010166f:	00 
f0101670:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0101677:	e8 18 ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010167c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101683:	00 
f0101684:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010168b:	00 
	return (void *)(pa + KERNBASE);
f010168c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101691:	89 04 24             	mov    %eax,(%esp)
f0101694:	e8 99 21 00 00       	call   f0103832 <memset>
	page_free(pp0);
f0101699:	89 34 24             	mov    %esi,(%esp)
f010169c:	e8 b1 f7 ff ff       	call   f0100e52 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016a1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016a8:	e8 21 f7 ff ff       	call   f0100dce <page_alloc>
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	75 24                	jne    f01016d5 <mem_init+0x585>
f01016b1:	c7 44 24 0c ad 4b 10 	movl   $0xf0104bad,0xc(%esp)
f01016b8:	f0 
f01016b9:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01016c0:	f0 
f01016c1:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f01016c8:	00 
f01016c9:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01016d0:	e8 bf e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016d5:	39 c6                	cmp    %eax,%esi
f01016d7:	74 24                	je     f01016fd <mem_init+0x5ad>
f01016d9:	c7 44 24 0c cb 4b 10 	movl   $0xf0104bcb,0xc(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01016e8:	f0 
f01016e9:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f01016f0:	00 
f01016f1:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01016f8:	e8 97 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016fd:	89 f2                	mov    %esi,%edx
f01016ff:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0101705:	c1 fa 03             	sar    $0x3,%edx
f0101708:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010170b:	89 d0                	mov    %edx,%eax
f010170d:	c1 e8 0c             	shr    $0xc,%eax
f0101710:	3b 05 68 f9 11 f0    	cmp    0xf011f968,%eax
f0101716:	72 20                	jb     f0101738 <mem_init+0x5e8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101718:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010171c:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0101723:	f0 
f0101724:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010172b:	00 
f010172c:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0101733:	e8 5c e9 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101738:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010173e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101744:	80 38 00             	cmpb   $0x0,(%eax)
f0101747:	74 24                	je     f010176d <mem_init+0x61d>
f0101749:	c7 44 24 0c db 4b 10 	movl   $0xf0104bdb,0xc(%esp)
f0101750:	f0 
f0101751:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101758:	f0 
f0101759:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0101760:	00 
f0101761:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101768:	e8 27 e9 ff ff       	call   f0100094 <_panic>
f010176d:	40                   	inc    %eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010176e:	39 d0                	cmp    %edx,%eax
f0101770:	75 d2                	jne    f0101744 <mem_init+0x5f4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101772:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101775:	89 15 38 f5 11 f0    	mov    %edx,0xf011f538

	// free the pages we took
	page_free(pp0);
f010177b:	89 34 24             	mov    %esi,(%esp)
f010177e:	e8 cf f6 ff ff       	call   f0100e52 <page_free>
	page_free(pp1);
f0101783:	89 3c 24             	mov    %edi,(%esp)
f0101786:	e8 c7 f6 ff ff       	call   f0100e52 <page_free>
	page_free(pp2);
f010178b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010178e:	89 04 24             	mov    %eax,(%esp)
f0101791:	e8 bc f6 ff ff       	call   f0100e52 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101796:	a1 38 f5 11 f0       	mov    0xf011f538,%eax
f010179b:	eb 03                	jmp    f01017a0 <mem_init+0x650>
		--nfree;
f010179d:	4b                   	dec    %ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179e:	8b 00                	mov    (%eax),%eax
f01017a0:	85 c0                	test   %eax,%eax
f01017a2:	75 f9                	jne    f010179d <mem_init+0x64d>
		--nfree;
	assert(nfree == 0);
f01017a4:	85 db                	test   %ebx,%ebx
f01017a6:	74 24                	je     f01017cc <mem_init+0x67c>
f01017a8:	c7 44 24 0c e5 4b 10 	movl   $0xf0104be5,0xc(%esp)
f01017af:	f0 
f01017b0:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01017b7:	f0 
f01017b8:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f01017bf:	00 
f01017c0:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01017c7:	e8 c8 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017cc:	c7 04 24 b0 43 10 f0 	movl   $0xf01043b0,(%esp)
f01017d3:	e8 0e 16 00 00       	call   f0102de6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017df:	e8 ea f5 ff ff       	call   f0100dce <page_alloc>
f01017e4:	89 c7                	mov    %eax,%edi
f01017e6:	85 c0                	test   %eax,%eax
f01017e8:	75 24                	jne    f010180e <mem_init+0x6be>
f01017ea:	c7 44 24 0c f3 4a 10 	movl   $0xf0104af3,0xc(%esp)
f01017f1:	f0 
f01017f2:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01017f9:	f0 
f01017fa:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101801:	00 
f0101802:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101809:	e8 86 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010180e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101815:	e8 b4 f5 ff ff       	call   f0100dce <page_alloc>
f010181a:	89 c6                	mov    %eax,%esi
f010181c:	85 c0                	test   %eax,%eax
f010181e:	75 24                	jne    f0101844 <mem_init+0x6f4>
f0101820:	c7 44 24 0c 09 4b 10 	movl   $0xf0104b09,0xc(%esp)
f0101827:	f0 
f0101828:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010182f:	f0 
f0101830:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101837:	00 
f0101838:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010183f:	e8 50 e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101844:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010184b:	e8 7e f5 ff ff       	call   f0100dce <page_alloc>
f0101850:	89 c3                	mov    %eax,%ebx
f0101852:	85 c0                	test   %eax,%eax
f0101854:	75 24                	jne    f010187a <mem_init+0x72a>
f0101856:	c7 44 24 0c 1f 4b 10 	movl   $0xf0104b1f,0xc(%esp)
f010185d:	f0 
f010185e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101865:	f0 
f0101866:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f010186d:	00 
f010186e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101875:	e8 1a e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010187a:	39 f7                	cmp    %esi,%edi
f010187c:	75 24                	jne    f01018a2 <mem_init+0x752>
f010187e:	c7 44 24 0c 35 4b 10 	movl   $0xf0104b35,0xc(%esp)
f0101885:	f0 
f0101886:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010188d:	f0 
f010188e:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101895:	00 
f0101896:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010189d:	e8 f2 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018a2:	39 c6                	cmp    %eax,%esi
f01018a4:	74 04                	je     f01018aa <mem_init+0x75a>
f01018a6:	39 c7                	cmp    %eax,%edi
f01018a8:	75 24                	jne    f01018ce <mem_init+0x77e>
f01018aa:	c7 44 24 0c 90 43 10 	movl   $0xf0104390,0xc(%esp)
f01018b1:	f0 
f01018b2:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01018b9:	f0 
f01018ba:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01018c1:	00 
f01018c2:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01018c9:	e8 c6 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018ce:	8b 15 38 f5 11 f0    	mov    0xf011f538,%edx
f01018d4:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01018d7:	c7 05 38 f5 11 f0 00 	movl   $0x0,0xf011f538
f01018de:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018e8:	e8 e1 f4 ff ff       	call   f0100dce <page_alloc>
f01018ed:	85 c0                	test   %eax,%eax
f01018ef:	74 24                	je     f0101915 <mem_init+0x7c5>
f01018f1:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f01018f8:	f0 
f01018f9:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101900:	f0 
f0101901:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101908:	00 
f0101909:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101910:	e8 7f e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101915:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101918:	89 44 24 08          	mov    %eax,0x8(%esp)
f010191c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101923:	00 
f0101924:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101929:	89 04 24             	mov    %eax,(%esp)
f010192c:	e8 ec f6 ff ff       	call   f010101d <page_lookup>
f0101931:	85 c0                	test   %eax,%eax
f0101933:	74 24                	je     f0101959 <mem_init+0x809>
f0101935:	c7 44 24 0c d0 43 10 	movl   $0xf01043d0,0xc(%esp)
f010193c:	f0 
f010193d:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101944:	f0 
f0101945:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f010194c:	00 
f010194d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101954:	e8 3b e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101959:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101960:	00 
f0101961:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101968:	00 
f0101969:	89 74 24 04          	mov    %esi,0x4(%esp)
f010196d:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101972:	89 04 24             	mov    %eax,(%esp)
f0101975:	e8 64 f7 ff ff       	call   f01010de <page_insert>
f010197a:	85 c0                	test   %eax,%eax
f010197c:	78 24                	js     f01019a2 <mem_init+0x852>
f010197e:	c7 44 24 0c 08 44 10 	movl   $0xf0104408,0xc(%esp)
f0101985:	f0 
f0101986:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010198d:	f0 
f010198e:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101995:	00 
f0101996:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010199d:	e8 f2 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019a2:	89 3c 24             	mov    %edi,(%esp)
f01019a5:	e8 a8 f4 ff ff       	call   f0100e52 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019aa:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019b1:	00 
f01019b2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019b9:	00 
f01019ba:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019be:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f01019c3:	89 04 24             	mov    %eax,(%esp)
f01019c6:	e8 13 f7 ff ff       	call   f01010de <page_insert>
f01019cb:	85 c0                	test   %eax,%eax
f01019cd:	74 24                	je     f01019f3 <mem_init+0x8a3>
f01019cf:	c7 44 24 0c 38 44 10 	movl   $0xf0104438,0xc(%esp)
f01019d6:	f0 
f01019d7:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01019de:	f0 
f01019df:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f01019e6:	00 
f01019e7:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01019ee:	e8 a1 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019f3:	8b 0d 6c f9 11 f0    	mov    0xf011f96c,%ecx
f01019f9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019fc:	a1 70 f9 11 f0       	mov    0xf011f970,%eax
f0101a01:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a04:	8b 11                	mov    (%ecx),%edx
f0101a06:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a0c:	89 f8                	mov    %edi,%eax
f0101a0e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a11:	c1 f8 03             	sar    $0x3,%eax
f0101a14:	c1 e0 0c             	shl    $0xc,%eax
f0101a17:	39 c2                	cmp    %eax,%edx
f0101a19:	74 24                	je     f0101a3f <mem_init+0x8ef>
f0101a1b:	c7 44 24 0c 68 44 10 	movl   $0xf0104468,0xc(%esp)
f0101a22:	f0 
f0101a23:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101a2a:	f0 
f0101a2b:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101a32:	00 
f0101a33:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101a3a:	e8 55 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a47:	e8 6c ee ff ff       	call   f01008b8 <check_va2pa>
f0101a4c:	89 f2                	mov    %esi,%edx
f0101a4e:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a51:	c1 fa 03             	sar    $0x3,%edx
f0101a54:	c1 e2 0c             	shl    $0xc,%edx
f0101a57:	39 d0                	cmp    %edx,%eax
f0101a59:	74 24                	je     f0101a7f <mem_init+0x92f>
f0101a5b:	c7 44 24 0c 90 44 10 	movl   $0xf0104490,0xc(%esp)
f0101a62:	f0 
f0101a63:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101a6a:	f0 
f0101a6b:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101a72:	00 
f0101a73:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101a7a:	e8 15 e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a7f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a84:	74 24                	je     f0101aaa <mem_init+0x95a>
f0101a86:	c7 44 24 0c f0 4b 10 	movl   $0xf0104bf0,0xc(%esp)
f0101a8d:	f0 
f0101a8e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101a95:	f0 
f0101a96:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101a9d:	00 
f0101a9e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101aa5:	e8 ea e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101aaa:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101aaf:	74 24                	je     f0101ad5 <mem_init+0x985>
f0101ab1:	c7 44 24 0c 01 4c 10 	movl   $0xf0104c01,0xc(%esp)
f0101ab8:	f0 
f0101ab9:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101ac0:	f0 
f0101ac1:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101ac8:	00 
f0101ac9:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101ad0:	e8 bf e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101adc:	00 
f0101add:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ae4:	00 
f0101ae5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ae9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101aec:	89 14 24             	mov    %edx,(%esp)
f0101aef:	e8 ea f5 ff ff       	call   f01010de <page_insert>
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	74 24                	je     f0101b1c <mem_init+0x9cc>
f0101af8:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f0101aff:	f0 
f0101b00:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101b07:	f0 
f0101b08:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101b0f:	00 
f0101b10:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101b17:	e8 78 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b1c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b21:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101b26:	e8 8d ed ff ff       	call   f01008b8 <check_va2pa>
f0101b2b:	89 da                	mov    %ebx,%edx
f0101b2d:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0101b33:	c1 fa 03             	sar    $0x3,%edx
f0101b36:	c1 e2 0c             	shl    $0xc,%edx
f0101b39:	39 d0                	cmp    %edx,%eax
f0101b3b:	74 24                	je     f0101b61 <mem_init+0xa11>
f0101b3d:	c7 44 24 0c fc 44 10 	movl   $0xf01044fc,0xc(%esp)
f0101b44:	f0 
f0101b45:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101b4c:	f0 
f0101b4d:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101b54:	00 
f0101b55:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101b5c:	e8 33 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b61:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b66:	74 24                	je     f0101b8c <mem_init+0xa3c>
f0101b68:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0101b6f:	f0 
f0101b70:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101b77:	f0 
f0101b78:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101b7f:	00 
f0101b80:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101b87:	e8 08 e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b8c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b93:	e8 36 f2 ff ff       	call   f0100dce <page_alloc>
f0101b98:	85 c0                	test   %eax,%eax
f0101b9a:	74 24                	je     f0101bc0 <mem_init+0xa70>
f0101b9c:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101bab:	f0 
f0101bac:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101bb3:	00 
f0101bb4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101bbb:	e8 d4 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bc0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bc7:	00 
f0101bc8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bcf:	00 
f0101bd0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bd4:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101bd9:	89 04 24             	mov    %eax,(%esp)
f0101bdc:	e8 fd f4 ff ff       	call   f01010de <page_insert>
f0101be1:	85 c0                	test   %eax,%eax
f0101be3:	74 24                	je     f0101c09 <mem_init+0xab9>
f0101be5:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f0101bec:	f0 
f0101bed:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101bf4:	f0 
f0101bf5:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101bfc:	00 
f0101bfd:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101c04:	e8 8b e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c09:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c0e:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101c13:	e8 a0 ec ff ff       	call   f01008b8 <check_va2pa>
f0101c18:	89 da                	mov    %ebx,%edx
f0101c1a:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0101c20:	c1 fa 03             	sar    $0x3,%edx
f0101c23:	c1 e2 0c             	shl    $0xc,%edx
f0101c26:	39 d0                	cmp    %edx,%eax
f0101c28:	74 24                	je     f0101c4e <mem_init+0xafe>
f0101c2a:	c7 44 24 0c fc 44 10 	movl   $0xf01044fc,0xc(%esp)
f0101c31:	f0 
f0101c32:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101c39:	f0 
f0101c3a:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101c41:	00 
f0101c42:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101c49:	e8 46 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c4e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c53:	74 24                	je     f0101c79 <mem_init+0xb29>
f0101c55:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0101c5c:	f0 
f0101c5d:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101c64:	f0 
f0101c65:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c6c:	00 
f0101c6d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101c74:	e8 1b e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c80:	e8 49 f1 ff ff       	call   f0100dce <page_alloc>
f0101c85:	85 c0                	test   %eax,%eax
f0101c87:	74 24                	je     f0101cad <mem_init+0xb5d>
f0101c89:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f0101c90:	f0 
f0101c91:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101c98:	f0 
f0101c99:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101ca0:	00 
f0101ca1:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101ca8:	e8 e7 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cad:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
f0101cb3:	8b 02                	mov    (%edx),%eax
f0101cb5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cba:	89 c1                	mov    %eax,%ecx
f0101cbc:	c1 e9 0c             	shr    $0xc,%ecx
f0101cbf:	3b 0d 68 f9 11 f0    	cmp    0xf011f968,%ecx
f0101cc5:	72 20                	jb     f0101ce7 <mem_init+0xb97>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ccb:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101ce2:	e8 ad e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101ce7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cec:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101cef:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cf6:	00 
f0101cf7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101cfe:	00 
f0101cff:	89 14 24             	mov    %edx,(%esp)
f0101d02:	e8 ab f1 ff ff       	call   f0100eb2 <pgdir_walk>
f0101d07:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d0a:	83 c2 04             	add    $0x4,%edx
f0101d0d:	39 d0                	cmp    %edx,%eax
f0101d0f:	74 24                	je     f0101d35 <mem_init+0xbe5>
f0101d11:	c7 44 24 0c 2c 45 10 	movl   $0xf010452c,0xc(%esp)
f0101d18:	f0 
f0101d19:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101d20:	f0 
f0101d21:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101d28:	00 
f0101d29:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101d30:	e8 5f e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d35:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d3c:	00 
f0101d3d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d44:	00 
f0101d45:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d49:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101d4e:	89 04 24             	mov    %eax,(%esp)
f0101d51:	e8 88 f3 ff ff       	call   f01010de <page_insert>
f0101d56:	85 c0                	test   %eax,%eax
f0101d58:	74 24                	je     f0101d7e <mem_init+0xc2e>
f0101d5a:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0101d61:	f0 
f0101d62:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101d71:	00 
f0101d72:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101d79:	e8 16 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d7e:	8b 0d 6c f9 11 f0    	mov    0xf011f96c,%ecx
f0101d84:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101d87:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d8c:	89 c8                	mov    %ecx,%eax
f0101d8e:	e8 25 eb ff ff       	call   f01008b8 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d93:	89 da                	mov    %ebx,%edx
f0101d95:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0101d9b:	c1 fa 03             	sar    $0x3,%edx
f0101d9e:	c1 e2 0c             	shl    $0xc,%edx
f0101da1:	39 d0                	cmp    %edx,%eax
f0101da3:	74 24                	je     f0101dc9 <mem_init+0xc79>
f0101da5:	c7 44 24 0c fc 44 10 	movl   $0xf01044fc,0xc(%esp)
f0101dac:	f0 
f0101dad:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101db4:	f0 
f0101db5:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101dbc:	00 
f0101dbd:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101dc4:	e8 cb e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dc9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dce:	74 24                	je     f0101df4 <mem_init+0xca4>
f0101dd0:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0101dd7:	f0 
f0101dd8:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101ddf:	f0 
f0101de0:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101de7:	00 
f0101de8:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101def:	e8 a0 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101df4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dfb:	00 
f0101dfc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e03:	00 
f0101e04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e07:	89 04 24             	mov    %eax,(%esp)
f0101e0a:	e8 a3 f0 ff ff       	call   f0100eb2 <pgdir_walk>
f0101e0f:	f6 00 04             	testb  $0x4,(%eax)
f0101e12:	75 24                	jne    f0101e38 <mem_init+0xce8>
f0101e14:	c7 44 24 0c ac 45 10 	movl   $0xf01045ac,0xc(%esp)
f0101e1b:	f0 
f0101e1c:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101e23:	f0 
f0101e24:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101e2b:	00 
f0101e2c:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101e33:	e8 5c e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e38:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101e3d:	f6 00 04             	testb  $0x4,(%eax)
f0101e40:	75 24                	jne    f0101e66 <mem_init+0xd16>
f0101e42:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0101e49:	f0 
f0101e4a:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101e51:	f0 
f0101e52:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101e59:	00 
f0101e5a:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101e61:	e8 2e e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e66:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e6d:	00 
f0101e6e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e75:	00 
f0101e76:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e7a:	89 04 24             	mov    %eax,(%esp)
f0101e7d:	e8 5c f2 ff ff       	call   f01010de <page_insert>
f0101e82:	85 c0                	test   %eax,%eax
f0101e84:	74 24                	je     f0101eaa <mem_init+0xd5a>
f0101e86:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f0101e8d:	f0 
f0101e8e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101e95:	f0 
f0101e96:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101e9d:	00 
f0101e9e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101ea5:	e8 ea e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101eaa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eb1:	00 
f0101eb2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101eb9:	00 
f0101eba:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101ebf:	89 04 24             	mov    %eax,(%esp)
f0101ec2:	e8 eb ef ff ff       	call   f0100eb2 <pgdir_walk>
f0101ec7:	f6 00 02             	testb  $0x2,(%eax)
f0101eca:	75 24                	jne    f0101ef0 <mem_init+0xda0>
f0101ecc:	c7 44 24 0c e0 45 10 	movl   $0xf01045e0,0xc(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101edb:	f0 
f0101edc:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101ee3:	00 
f0101ee4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101eeb:	e8 a4 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ef0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ef7:	00 
f0101ef8:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101eff:	00 
f0101f00:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101f05:	89 04 24             	mov    %eax,(%esp)
f0101f08:	e8 a5 ef ff ff       	call   f0100eb2 <pgdir_walk>
f0101f0d:	f6 00 04             	testb  $0x4,(%eax)
f0101f10:	74 24                	je     f0101f36 <mem_init+0xde6>
f0101f12:	c7 44 24 0c 14 46 10 	movl   $0xf0104614,0xc(%esp)
f0101f19:	f0 
f0101f1a:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101f21:	f0 
f0101f22:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101f29:	00 
f0101f2a:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101f31:	e8 5e e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f36:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f3d:	00 
f0101f3e:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f45:	00 
f0101f46:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f4a:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101f4f:	89 04 24             	mov    %eax,(%esp)
f0101f52:	e8 87 f1 ff ff       	call   f01010de <page_insert>
f0101f57:	85 c0                	test   %eax,%eax
f0101f59:	78 24                	js     f0101f7f <mem_init+0xe2f>
f0101f5b:	c7 44 24 0c 4c 46 10 	movl   $0xf010464c,0xc(%esp)
f0101f62:	f0 
f0101f63:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101f6a:	f0 
f0101f6b:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101f72:	00 
f0101f73:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101f7a:	e8 15 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f7f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f86:	00 
f0101f87:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f8e:	00 
f0101f8f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f93:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101f98:	89 04 24             	mov    %eax,(%esp)
f0101f9b:	e8 3e f1 ff ff       	call   f01010de <page_insert>
f0101fa0:	85 c0                	test   %eax,%eax
f0101fa2:	74 24                	je     f0101fc8 <mem_init+0xe78>
f0101fa4:	c7 44 24 0c 84 46 10 	movl   $0xf0104684,0xc(%esp)
f0101fab:	f0 
f0101fac:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101fb3:	f0 
f0101fb4:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101fbb:	00 
f0101fbc:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0101fc3:	e8 cc e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fc8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fcf:	00 
f0101fd0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fd7:	00 
f0101fd8:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101fdd:	89 04 24             	mov    %eax,(%esp)
f0101fe0:	e8 cd ee ff ff       	call   f0100eb2 <pgdir_walk>
f0101fe5:	f6 00 04             	testb  $0x4,(%eax)
f0101fe8:	74 24                	je     f010200e <mem_init+0xebe>
f0101fea:	c7 44 24 0c 14 46 10 	movl   $0xf0104614,0xc(%esp)
f0101ff1:	f0 
f0101ff2:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0101ff9:	f0 
f0101ffa:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0102001:	00 
f0102002:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102009:	e8 86 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010200e:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102013:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102016:	ba 00 00 00 00       	mov    $0x0,%edx
f010201b:	e8 98 e8 ff ff       	call   f01008b8 <check_va2pa>
f0102020:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102023:	89 f0                	mov    %esi,%eax
f0102025:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f010202b:	c1 f8 03             	sar    $0x3,%eax
f010202e:	c1 e0 0c             	shl    $0xc,%eax
f0102031:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102034:	74 24                	je     f010205a <mem_init+0xf0a>
f0102036:	c7 44 24 0c c0 46 10 	movl   $0xf01046c0,0xc(%esp)
f010203d:	f0 
f010203e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102045:	f0 
f0102046:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010204d:	00 
f010204e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102055:	e8 3a e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010205a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010205f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102062:	e8 51 e8 ff ff       	call   f01008b8 <check_va2pa>
f0102067:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010206a:	74 24                	je     f0102090 <mem_init+0xf40>
f010206c:	c7 44 24 0c ec 46 10 	movl   $0xf01046ec,0xc(%esp)
f0102073:	f0 
f0102074:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010207b:	f0 
f010207c:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102083:	00 
f0102084:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010208b:	e8 04 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102090:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0102095:	74 24                	je     f01020bb <mem_init+0xf6b>
f0102097:	c7 44 24 0c 39 4c 10 	movl   $0xf0104c39,0xc(%esp)
f010209e:	f0 
f010209f:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01020a6:	f0 
f01020a7:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01020ae:	00 
f01020af:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01020b6:	e8 d9 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020bb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020c0:	74 24                	je     f01020e6 <mem_init+0xf96>
f01020c2:	c7 44 24 0c 4a 4c 10 	movl   $0xf0104c4a,0xc(%esp)
f01020c9:	f0 
f01020ca:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01020d1:	f0 
f01020d2:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01020d9:	00 
f01020da:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01020e1:	e8 ae df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020e6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020ed:	e8 dc ec ff ff       	call   f0100dce <page_alloc>
f01020f2:	85 c0                	test   %eax,%eax
f01020f4:	74 04                	je     f01020fa <mem_init+0xfaa>
f01020f6:	39 c3                	cmp    %eax,%ebx
f01020f8:	74 24                	je     f010211e <mem_init+0xfce>
f01020fa:	c7 44 24 0c 1c 47 10 	movl   $0xf010471c,0xc(%esp)
f0102101:	f0 
f0102102:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102109:	f0 
f010210a:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0102111:	00 
f0102112:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102119:	e8 76 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010211e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102125:	00 
f0102126:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f010212b:	89 04 24             	mov    %eax,(%esp)
f010212e:	e8 62 ef ff ff       	call   f0101095 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102133:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
f0102139:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010213c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102141:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102144:	e8 6f e7 ff ff       	call   f01008b8 <check_va2pa>
f0102149:	83 f8 ff             	cmp    $0xffffffff,%eax
f010214c:	74 24                	je     f0102172 <mem_init+0x1022>
f010214e:	c7 44 24 0c 40 47 10 	movl   $0xf0104740,0xc(%esp)
f0102155:	f0 
f0102156:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010215d:	f0 
f010215e:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102165:	00 
f0102166:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010216d:	e8 22 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102172:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102177:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010217a:	e8 39 e7 ff ff       	call   f01008b8 <check_va2pa>
f010217f:	89 f2                	mov    %esi,%edx
f0102181:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0102187:	c1 fa 03             	sar    $0x3,%edx
f010218a:	c1 e2 0c             	shl    $0xc,%edx
f010218d:	39 d0                	cmp    %edx,%eax
f010218f:	74 24                	je     f01021b5 <mem_init+0x1065>
f0102191:	c7 44 24 0c ec 46 10 	movl   $0xf01046ec,0xc(%esp)
f0102198:	f0 
f0102199:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01021a0:	f0 
f01021a1:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01021a8:	00 
f01021a9:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01021b0:	e8 df de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021b5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01021ba:	74 24                	je     f01021e0 <mem_init+0x1090>
f01021bc:	c7 44 24 0c f0 4b 10 	movl   $0xf0104bf0,0xc(%esp)
f01021c3:	f0 
f01021c4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01021cb:	f0 
f01021cc:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01021d3:	00 
f01021d4:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01021db:	e8 b4 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021e0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021e5:	74 24                	je     f010220b <mem_init+0x10bb>
f01021e7:	c7 44 24 0c 4a 4c 10 	movl   $0xf0104c4a,0xc(%esp)
f01021ee:	f0 
f01021ef:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01021f6:	f0 
f01021f7:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01021fe:	00 
f01021ff:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102206:	e8 89 de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010220b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102212:	00 
f0102213:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010221a:	00 
f010221b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010221f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102222:	89 0c 24             	mov    %ecx,(%esp)
f0102225:	e8 b4 ee ff ff       	call   f01010de <page_insert>
f010222a:	85 c0                	test   %eax,%eax
f010222c:	74 24                	je     f0102252 <mem_init+0x1102>
f010222e:	c7 44 24 0c 64 47 10 	movl   $0xf0104764,0xc(%esp)
f0102235:	f0 
f0102236:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010223d:	f0 
f010223e:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0102245:	00 
f0102246:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010224d:	e8 42 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102252:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102257:	75 24                	jne    f010227d <mem_init+0x112d>
f0102259:	c7 44 24 0c 5b 4c 10 	movl   $0xf0104c5b,0xc(%esp)
f0102260:	f0 
f0102261:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102268:	f0 
f0102269:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0102270:	00 
f0102271:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102278:	e8 17 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010227d:	83 3e 00             	cmpl   $0x0,(%esi)
f0102280:	74 24                	je     f01022a6 <mem_init+0x1156>
f0102282:	c7 44 24 0c 67 4c 10 	movl   $0xf0104c67,0xc(%esp)
f0102289:	f0 
f010228a:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102291:	f0 
f0102292:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102299:	00 
f010229a:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01022a1:	e8 ee dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022a6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022ad:	00 
f01022ae:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f01022b3:	89 04 24             	mov    %eax,(%esp)
f01022b6:	e8 da ed ff ff       	call   f0101095 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022bb:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f01022c0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01022c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01022c8:	e8 eb e5 ff ff       	call   f01008b8 <check_va2pa>
f01022cd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d0:	74 24                	je     f01022f6 <mem_init+0x11a6>
f01022d2:	c7 44 24 0c 40 47 10 	movl   $0xf0104740,0xc(%esp)
f01022d9:	f0 
f01022da:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01022e1:	f0 
f01022e2:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01022e9:	00 
f01022ea:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01022f1:	e8 9e dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022f6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022fe:	e8 b5 e5 ff ff       	call   f01008b8 <check_va2pa>
f0102303:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102306:	74 24                	je     f010232c <mem_init+0x11dc>
f0102308:	c7 44 24 0c 9c 47 10 	movl   $0xf010479c,0xc(%esp)
f010230f:	f0 
f0102310:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102317:	f0 
f0102318:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f010231f:	00 
f0102320:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102327:	e8 68 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010232c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102331:	74 24                	je     f0102357 <mem_init+0x1207>
f0102333:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f010233a:	f0 
f010233b:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102342:	f0 
f0102343:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010234a:	00 
f010234b:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102352:	e8 3d dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102357:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010235c:	74 24                	je     f0102382 <mem_init+0x1232>
f010235e:	c7 44 24 0c 4a 4c 10 	movl   $0xf0104c4a,0xc(%esp)
f0102365:	f0 
f0102366:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010236d:	f0 
f010236e:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102375:	00 
f0102376:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010237d:	e8 12 dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102382:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102389:	e8 40 ea ff ff       	call   f0100dce <page_alloc>
f010238e:	85 c0                	test   %eax,%eax
f0102390:	74 04                	je     f0102396 <mem_init+0x1246>
f0102392:	39 c6                	cmp    %eax,%esi
f0102394:	74 24                	je     f01023ba <mem_init+0x126a>
f0102396:	c7 44 24 0c c4 47 10 	movl   $0xf01047c4,0xc(%esp)
f010239d:	f0 
f010239e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01023ad:	00 
f01023ae:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01023b5:	e8 da dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023c1:	e8 08 ea ff ff       	call   f0100dce <page_alloc>
f01023c6:	85 c0                	test   %eax,%eax
f01023c8:	74 24                	je     f01023ee <mem_init+0x129e>
f01023ca:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f01023d1:	f0 
f01023d2:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01023d9:	f0 
f01023da:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01023e1:	00 
f01023e2:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01023e9:	e8 a6 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023ee:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f01023f3:	8b 08                	mov    (%eax),%ecx
f01023f5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023fb:	89 fa                	mov    %edi,%edx
f01023fd:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0102403:	c1 fa 03             	sar    $0x3,%edx
f0102406:	c1 e2 0c             	shl    $0xc,%edx
f0102409:	39 d1                	cmp    %edx,%ecx
f010240b:	74 24                	je     f0102431 <mem_init+0x12e1>
f010240d:	c7 44 24 0c 68 44 10 	movl   $0xf0104468,0xc(%esp)
f0102414:	f0 
f0102415:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010241c:	f0 
f010241d:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102424:	00 
f0102425:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010242c:	e8 63 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102431:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102437:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010243c:	74 24                	je     f0102462 <mem_init+0x1312>
f010243e:	c7 44 24 0c 01 4c 10 	movl   $0xf0104c01,0xc(%esp)
f0102445:	f0 
f0102446:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010244d:	f0 
f010244e:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102455:	00 
f0102456:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010245d:	e8 32 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102462:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102468:	89 3c 24             	mov    %edi,(%esp)
f010246b:	e8 e2 e9 ff ff       	call   f0100e52 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102470:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102477:	00 
f0102478:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010247f:	00 
f0102480:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102485:	89 04 24             	mov    %eax,(%esp)
f0102488:	e8 25 ea ff ff       	call   f0100eb2 <pgdir_walk>
f010248d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102490:	8b 0d 6c f9 11 f0    	mov    0xf011f96c,%ecx
f0102496:	8b 51 04             	mov    0x4(%ecx),%edx
f0102499:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010249f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024a2:	8b 15 68 f9 11 f0    	mov    0xf011f968,%edx
f01024a8:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01024ab:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024ae:	c1 ea 0c             	shr    $0xc,%edx
f01024b1:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01024b4:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01024b7:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01024ba:	72 23                	jb     f01024df <mem_init+0x138f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024bc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01024bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01024c3:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f01024ca:	f0 
f01024cb:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01024d2:	00 
f01024d3:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01024da:	e8 b5 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01024df:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024e2:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01024e8:	39 d0                	cmp    %edx,%eax
f01024ea:	74 24                	je     f0102510 <mem_init+0x13c0>
f01024ec:	c7 44 24 0c 8d 4c 10 	movl   $0xf0104c8d,0xc(%esp)
f01024f3:	f0 
f01024f4:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01024fb:	f0 
f01024fc:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102503:	00 
f0102504:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010250b:	e8 84 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102510:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102517:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010251d:	89 f8                	mov    %edi,%eax
f010251f:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0102525:	c1 f8 03             	sar    $0x3,%eax
f0102528:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010252b:	89 c1                	mov    %eax,%ecx
f010252d:	c1 e9 0c             	shr    $0xc,%ecx
f0102530:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102533:	77 20                	ja     f0102555 <mem_init+0x1405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102535:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102539:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0102540:	f0 
f0102541:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102548:	00 
f0102549:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0102550:	e8 3f db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102555:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010255c:	00 
f010255d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102564:	00 
	return (void *)(pa + KERNBASE);
f0102565:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010256a:	89 04 24             	mov    %eax,(%esp)
f010256d:	e8 c0 12 00 00       	call   f0103832 <memset>
	page_free(pp0);
f0102572:	89 3c 24             	mov    %edi,(%esp)
f0102575:	e8 d8 e8 ff ff       	call   f0100e52 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010257a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102581:	00 
f0102582:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102589:	00 
f010258a:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f010258f:	89 04 24             	mov    %eax,(%esp)
f0102592:	e8 1b e9 ff ff       	call   f0100eb2 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102597:	89 fa                	mov    %edi,%edx
f0102599:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f010259f:	c1 fa 03             	sar    $0x3,%edx
f01025a2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a5:	89 d0                	mov    %edx,%eax
f01025a7:	c1 e8 0c             	shr    $0xc,%eax
f01025aa:	3b 05 68 f9 11 f0    	cmp    0xf011f968,%eax
f01025b0:	72 20                	jb     f01025d2 <mem_init+0x1482>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025b6:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f01025bd:	f0 
f01025be:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025c5:	00 
f01025c6:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f01025cd:	e8 c2 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01025d2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01025db:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025e1:	f6 00 01             	testb  $0x1,(%eax)
f01025e4:	74 24                	je     f010260a <mem_init+0x14ba>
f01025e6:	c7 44 24 0c a5 4c 10 	movl   $0xf0104ca5,0xc(%esp)
f01025ed:	f0 
f01025ee:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01025f5:	f0 
f01025f6:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f01025fd:	00 
f01025fe:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102605:	e8 8a da ff ff       	call   f0100094 <_panic>
f010260a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010260d:	39 d0                	cmp    %edx,%eax
f010260f:	75 d0                	jne    f01025e1 <mem_init+0x1491>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102611:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102616:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010261c:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0102622:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102625:	89 0d 38 f5 11 f0    	mov    %ecx,0xf011f538

	// free the pages we took
	page_free(pp0);
f010262b:	89 3c 24             	mov    %edi,(%esp)
f010262e:	e8 1f e8 ff ff       	call   f0100e52 <page_free>
	page_free(pp1);
f0102633:	89 34 24             	mov    %esi,(%esp)
f0102636:	e8 17 e8 ff ff       	call   f0100e52 <page_free>
	page_free(pp2);
f010263b:	89 1c 24             	mov    %ebx,(%esp)
f010263e:	e8 0f e8 ff ff       	call   f0100e52 <page_free>

	cprintf("check_page() succeeded!\n");
f0102643:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f010264a:	e8 97 07 00 00       	call   f0102de6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f010264f:	a1 70 f9 11 f0       	mov    0xf011f970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102654:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102659:	77 20                	ja     f010267b <mem_init+0x152b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010265b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010265f:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0102666:	f0 
f0102667:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f010266e:	00 
f010266f:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102676:	e8 19 da ff ff       	call   f0100094 <_panic>
f010267b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102682:	00 
	return (physaddr_t)kva - KERNBASE;
f0102683:	05 00 00 00 10       	add    $0x10000000,%eax
f0102688:	89 04 24             	mov    %eax,(%esp)
f010268b:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102690:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102695:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f010269a:	e8 21 e9 ff ff       	call   f0100fc0 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010269f:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01026a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026a9:	77 20                	ja     f01026cb <mem_init+0x157b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026af:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f01026b6:	f0 
f01026b7:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f01026be:	00 
f01026bf:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01026c6:	e8 c9 d9 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f01026cb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01026d2:	00 
f01026d3:	c7 04 24 00 50 11 00 	movl   $0x115000,(%esp)
f01026da:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026df:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026e4:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f01026e9:	e8 d2 e8 ff ff       	call   f0100fc0 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W | PTE_P);
f01026ee:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01026f5:	00 
f01026f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026fd:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102702:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102707:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f010270c:	e8 af e8 ff ff       	call   f0100fc0 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102711:	8b 1d 6c f9 11 f0    	mov    0xf011f96c,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102717:	8b 15 68 f9 11 f0    	mov    0xf011f968,%edx
f010271d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102720:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
f0102727:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (i = 0; i < n; i += PGSIZE)
f010272d:	be 00 00 00 00       	mov    $0x0,%esi
f0102732:	eb 70                	jmp    f01027a4 <mem_init+0x1654>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102734:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010273a:	89 d8                	mov    %ebx,%eax
f010273c:	e8 77 e1 ff ff       	call   f01008b8 <check_va2pa>
f0102741:	8b 15 70 f9 11 f0    	mov    0xf011f970,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102747:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010274d:	77 20                	ja     f010276f <mem_init+0x161f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010274f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102753:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f010275a:	f0 
f010275b:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102762:	00 
f0102763:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010276a:	e8 25 d9 ff ff       	call   f0100094 <_panic>
f010276f:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102776:	39 d0                	cmp    %edx,%eax
f0102778:	74 24                	je     f010279e <mem_init+0x164e>
f010277a:	c7 44 24 0c e8 47 10 	movl   $0xf01047e8,0xc(%esp)
f0102781:	f0 
f0102782:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102789:	f0 
f010278a:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102799:	e8 f6 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010279e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027a4:	39 f7                	cmp    %esi,%edi
f01027a6:	77 8c                	ja     f0102734 <mem_init+0x15e4>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027a8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01027ab:	c1 e7 0c             	shl    $0xc,%edi
f01027ae:	be 00 00 00 00       	mov    $0x0,%esi
f01027b3:	eb 3b                	jmp    f01027f0 <mem_init+0x16a0>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027b5:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027bb:	89 d8                	mov    %ebx,%eax
f01027bd:	e8 f6 e0 ff ff       	call   f01008b8 <check_va2pa>
f01027c2:	39 c6                	cmp    %eax,%esi
f01027c4:	74 24                	je     f01027ea <mem_init+0x169a>
f01027c6:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f01027cd:	f0 
f01027ce:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f01027dd:	00 
f01027de:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01027e5:	e8 aa d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027ea:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027f0:	39 fe                	cmp    %edi,%esi
f01027f2:	72 c1                	jb     f01027b5 <mem_init+0x1665>
f01027f4:	be 00 80 ff ef       	mov    $0xefff8000,%esi
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027f9:	bf 00 50 11 f0       	mov    $0xf0115000,%edi
f01027fe:	81 c7 00 80 00 20    	add    $0x20008000,%edi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102804:	89 f2                	mov    %esi,%edx
f0102806:	89 d8                	mov    %ebx,%eax
f0102808:	e8 ab e0 ff ff       	call   f01008b8 <check_va2pa>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010280d:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102810:	39 d0                	cmp    %edx,%eax
f0102812:	74 24                	je     f0102838 <mem_init+0x16e8>
f0102814:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f010281b:	f0 
f010281c:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102823:	f0 
f0102824:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f010282b:	00 
f010282c:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102833:	e8 5c d8 ff ff       	call   f0100094 <_panic>
f0102838:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010283e:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102844:	75 be                	jne    f0102804 <mem_init+0x16b4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102846:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010284b:	89 d8                	mov    %ebx,%eax
f010284d:	e8 66 e0 ff ff       	call   f01008b8 <check_va2pa>
f0102852:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102855:	74 24                	je     f010287b <mem_init+0x172b>
f0102857:	c7 44 24 0c 8c 48 10 	movl   $0xf010488c,0xc(%esp)
f010285e:	f0 
f010285f:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102866:	f0 
f0102867:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f010286e:	00 
f010286f:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102876:	e8 19 d8 ff ff       	call   f0100094 <_panic>
f010287b:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102880:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102885:	72 3c                	jb     f01028c3 <mem_init+0x1773>
f0102887:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010288c:	76 07                	jbe    f0102895 <mem_init+0x1745>
f010288e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102893:	75 2e                	jne    f01028c3 <mem_init+0x1773>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102895:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102899:	0f 85 aa 00 00 00    	jne    f0102949 <mem_init+0x17f9>
f010289f:	c7 44 24 0c d5 4c 10 	movl   $0xf0104cd5,0xc(%esp)
f01028a6:	f0 
f01028a7:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01028ae:	f0 
f01028af:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01028b6:	00 
f01028b7:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01028be:	e8 d1 d7 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028c3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028c8:	76 55                	jbe    f010291f <mem_init+0x17cf>
				assert(pgdir[i] & PTE_P);
f01028ca:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01028cd:	f6 c2 01             	test   $0x1,%dl
f01028d0:	75 24                	jne    f01028f6 <mem_init+0x17a6>
f01028d2:	c7 44 24 0c d5 4c 10 	movl   $0xf0104cd5,0xc(%esp)
f01028d9:	f0 
f01028da:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01028e1:	f0 
f01028e2:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f01028e9:	00 
f01028ea:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01028f1:	e8 9e d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01028f6:	f6 c2 02             	test   $0x2,%dl
f01028f9:	75 4e                	jne    f0102949 <mem_init+0x17f9>
f01028fb:	c7 44 24 0c e6 4c 10 	movl   $0xf0104ce6,0xc(%esp)
f0102902:	f0 
f0102903:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f010290a:	f0 
f010290b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0102912:	00 
f0102913:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f010291a:	e8 75 d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010291f:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102923:	74 24                	je     f0102949 <mem_init+0x17f9>
f0102925:	c7 44 24 0c f7 4c 10 	movl   $0xf0104cf7,0xc(%esp)
f010292c:	f0 
f010292d:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102934:	f0 
f0102935:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f010293c:	00 
f010293d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102944:	e8 4b d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102949:	40                   	inc    %eax
f010294a:	3d 00 04 00 00       	cmp    $0x400,%eax
f010294f:	0f 85 2b ff ff ff    	jne    f0102880 <mem_init+0x1730>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102955:	c7 04 24 bc 48 10 f0 	movl   $0xf01048bc,(%esp)
f010295c:	e8 85 04 00 00       	call   f0102de6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102961:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102966:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010296b:	77 20                	ja     f010298d <mem_init+0x183d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010296d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102971:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0102978:	f0 
f0102979:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
f0102980:	00 
f0102981:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102988:	e8 07 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010298d:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102992:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102995:	b8 00 00 00 00       	mov    $0x0,%eax
f010299a:	e8 31 e0 ff ff       	call   f01009d0 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010299f:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01029a2:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01029a7:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029aa:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029b4:	e8 15 e4 ff ff       	call   f0100dce <page_alloc>
f01029b9:	89 c6                	mov    %eax,%esi
f01029bb:	85 c0                	test   %eax,%eax
f01029bd:	75 24                	jne    f01029e3 <mem_init+0x1893>
f01029bf:	c7 44 24 0c f3 4a 10 	movl   $0xf0104af3,0xc(%esp)
f01029c6:	f0 
f01029c7:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f01029ce:	f0 
f01029cf:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01029d6:	00 
f01029d7:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f01029de:	e8 b1 d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01029e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029ea:	e8 df e3 ff ff       	call   f0100dce <page_alloc>
f01029ef:	89 c7                	mov    %eax,%edi
f01029f1:	85 c0                	test   %eax,%eax
f01029f3:	75 24                	jne    f0102a19 <mem_init+0x18c9>
f01029f5:	c7 44 24 0c 09 4b 10 	movl   $0xf0104b09,0xc(%esp)
f01029fc:	f0 
f01029fd:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102a04:	f0 
f0102a05:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102a0c:	00 
f0102a0d:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102a14:	e8 7b d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a20:	e8 a9 e3 ff ff       	call   f0100dce <page_alloc>
f0102a25:	89 c3                	mov    %eax,%ebx
f0102a27:	85 c0                	test   %eax,%eax
f0102a29:	75 24                	jne    f0102a4f <mem_init+0x18ff>
f0102a2b:	c7 44 24 0c 1f 4b 10 	movl   $0xf0104b1f,0xc(%esp)
f0102a32:	f0 
f0102a33:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102a3a:	f0 
f0102a3b:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102a42:	00 
f0102a43:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102a4a:	e8 45 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102a4f:	89 34 24             	mov    %esi,(%esp)
f0102a52:	e8 fb e3 ff ff       	call   f0100e52 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a57:	89 f8                	mov    %edi,%eax
f0102a59:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0102a5f:	c1 f8 03             	sar    $0x3,%eax
f0102a62:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a65:	89 c2                	mov    %eax,%edx
f0102a67:	c1 ea 0c             	shr    $0xc,%edx
f0102a6a:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0102a70:	72 20                	jb     f0102a92 <mem_init+0x1942>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a72:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a76:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0102a7d:	f0 
f0102a7e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a85:	00 
f0102a86:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0102a8d:	e8 02 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a92:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a99:	00 
f0102a9a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102aa1:	00 
	return (void *)(pa + KERNBASE);
f0102aa2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aa7:	89 04 24             	mov    %eax,(%esp)
f0102aaa:	e8 83 0d 00 00       	call   f0103832 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aaf:	89 d8                	mov    %ebx,%eax
f0102ab1:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0102ab7:	c1 f8 03             	sar    $0x3,%eax
f0102aba:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102abd:	89 c2                	mov    %eax,%edx
f0102abf:	c1 ea 0c             	shr    $0xc,%edx
f0102ac2:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0102ac8:	72 20                	jb     f0102aea <mem_init+0x199a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102aca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ace:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0102ad5:	f0 
f0102ad6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102add:	00 
f0102ade:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0102ae5:	e8 aa d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102aea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102af1:	00 
f0102af2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102af9:	00 
	return (void *)(pa + KERNBASE);
f0102afa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aff:	89 04 24             	mov    %eax,(%esp)
f0102b02:	e8 2b 0d 00 00       	call   f0103832 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b07:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b0e:	00 
f0102b0f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b16:	00 
f0102b17:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b1b:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102b20:	89 04 24             	mov    %eax,(%esp)
f0102b23:	e8 b6 e5 ff ff       	call   f01010de <page_insert>
	assert(pp1->pp_ref == 1);
f0102b28:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b2d:	74 24                	je     f0102b53 <mem_init+0x1a03>
f0102b2f:	c7 44 24 0c f0 4b 10 	movl   $0xf0104bf0,0xc(%esp)
f0102b36:	f0 
f0102b37:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102b3e:	f0 
f0102b3f:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102b46:	00 
f0102b47:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102b4e:	e8 41 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b53:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b5a:	01 01 01 
f0102b5d:	74 24                	je     f0102b83 <mem_init+0x1a33>
f0102b5f:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f0102b66:	f0 
f0102b67:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102b6e:	f0 
f0102b6f:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102b76:	00 
f0102b77:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102b7e:	e8 11 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b83:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b8a:	00 
f0102b8b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b92:	00 
f0102b93:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b97:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102b9c:	89 04 24             	mov    %eax,(%esp)
f0102b9f:	e8 3a e5 ff ff       	call   f01010de <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ba4:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bab:	02 02 02 
f0102bae:	74 24                	je     f0102bd4 <mem_init+0x1a84>
f0102bb0:	c7 44 24 0c 00 49 10 	movl   $0xf0104900,0xc(%esp)
f0102bb7:	f0 
f0102bb8:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102bbf:	f0 
f0102bc0:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102bc7:	00 
f0102bc8:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102bcf:	e8 c0 d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102bd4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102bd9:	74 24                	je     f0102bff <mem_init+0x1aaf>
f0102bdb:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0102be2:	f0 
f0102be3:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102bea:	f0 
f0102beb:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102bf2:	00 
f0102bf3:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102bfa:	e8 95 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102bff:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c04:	74 24                	je     f0102c2a <mem_init+0x1ada>
f0102c06:	c7 44 24 0c 7c 4c 10 	movl   $0xf0104c7c,0xc(%esp)
f0102c0d:	f0 
f0102c0e:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102c15:	f0 
f0102c16:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102c1d:	00 
f0102c1e:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102c25:	e8 6a d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c2a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c31:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c34:	89 d8                	mov    %ebx,%eax
f0102c36:	2b 05 70 f9 11 f0    	sub    0xf011f970,%eax
f0102c3c:	c1 f8 03             	sar    $0x3,%eax
f0102c3f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c42:	89 c2                	mov    %eax,%edx
f0102c44:	c1 ea 0c             	shr    $0xc,%edx
f0102c47:	3b 15 68 f9 11 f0    	cmp    0xf011f968,%edx
f0102c4d:	72 20                	jb     f0102c6f <mem_init+0x1b1f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c4f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c53:	c7 44 24 08 84 41 10 	movl   $0xf0104184,0x8(%esp)
f0102c5a:	f0 
f0102c5b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c62:	00 
f0102c63:	c7 04 24 c8 49 10 f0 	movl   $0xf01049c8,(%esp)
f0102c6a:	e8 25 d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c6f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c76:	03 03 03 
f0102c79:	74 24                	je     f0102c9f <mem_init+0x1b4f>
f0102c7b:	c7 44 24 0c 24 49 10 	movl   $0xf0104924,0xc(%esp)
f0102c82:	f0 
f0102c83:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102c8a:	f0 
f0102c8b:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102c92:	00 
f0102c93:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102c9a:	e8 f5 d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c9f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ca6:	00 
f0102ca7:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102cac:	89 04 24             	mov    %eax,(%esp)
f0102caf:	e8 e1 e3 ff ff       	call   f0101095 <page_remove>
	assert(pp2->pp_ref == 0);
f0102cb4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102cb9:	74 24                	je     f0102cdf <mem_init+0x1b8f>
f0102cbb:	c7 44 24 0c 4a 4c 10 	movl   $0xf0104c4a,0xc(%esp)
f0102cc2:	f0 
f0102cc3:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102cca:	f0 
f0102ccb:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102cd2:	00 
f0102cd3:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102cda:	e8 b5 d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cdf:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0102ce4:	8b 08                	mov    (%eax),%ecx
f0102ce6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cec:	89 f2                	mov    %esi,%edx
f0102cee:	2b 15 70 f9 11 f0    	sub    0xf011f970,%edx
f0102cf4:	c1 fa 03             	sar    $0x3,%edx
f0102cf7:	c1 e2 0c             	shl    $0xc,%edx
f0102cfa:	39 d1                	cmp    %edx,%ecx
f0102cfc:	74 24                	je     f0102d22 <mem_init+0x1bd2>
f0102cfe:	c7 44 24 0c 68 44 10 	movl   $0xf0104468,0xc(%esp)
f0102d05:	f0 
f0102d06:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102d0d:	f0 
f0102d0e:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102d15:	00 
f0102d16:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102d1d:	e8 72 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102d22:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d28:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d2d:	74 24                	je     f0102d53 <mem_init+0x1c03>
f0102d2f:	c7 44 24 0c 01 4c 10 	movl   $0xf0104c01,0xc(%esp)
f0102d36:	f0 
f0102d37:	c7 44 24 08 e2 49 10 	movl   $0xf01049e2,0x8(%esp)
f0102d3e:	f0 
f0102d3f:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102d46:	00 
f0102d47:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0102d4e:	e8 41 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d53:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d59:	89 34 24             	mov    %esi,(%esp)
f0102d5c:	e8 f1 e0 ff ff       	call   f0100e52 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d61:	c7 04 24 50 49 10 f0 	movl   $0xf0104950,(%esp)
f0102d68:	e8 79 00 00 00       	call   f0102de6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d6d:	83 c4 3c             	add    $0x3c,%esp
f0102d70:	5b                   	pop    %ebx
f0102d71:	5e                   	pop    %esi
f0102d72:	5f                   	pop    %edi
f0102d73:	5d                   	pop    %ebp
f0102d74:	c3                   	ret    
f0102d75:	00 00                	add    %al,(%eax)
	...

f0102d78 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d78:	55                   	push   %ebp
f0102d79:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d7b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d80:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d83:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d84:	b2 71                	mov    $0x71,%dl
f0102d86:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d87:	0f b6 c0             	movzbl %al,%eax
}
f0102d8a:	5d                   	pop    %ebp
f0102d8b:	c3                   	ret    

f0102d8c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d8c:	55                   	push   %ebp
f0102d8d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d8f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d94:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d97:	ee                   	out    %al,(%dx)
f0102d98:	b2 71                	mov    $0x71,%dl
f0102d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d9d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d9e:	5d                   	pop    %ebp
f0102d9f:	c3                   	ret    

f0102da0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102da0:	55                   	push   %ebp
f0102da1:	89 e5                	mov    %esp,%ebp
f0102da3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102da6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102da9:	89 04 24             	mov    %eax,(%esp)
f0102dac:	e8 07 d8 ff ff       	call   f01005b8 <cputchar>
	*cnt++;
}
f0102db1:	c9                   	leave  
f0102db2:	c3                   	ret    

f0102db3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102db3:	55                   	push   %ebp
f0102db4:	89 e5                	mov    %esp,%ebp
f0102db6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102db9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102dc0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102dce:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dd5:	c7 04 24 a0 2d 10 f0 	movl   $0xf0102da0,(%esp)
f0102ddc:	e8 11 04 00 00       	call   f01031f2 <vprintfmt>
	return cnt;
}
f0102de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102de4:	c9                   	leave  
f0102de5:	c3                   	ret    

f0102de6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102de6:	55                   	push   %ebp
f0102de7:	89 e5                	mov    %esp,%ebp
f0102de9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102dec:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102def:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102df3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102df6:	89 04 24             	mov    %eax,(%esp)
f0102df9:	e8 b5 ff ff ff       	call   f0102db3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102dfe:	c9                   	leave  
f0102dff:	c3                   	ret    

f0102e00 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e00:	55                   	push   %ebp
f0102e01:	89 e5                	mov    %esp,%ebp
f0102e03:	57                   	push   %edi
f0102e04:	56                   	push   %esi
f0102e05:	53                   	push   %ebx
f0102e06:	83 ec 10             	sub    $0x10,%esp
f0102e09:	89 c3                	mov    %eax,%ebx
f0102e0b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102e0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102e11:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e14:	8b 0a                	mov    (%edx),%ecx
f0102e16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e19:	8b 00                	mov    (%eax),%eax
f0102e1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e1e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102e25:	eb 77                	jmp    f0102e9e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102e27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e2a:	01 c8                	add    %ecx,%eax
f0102e2c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102e31:	99                   	cltd   
f0102e32:	f7 ff                	idiv   %edi
f0102e34:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e36:	eb 01                	jmp    f0102e39 <stab_binsearch+0x39>
			m--;
f0102e38:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e39:	39 ca                	cmp    %ecx,%edx
f0102e3b:	7c 1d                	jl     f0102e5a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e3d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e40:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102e45:	39 f7                	cmp    %esi,%edi
f0102e47:	75 ef                	jne    f0102e38 <stab_binsearch+0x38>
f0102e49:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e4c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102e4f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102e53:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e56:	73 18                	jae    f0102e70 <stab_binsearch+0x70>
f0102e58:	eb 05                	jmp    f0102e5f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e5a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102e5d:	eb 3f                	jmp    f0102e9e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102e5f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e62:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102e64:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e67:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e6e:	eb 2e                	jmp    f0102e9e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e70:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e73:	76 15                	jbe    f0102e8a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102e75:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e78:	4f                   	dec    %edi
f0102e79:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102e7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e7f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e81:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e88:	eb 14                	jmp    f0102e9e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e8a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e8d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e90:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102e92:	ff 45 0c             	incl   0xc(%ebp)
f0102e95:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e9e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102ea1:	7e 84                	jle    f0102e27 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102ea3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102ea7:	75 0d                	jne    f0102eb6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102ea9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102eac:	8b 02                	mov    (%edx),%eax
f0102eae:	48                   	dec    %eax
f0102eaf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102eb2:	89 01                	mov    %eax,(%ecx)
f0102eb4:	eb 22                	jmp    f0102ed8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102eb6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102eb9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102ebb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ebe:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ec0:	eb 01                	jmp    f0102ec3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102ec2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ec3:	39 c1                	cmp    %eax,%ecx
f0102ec5:	7d 0c                	jge    f0102ed3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102ec7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102eca:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102ecf:	39 f2                	cmp    %esi,%edx
f0102ed1:	75 ef                	jne    f0102ec2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102ed3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ed6:	89 02                	mov    %eax,(%edx)
	}
}
f0102ed8:	83 c4 10             	add    $0x10,%esp
f0102edb:	5b                   	pop    %ebx
f0102edc:	5e                   	pop    %esi
f0102edd:	5f                   	pop    %edi
f0102ede:	5d                   	pop    %ebp
f0102edf:	c3                   	ret    

f0102ee0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ee0:	55                   	push   %ebp
f0102ee1:	89 e5                	mov    %esp,%ebp
f0102ee3:	57                   	push   %edi
f0102ee4:	56                   	push   %esi
f0102ee5:	53                   	push   %ebx
f0102ee6:	83 ec 2c             	sub    $0x2c,%esp
f0102ee9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102eec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102eef:	c7 03 05 4d 10 f0    	movl   $0xf0104d05,(%ebx)
	info->eip_line = 0;
f0102ef5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102efc:	c7 43 08 05 4d 10 f0 	movl   $0xf0104d05,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f03:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f0a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f0d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f14:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f1a:	76 12                	jbe    f0102f2e <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f1c:	b8 3a 49 11 f0       	mov    $0xf011493a,%eax
f0102f21:	3d 41 b9 10 f0       	cmp    $0xf010b941,%eax
f0102f26:	0f 86 50 01 00 00    	jbe    f010307c <debuginfo_eip+0x19c>
f0102f2c:	eb 1c                	jmp    f0102f4a <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102f2e:	c7 44 24 08 0f 4d 10 	movl   $0xf0104d0f,0x8(%esp)
f0102f35:	f0 
f0102f36:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f3d:	00 
f0102f3e:	c7 04 24 1c 4d 10 f0 	movl   $0xf0104d1c,(%esp)
f0102f45:	e8 4a d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102f4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f4f:	80 3d 39 49 11 f0 00 	cmpb   $0x0,0xf0114939
f0102f56:	0f 85 2c 01 00 00    	jne    f0103088 <debuginfo_eip+0x1a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f5c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f63:	b8 40 b9 10 f0       	mov    $0xf010b940,%eax
f0102f68:	2d 38 4f 10 f0       	sub    $0xf0104f38,%eax
f0102f6d:	c1 f8 02             	sar    $0x2,%eax
f0102f70:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f76:	48                   	dec    %eax
f0102f77:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f7a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f7e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f85:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f88:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f8b:	b8 38 4f 10 f0       	mov    $0xf0104f38,%eax
f0102f90:	e8 6b fe ff ff       	call   f0102e00 <stab_binsearch>
	if (lfile == 0)
f0102f95:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102f98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102f9d:	85 d2                	test   %edx,%edx
f0102f9f:	0f 84 e3 00 00 00    	je     f0103088 <debuginfo_eip+0x1a8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102fa5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102fa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fab:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102fae:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fb2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102fb9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102fbc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102fbf:	b8 38 4f 10 f0       	mov    $0xf0104f38,%eax
f0102fc4:	e8 37 fe ff ff       	call   f0102e00 <stab_binsearch>

	if (lfun <= rfun) {
f0102fc9:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102fcc:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102fcf:	7f 2e                	jg     f0102fff <debuginfo_eip+0x11f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fd1:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102fd4:	8d 90 38 4f 10 f0    	lea    -0xfefb0c8(%eax),%edx
f0102fda:	8b 80 38 4f 10 f0    	mov    -0xfefb0c8(%eax),%eax
f0102fe0:	b9 3a 49 11 f0       	mov    $0xf011493a,%ecx
f0102fe5:	81 e9 41 b9 10 f0    	sub    $0xf010b941,%ecx
f0102feb:	39 c8                	cmp    %ecx,%eax
f0102fed:	73 08                	jae    f0102ff7 <debuginfo_eip+0x117>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102fef:	05 41 b9 10 f0       	add    $0xf010b941,%eax
f0102ff4:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102ff7:	8b 42 08             	mov    0x8(%edx),%eax
f0102ffa:	89 43 10             	mov    %eax,0x10(%ebx)
f0102ffd:	eb 06                	jmp    f0103005 <debuginfo_eip+0x125>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102fff:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103002:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103005:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010300c:	00 
f010300d:	8b 43 08             	mov    0x8(%ebx),%eax
f0103010:	89 04 24             	mov    %eax,(%esp)
f0103013:	e8 02 08 00 00       	call   f010381a <strfind>
f0103018:	2b 43 08             	sub    0x8(%ebx),%eax
f010301b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010301e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103021:	eb 01                	jmp    f0103024 <debuginfo_eip+0x144>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103023:	4f                   	dec    %edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103024:	39 cf                	cmp    %ecx,%edi
f0103026:	7c 24                	jl     f010304c <debuginfo_eip+0x16c>
	       && stabs[lline].n_type != N_SOL
f0103028:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010302b:	8d 14 85 38 4f 10 f0 	lea    -0xfefb0c8(,%eax,4),%edx
f0103032:	8a 42 04             	mov    0x4(%edx),%al
f0103035:	3c 84                	cmp    $0x84,%al
f0103037:	74 57                	je     f0103090 <debuginfo_eip+0x1b0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103039:	3c 64                	cmp    $0x64,%al
f010303b:	75 e6                	jne    f0103023 <debuginfo_eip+0x143>
f010303d:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103041:	74 e0                	je     f0103023 <debuginfo_eip+0x143>
f0103043:	eb 4b                	jmp    f0103090 <debuginfo_eip+0x1b0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103045:	05 41 b9 10 f0       	add    $0xf010b941,%eax
f010304a:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010304c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010304f:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103052:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103057:	39 d1                	cmp    %edx,%ecx
f0103059:	7d 2d                	jge    f0103088 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
f010305b:	8d 41 01             	lea    0x1(%ecx),%eax
f010305e:	eb 04                	jmp    f0103064 <debuginfo_eip+0x184>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103060:	ff 43 14             	incl   0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103063:	40                   	inc    %eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103064:	39 d0                	cmp    %edx,%eax
f0103066:	74 1b                	je     f0103083 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103068:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010306b:	80 3c 8d 3c 4f 10 f0 	cmpb   $0xa0,-0xfefb0c4(,%ecx,4)
f0103072:	a0 
f0103073:	74 eb                	je     f0103060 <debuginfo_eip+0x180>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103075:	b8 00 00 00 00       	mov    $0x0,%eax
f010307a:	eb 0c                	jmp    f0103088 <debuginfo_eip+0x1a8>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010307c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103081:	eb 05                	jmp    f0103088 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103083:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103088:	83 c4 2c             	add    $0x2c,%esp
f010308b:	5b                   	pop    %ebx
f010308c:	5e                   	pop    %esi
f010308d:	5f                   	pop    %edi
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103090:	6b ff 0c             	imul   $0xc,%edi,%edi
f0103093:	8b 87 38 4f 10 f0    	mov    -0xfefb0c8(%edi),%eax
f0103099:	ba 3a 49 11 f0       	mov    $0xf011493a,%edx
f010309e:	81 ea 41 b9 10 f0    	sub    $0xf010b941,%edx
f01030a4:	39 d0                	cmp    %edx,%eax
f01030a6:	72 9d                	jb     f0103045 <debuginfo_eip+0x165>
f01030a8:	eb a2                	jmp    f010304c <debuginfo_eip+0x16c>
	...

f01030ac <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01030ac:	55                   	push   %ebp
f01030ad:	89 e5                	mov    %esp,%ebp
f01030af:	57                   	push   %edi
f01030b0:	56                   	push   %esi
f01030b1:	53                   	push   %ebx
f01030b2:	83 ec 3c             	sub    $0x3c,%esp
f01030b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030b8:	89 d7                	mov    %edx,%edi
f01030ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01030bd:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01030c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030c6:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01030c9:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01030cc:	85 c0                	test   %eax,%eax
f01030ce:	75 08                	jne    f01030d8 <printnum+0x2c>
f01030d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030d3:	39 45 10             	cmp    %eax,0x10(%ebp)
f01030d6:	77 57                	ja     f010312f <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01030d8:	89 74 24 10          	mov    %esi,0x10(%esp)
f01030dc:	4b                   	dec    %ebx
f01030dd:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01030e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01030e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030e8:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01030ec:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01030f0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030f7:	00 
f01030f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030fb:	89 04 24             	mov    %eax,(%esp)
f01030fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103101:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103105:	e8 1e 09 00 00       	call   f0103a28 <__udivdi3>
f010310a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010310e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103112:	89 04 24             	mov    %eax,(%esp)
f0103115:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103119:	89 fa                	mov    %edi,%edx
f010311b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010311e:	e8 89 ff ff ff       	call   f01030ac <printnum>
f0103123:	eb 0f                	jmp    f0103134 <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103125:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103129:	89 34 24             	mov    %esi,(%esp)
f010312c:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010312f:	4b                   	dec    %ebx
f0103130:	85 db                	test   %ebx,%ebx
f0103132:	7f f1                	jg     f0103125 <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103134:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103138:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010313c:	8b 45 10             	mov    0x10(%ebp),%eax
f010313f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103143:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010314a:	00 
f010314b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010314e:	89 04 24             	mov    %eax,(%esp)
f0103151:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103154:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103158:	e8 eb 09 00 00       	call   f0103b48 <__umoddi3>
f010315d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103161:	0f be 80 2a 4d 10 f0 	movsbl -0xfefb2d6(%eax),%eax
f0103168:	89 04 24             	mov    %eax,(%esp)
f010316b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f010316e:	83 c4 3c             	add    $0x3c,%esp
f0103171:	5b                   	pop    %ebx
f0103172:	5e                   	pop    %esi
f0103173:	5f                   	pop    %edi
f0103174:	5d                   	pop    %ebp
f0103175:	c3                   	ret    

f0103176 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103176:	55                   	push   %ebp
f0103177:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103179:	83 fa 01             	cmp    $0x1,%edx
f010317c:	7e 0e                	jle    f010318c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010317e:	8b 10                	mov    (%eax),%edx
f0103180:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103183:	89 08                	mov    %ecx,(%eax)
f0103185:	8b 02                	mov    (%edx),%eax
f0103187:	8b 52 04             	mov    0x4(%edx),%edx
f010318a:	eb 22                	jmp    f01031ae <getuint+0x38>
	else if (lflag)
f010318c:	85 d2                	test   %edx,%edx
f010318e:	74 10                	je     f01031a0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103190:	8b 10                	mov    (%eax),%edx
f0103192:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103195:	89 08                	mov    %ecx,(%eax)
f0103197:	8b 02                	mov    (%edx),%eax
f0103199:	ba 00 00 00 00       	mov    $0x0,%edx
f010319e:	eb 0e                	jmp    f01031ae <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01031a0:	8b 10                	mov    (%eax),%edx
f01031a2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031a5:	89 08                	mov    %ecx,(%eax)
f01031a7:	8b 02                	mov    (%edx),%eax
f01031a9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01031ae:	5d                   	pop    %ebp
f01031af:	c3                   	ret    

f01031b0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01031b0:	55                   	push   %ebp
f01031b1:	89 e5                	mov    %esp,%ebp
f01031b3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01031b6:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f01031b9:	8b 10                	mov    (%eax),%edx
f01031bb:	3b 50 04             	cmp    0x4(%eax),%edx
f01031be:	73 08                	jae    f01031c8 <sprintputch+0x18>
		*b->buf++ = ch;
f01031c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031c3:	88 0a                	mov    %cl,(%edx)
f01031c5:	42                   	inc    %edx
f01031c6:	89 10                	mov    %edx,(%eax)
}
f01031c8:	5d                   	pop    %ebp
f01031c9:	c3                   	ret    

f01031ca <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031ca:	55                   	push   %ebp
f01031cb:	89 e5                	mov    %esp,%ebp
f01031cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01031d0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01031d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01031da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01031e8:	89 04 24             	mov    %eax,(%esp)
f01031eb:	e8 02 00 00 00       	call   f01031f2 <vprintfmt>
	va_end(ap);
}
f01031f0:	c9                   	leave  
f01031f1:	c3                   	ret    

f01031f2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031f2:	55                   	push   %ebp
f01031f3:	89 e5                	mov    %esp,%ebp
f01031f5:	57                   	push   %edi
f01031f6:	56                   	push   %esi
f01031f7:	53                   	push   %ebx
f01031f8:	83 ec 4c             	sub    $0x4c,%esp
f01031fb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031fe:	8b 75 10             	mov    0x10(%ebp),%esi
f0103201:	eb 12                	jmp    f0103215 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103203:	85 c0                	test   %eax,%eax
f0103205:	0f 84 6b 03 00 00    	je     f0103576 <vprintfmt+0x384>
				return;
			putch(ch, putdat);
f010320b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010320f:	89 04 24             	mov    %eax,(%esp)
f0103212:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103215:	0f b6 06             	movzbl (%esi),%eax
f0103218:	46                   	inc    %esi
f0103219:	83 f8 25             	cmp    $0x25,%eax
f010321c:	75 e5                	jne    f0103203 <vprintfmt+0x11>
f010321e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103222:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103229:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f010322e:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103235:	b9 00 00 00 00       	mov    $0x0,%ecx
f010323a:	eb 26                	jmp    f0103262 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010323c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010323f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103243:	eb 1d                	jmp    f0103262 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103245:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103248:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010324c:	eb 14                	jmp    f0103262 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010324e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103251:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103258:	eb 08                	jmp    f0103262 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010325a:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010325d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103262:	0f b6 06             	movzbl (%esi),%eax
f0103265:	8d 56 01             	lea    0x1(%esi),%edx
f0103268:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010326b:	8a 16                	mov    (%esi),%dl
f010326d:	83 ea 23             	sub    $0x23,%edx
f0103270:	80 fa 55             	cmp    $0x55,%dl
f0103273:	0f 87 e1 02 00 00    	ja     f010355a <vprintfmt+0x368>
f0103279:	0f b6 d2             	movzbl %dl,%edx
f010327c:	ff 24 95 b4 4d 10 f0 	jmp    *-0xfefb24c(,%edx,4)
f0103283:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103286:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010328b:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010328e:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103292:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103295:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103298:	83 fa 09             	cmp    $0x9,%edx
f010329b:	77 2a                	ja     f01032c7 <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010329d:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010329e:	eb eb                	jmp    f010328b <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01032a3:	8d 50 04             	lea    0x4(%eax),%edx
f01032a6:	89 55 14             	mov    %edx,0x14(%ebp)
f01032a9:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ab:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032ae:	eb 17                	jmp    f01032c7 <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f01032b0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01032b4:	78 98                	js     f010324e <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01032b9:	eb a7                	jmp    f0103262 <vprintfmt+0x70>
f01032bb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01032be:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01032c5:	eb 9b                	jmp    f0103262 <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f01032c7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01032cb:	79 95                	jns    f0103262 <vprintfmt+0x70>
f01032cd:	eb 8b                	jmp    f010325a <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01032cf:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d0:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01032d3:	eb 8d                	jmp    f0103262 <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01032d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01032d8:	8d 50 04             	lea    0x4(%eax),%edx
f01032db:	89 55 14             	mov    %edx,0x14(%ebp)
f01032de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032e2:	8b 00                	mov    (%eax),%eax
f01032e4:	89 04 24             	mov    %eax,(%esp)
f01032e7:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01032ed:	e9 23 ff ff ff       	jmp    f0103215 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01032f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01032f5:	8d 50 04             	lea    0x4(%eax),%edx
f01032f8:	89 55 14             	mov    %edx,0x14(%ebp)
f01032fb:	8b 00                	mov    (%eax),%eax
f01032fd:	85 c0                	test   %eax,%eax
f01032ff:	79 02                	jns    f0103303 <vprintfmt+0x111>
f0103301:	f7 d8                	neg    %eax
f0103303:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103305:	83 f8 06             	cmp    $0x6,%eax
f0103308:	7f 0b                	jg     f0103315 <vprintfmt+0x123>
f010330a:	8b 04 85 0c 4f 10 f0 	mov    -0xfefb0f4(,%eax,4),%eax
f0103311:	85 c0                	test   %eax,%eax
f0103313:	75 23                	jne    f0103338 <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f0103315:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103319:	c7 44 24 08 42 4d 10 	movl   $0xf0104d42,0x8(%esp)
f0103320:	f0 
f0103321:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103325:	8b 45 08             	mov    0x8(%ebp),%eax
f0103328:	89 04 24             	mov    %eax,(%esp)
f010332b:	e8 9a fe ff ff       	call   f01031ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103330:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103333:	e9 dd fe ff ff       	jmp    f0103215 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103338:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010333c:	c7 44 24 08 f4 49 10 	movl   $0xf01049f4,0x8(%esp)
f0103343:	f0 
f0103344:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103348:	8b 55 08             	mov    0x8(%ebp),%edx
f010334b:	89 14 24             	mov    %edx,(%esp)
f010334e:	e8 77 fe ff ff       	call   f01031ca <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103353:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103356:	e9 ba fe ff ff       	jmp    f0103215 <vprintfmt+0x23>
f010335b:	89 f9                	mov    %edi,%ecx
f010335d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103360:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103363:	8b 45 14             	mov    0x14(%ebp),%eax
f0103366:	8d 50 04             	lea    0x4(%eax),%edx
f0103369:	89 55 14             	mov    %edx,0x14(%ebp)
f010336c:	8b 30                	mov    (%eax),%esi
f010336e:	85 f6                	test   %esi,%esi
f0103370:	75 05                	jne    f0103377 <vprintfmt+0x185>
				p = "(null)";
f0103372:	be 3b 4d 10 f0       	mov    $0xf0104d3b,%esi
			if (width > 0 && padc != '-')
f0103377:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010337b:	0f 8e 84 00 00 00    	jle    f0103405 <vprintfmt+0x213>
f0103381:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103385:	74 7e                	je     f0103405 <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103387:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010338b:	89 34 24             	mov    %esi,(%esp)
f010338e:	e8 53 03 00 00       	call   f01036e6 <strnlen>
f0103393:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103396:	29 c2                	sub    %eax,%edx
f0103398:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f010339b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010339f:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01033a2:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01033a5:	89 de                	mov    %ebx,%esi
f01033a7:	89 d3                	mov    %edx,%ebx
f01033a9:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033ab:	eb 0b                	jmp    f01033b8 <vprintfmt+0x1c6>
					putch(padc, putdat);
f01033ad:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033b1:	89 3c 24             	mov    %edi,(%esp)
f01033b4:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033b7:	4b                   	dec    %ebx
f01033b8:	85 db                	test   %ebx,%ebx
f01033ba:	7f f1                	jg     f01033ad <vprintfmt+0x1bb>
f01033bc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01033bf:	89 f3                	mov    %esi,%ebx
f01033c1:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f01033c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033c7:	85 c0                	test   %eax,%eax
f01033c9:	79 05                	jns    f01033d0 <vprintfmt+0x1de>
f01033cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01033d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01033d3:	29 c2                	sub    %eax,%edx
f01033d5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01033d8:	eb 2b                	jmp    f0103405 <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01033da:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01033de:	74 18                	je     f01033f8 <vprintfmt+0x206>
f01033e0:	8d 50 e0             	lea    -0x20(%eax),%edx
f01033e3:	83 fa 5e             	cmp    $0x5e,%edx
f01033e6:	76 10                	jbe    f01033f8 <vprintfmt+0x206>
					putch('?', putdat);
f01033e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01033f3:	ff 55 08             	call   *0x8(%ebp)
f01033f6:	eb 0a                	jmp    f0103402 <vprintfmt+0x210>
				else
					putch(ch, putdat);
f01033f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033fc:	89 04 24             	mov    %eax,(%esp)
f01033ff:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103402:	ff 4d e4             	decl   -0x1c(%ebp)
f0103405:	0f be 06             	movsbl (%esi),%eax
f0103408:	46                   	inc    %esi
f0103409:	85 c0                	test   %eax,%eax
f010340b:	74 21                	je     f010342e <vprintfmt+0x23c>
f010340d:	85 ff                	test   %edi,%edi
f010340f:	78 c9                	js     f01033da <vprintfmt+0x1e8>
f0103411:	4f                   	dec    %edi
f0103412:	79 c6                	jns    f01033da <vprintfmt+0x1e8>
f0103414:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103417:	89 de                	mov    %ebx,%esi
f0103419:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010341c:	eb 18                	jmp    f0103436 <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010341e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103422:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103429:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010342b:	4b                   	dec    %ebx
f010342c:	eb 08                	jmp    f0103436 <vprintfmt+0x244>
f010342e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103431:	89 de                	mov    %ebx,%esi
f0103433:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103436:	85 db                	test   %ebx,%ebx
f0103438:	7f e4                	jg     f010341e <vprintfmt+0x22c>
f010343a:	89 7d 08             	mov    %edi,0x8(%ebp)
f010343d:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010343f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103442:	e9 ce fd ff ff       	jmp    f0103215 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103447:	83 f9 01             	cmp    $0x1,%ecx
f010344a:	7e 10                	jle    f010345c <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f010344c:	8b 45 14             	mov    0x14(%ebp),%eax
f010344f:	8d 50 08             	lea    0x8(%eax),%edx
f0103452:	89 55 14             	mov    %edx,0x14(%ebp)
f0103455:	8b 30                	mov    (%eax),%esi
f0103457:	8b 78 04             	mov    0x4(%eax),%edi
f010345a:	eb 26                	jmp    f0103482 <vprintfmt+0x290>
	else if (lflag)
f010345c:	85 c9                	test   %ecx,%ecx
f010345e:	74 12                	je     f0103472 <vprintfmt+0x280>
		return va_arg(*ap, long);
f0103460:	8b 45 14             	mov    0x14(%ebp),%eax
f0103463:	8d 50 04             	lea    0x4(%eax),%edx
f0103466:	89 55 14             	mov    %edx,0x14(%ebp)
f0103469:	8b 30                	mov    (%eax),%esi
f010346b:	89 f7                	mov    %esi,%edi
f010346d:	c1 ff 1f             	sar    $0x1f,%edi
f0103470:	eb 10                	jmp    f0103482 <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f0103472:	8b 45 14             	mov    0x14(%ebp),%eax
f0103475:	8d 50 04             	lea    0x4(%eax),%edx
f0103478:	89 55 14             	mov    %edx,0x14(%ebp)
f010347b:	8b 30                	mov    (%eax),%esi
f010347d:	89 f7                	mov    %esi,%edi
f010347f:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103482:	85 ff                	test   %edi,%edi
f0103484:	78 0a                	js     f0103490 <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103486:	b8 0a 00 00 00       	mov    $0xa,%eax
f010348b:	e9 8c 00 00 00       	jmp    f010351c <vprintfmt+0x32a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0103490:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103494:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010349b:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010349e:	f7 de                	neg    %esi
f01034a0:	83 d7 00             	adc    $0x0,%edi
f01034a3:	f7 df                	neg    %edi
			}
			base = 10;
f01034a5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01034aa:	eb 70                	jmp    f010351c <vprintfmt+0x32a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01034ac:	89 ca                	mov    %ecx,%edx
f01034ae:	8d 45 14             	lea    0x14(%ebp),%eax
f01034b1:	e8 c0 fc ff ff       	call   f0103176 <getuint>
f01034b6:	89 c6                	mov    %eax,%esi
f01034b8:	89 d7                	mov    %edx,%edi
			base = 10;
f01034ba:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01034bf:	eb 5b                	jmp    f010351c <vprintfmt+0x32a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap,lflag);
f01034c1:	89 ca                	mov    %ecx,%edx
f01034c3:	8d 45 14             	lea    0x14(%ebp),%eax
f01034c6:	e8 ab fc ff ff       	call   f0103176 <getuint>
f01034cb:	89 c6                	mov    %eax,%esi
f01034cd:	89 d7                	mov    %edx,%edi
            base = 8;
f01034cf:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f01034d4:	eb 46                	jmp    f010351c <vprintfmt+0x32a>
//			putch('X', putdat);
//			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01034d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034da:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01034e1:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01034e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034e8:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01034ef:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f5:	8d 50 04             	lea    0x4(%eax),%edx
f01034f8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01034fb:	8b 30                	mov    (%eax),%esi
f01034fd:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103502:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103507:	eb 13                	jmp    f010351c <vprintfmt+0x32a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103509:	89 ca                	mov    %ecx,%edx
f010350b:	8d 45 14             	lea    0x14(%ebp),%eax
f010350e:	e8 63 fc ff ff       	call   f0103176 <getuint>
f0103513:	89 c6                	mov    %eax,%esi
f0103515:	89 d7                	mov    %edx,%edi
			base = 16;
f0103517:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010351c:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103520:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103524:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103527:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010352b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010352f:	89 34 24             	mov    %esi,(%esp)
f0103532:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103536:	89 da                	mov    %ebx,%edx
f0103538:	8b 45 08             	mov    0x8(%ebp),%eax
f010353b:	e8 6c fb ff ff       	call   f01030ac <printnum>
			break;
f0103540:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103543:	e9 cd fc ff ff       	jmp    f0103215 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103548:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010354c:	89 04 24             	mov    %eax,(%esp)
f010354f:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103552:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103555:	e9 bb fc ff ff       	jmp    f0103215 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010355a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010355e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103565:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103568:	eb 01                	jmp    f010356b <vprintfmt+0x379>
f010356a:	4e                   	dec    %esi
f010356b:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010356f:	75 f9                	jne    f010356a <vprintfmt+0x378>
f0103571:	e9 9f fc ff ff       	jmp    f0103215 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103576:	83 c4 4c             	add    $0x4c,%esp
f0103579:	5b                   	pop    %ebx
f010357a:	5e                   	pop    %esi
f010357b:	5f                   	pop    %edi
f010357c:	5d                   	pop    %ebp
f010357d:	c3                   	ret    

f010357e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010357e:	55                   	push   %ebp
f010357f:	89 e5                	mov    %esp,%ebp
f0103581:	83 ec 28             	sub    $0x28,%esp
f0103584:	8b 45 08             	mov    0x8(%ebp),%eax
f0103587:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010358a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010358d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103591:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010359b:	85 c0                	test   %eax,%eax
f010359d:	74 30                	je     f01035cf <vsnprintf+0x51>
f010359f:	85 d2                	test   %edx,%edx
f01035a1:	7e 33                	jle    f01035d6 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01035a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01035a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035aa:	8b 45 10             	mov    0x10(%ebp),%eax
f01035ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035b1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01035b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035b8:	c7 04 24 b0 31 10 f0 	movl   $0xf01031b0,(%esp)
f01035bf:	e8 2e fc ff ff       	call   f01031f2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01035c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035c7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01035ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035cd:	eb 0c                	jmp    f01035db <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01035cf:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01035d4:	eb 05                	jmp    f01035db <vsnprintf+0x5d>
f01035d6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01035db:	c9                   	leave  
f01035dc:	c3                   	ret    

f01035dd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01035dd:	55                   	push   %ebp
f01035de:	89 e5                	mov    %esp,%ebp
f01035e0:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035e3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035ea:	8b 45 10             	mov    0x10(%ebp),%eax
f01035ed:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035fb:	89 04 24             	mov    %eax,(%esp)
f01035fe:	e8 7b ff ff ff       	call   f010357e <vsnprintf>
	va_end(ap);

	return rc;
}
f0103603:	c9                   	leave  
f0103604:	c3                   	ret    
f0103605:	00 00                	add    %al,(%eax)
	...

f0103608 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103608:	55                   	push   %ebp
f0103609:	89 e5                	mov    %esp,%ebp
f010360b:	57                   	push   %edi
f010360c:	56                   	push   %esi
f010360d:	53                   	push   %ebx
f010360e:	83 ec 1c             	sub    $0x1c,%esp
f0103611:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103614:	85 c0                	test   %eax,%eax
f0103616:	74 10                	je     f0103628 <readline+0x20>
		cprintf("%s", prompt);
f0103618:	89 44 24 04          	mov    %eax,0x4(%esp)
f010361c:	c7 04 24 f4 49 10 f0 	movl   $0xf01049f4,(%esp)
f0103623:	e8 be f7 ff ff       	call   f0102de6 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103628:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010362f:	e8 a5 cf ff ff       	call   f01005d9 <iscons>
f0103634:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103636:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010363b:	e8 88 cf ff ff       	call   f01005c8 <getchar>
f0103640:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103642:	85 c0                	test   %eax,%eax
f0103644:	79 17                	jns    f010365d <readline+0x55>
			cprintf("read error: %e\n", c);
f0103646:	89 44 24 04          	mov    %eax,0x4(%esp)
f010364a:	c7 04 24 28 4f 10 f0 	movl   $0xf0104f28,(%esp)
f0103651:	e8 90 f7 ff ff       	call   f0102de6 <cprintf>
			return NULL;
f0103656:	b8 00 00 00 00       	mov    $0x0,%eax
f010365b:	eb 69                	jmp    f01036c6 <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010365d:	83 f8 08             	cmp    $0x8,%eax
f0103660:	74 05                	je     f0103667 <readline+0x5f>
f0103662:	83 f8 7f             	cmp    $0x7f,%eax
f0103665:	75 17                	jne    f010367e <readline+0x76>
f0103667:	85 f6                	test   %esi,%esi
f0103669:	7e 13                	jle    f010367e <readline+0x76>
			if (echoing)
f010366b:	85 ff                	test   %edi,%edi
f010366d:	74 0c                	je     f010367b <readline+0x73>
				cputchar('\b');
f010366f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103676:	e8 3d cf ff ff       	call   f01005b8 <cputchar>
			i--;
f010367b:	4e                   	dec    %esi
f010367c:	eb bd                	jmp    f010363b <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010367e:	83 fb 1f             	cmp    $0x1f,%ebx
f0103681:	7e 1d                	jle    f01036a0 <readline+0x98>
f0103683:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103689:	7f 15                	jg     f01036a0 <readline+0x98>
			if (echoing)
f010368b:	85 ff                	test   %edi,%edi
f010368d:	74 08                	je     f0103697 <readline+0x8f>
				cputchar(c);
f010368f:	89 1c 24             	mov    %ebx,(%esp)
f0103692:	e8 21 cf ff ff       	call   f01005b8 <cputchar>
			buf[i++] = c;
f0103697:	88 9e 60 f5 11 f0    	mov    %bl,-0xfee0aa0(%esi)
f010369d:	46                   	inc    %esi
f010369e:	eb 9b                	jmp    f010363b <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01036a0:	83 fb 0a             	cmp    $0xa,%ebx
f01036a3:	74 05                	je     f01036aa <readline+0xa2>
f01036a5:	83 fb 0d             	cmp    $0xd,%ebx
f01036a8:	75 91                	jne    f010363b <readline+0x33>
			if (echoing)
f01036aa:	85 ff                	test   %edi,%edi
f01036ac:	74 0c                	je     f01036ba <readline+0xb2>
				cputchar('\n');
f01036ae:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01036b5:	e8 fe ce ff ff       	call   f01005b8 <cputchar>
			buf[i] = 0;
f01036ba:	c6 86 60 f5 11 f0 00 	movb   $0x0,-0xfee0aa0(%esi)
			return buf;
f01036c1:	b8 60 f5 11 f0       	mov    $0xf011f560,%eax
		}
	}
}
f01036c6:	83 c4 1c             	add    $0x1c,%esp
f01036c9:	5b                   	pop    %ebx
f01036ca:	5e                   	pop    %esi
f01036cb:	5f                   	pop    %edi
f01036cc:	5d                   	pop    %ebp
f01036cd:	c3                   	ret    
	...

f01036d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01036d0:	55                   	push   %ebp
f01036d1:	89 e5                	mov    %esp,%ebp
f01036d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01036d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01036db:	eb 01                	jmp    f01036de <strlen+0xe>
		n++;
f01036dd:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036de:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036e2:	75 f9                	jne    f01036dd <strlen+0xd>
		n++;
	return n;
}
f01036e4:	5d                   	pop    %ebp
f01036e5:	c3                   	ret    

f01036e6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036e6:	55                   	push   %ebp
f01036e7:	89 e5                	mov    %esp,%ebp
f01036e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01036ec:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01036f4:	eb 01                	jmp    f01036f7 <strnlen+0x11>
		n++;
f01036f6:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036f7:	39 d0                	cmp    %edx,%eax
f01036f9:	74 06                	je     f0103701 <strnlen+0x1b>
f01036fb:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01036ff:	75 f5                	jne    f01036f6 <strnlen+0x10>
		n++;
	return n;
}
f0103701:	5d                   	pop    %ebp
f0103702:	c3                   	ret    

f0103703 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103703:	55                   	push   %ebp
f0103704:	89 e5                	mov    %esp,%ebp
f0103706:	53                   	push   %ebx
f0103707:	8b 45 08             	mov    0x8(%ebp),%eax
f010370a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010370d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103712:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f0103715:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103718:	42                   	inc    %edx
f0103719:	84 c9                	test   %cl,%cl
f010371b:	75 f5                	jne    f0103712 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f010371d:	5b                   	pop    %ebx
f010371e:	5d                   	pop    %ebp
f010371f:	c3                   	ret    

f0103720 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103720:	55                   	push   %ebp
f0103721:	89 e5                	mov    %esp,%ebp
f0103723:	53                   	push   %ebx
f0103724:	83 ec 08             	sub    $0x8,%esp
f0103727:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010372a:	89 1c 24             	mov    %ebx,(%esp)
f010372d:	e8 9e ff ff ff       	call   f01036d0 <strlen>
	strcpy(dst + len, src);
f0103732:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103735:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103739:	01 d8                	add    %ebx,%eax
f010373b:	89 04 24             	mov    %eax,(%esp)
f010373e:	e8 c0 ff ff ff       	call   f0103703 <strcpy>
	return dst;
}
f0103743:	89 d8                	mov    %ebx,%eax
f0103745:	83 c4 08             	add    $0x8,%esp
f0103748:	5b                   	pop    %ebx
f0103749:	5d                   	pop    %ebp
f010374a:	c3                   	ret    

f010374b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010374b:	55                   	push   %ebp
f010374c:	89 e5                	mov    %esp,%ebp
f010374e:	56                   	push   %esi
f010374f:	53                   	push   %ebx
f0103750:	8b 45 08             	mov    0x8(%ebp),%eax
f0103753:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103756:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103759:	b9 00 00 00 00       	mov    $0x0,%ecx
f010375e:	eb 0c                	jmp    f010376c <strncpy+0x21>
		*dst++ = *src;
f0103760:	8a 1a                	mov    (%edx),%bl
f0103762:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103765:	80 3a 01             	cmpb   $0x1,(%edx)
f0103768:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010376b:	41                   	inc    %ecx
f010376c:	39 f1                	cmp    %esi,%ecx
f010376e:	75 f0                	jne    f0103760 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103770:	5b                   	pop    %ebx
f0103771:	5e                   	pop    %esi
f0103772:	5d                   	pop    %ebp
f0103773:	c3                   	ret    

f0103774 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103774:	55                   	push   %ebp
f0103775:	89 e5                	mov    %esp,%ebp
f0103777:	56                   	push   %esi
f0103778:	53                   	push   %ebx
f0103779:	8b 75 08             	mov    0x8(%ebp),%esi
f010377c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010377f:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103782:	85 d2                	test   %edx,%edx
f0103784:	75 0a                	jne    f0103790 <strlcpy+0x1c>
f0103786:	89 f0                	mov    %esi,%eax
f0103788:	eb 1a                	jmp    f01037a4 <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010378a:	88 18                	mov    %bl,(%eax)
f010378c:	40                   	inc    %eax
f010378d:	41                   	inc    %ecx
f010378e:	eb 02                	jmp    f0103792 <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103790:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f0103792:	4a                   	dec    %edx
f0103793:	74 0a                	je     f010379f <strlcpy+0x2b>
f0103795:	8a 19                	mov    (%ecx),%bl
f0103797:	84 db                	test   %bl,%bl
f0103799:	75 ef                	jne    f010378a <strlcpy+0x16>
f010379b:	89 c2                	mov    %eax,%edx
f010379d:	eb 02                	jmp    f01037a1 <strlcpy+0x2d>
f010379f:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01037a1:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01037a4:	29 f0                	sub    %esi,%eax
}
f01037a6:	5b                   	pop    %ebx
f01037a7:	5e                   	pop    %esi
f01037a8:	5d                   	pop    %ebp
f01037a9:	c3                   	ret    

f01037aa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01037aa:	55                   	push   %ebp
f01037ab:	89 e5                	mov    %esp,%ebp
f01037ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037b0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01037b3:	eb 02                	jmp    f01037b7 <strcmp+0xd>
		p++, q++;
f01037b5:	41                   	inc    %ecx
f01037b6:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01037b7:	8a 01                	mov    (%ecx),%al
f01037b9:	84 c0                	test   %al,%al
f01037bb:	74 04                	je     f01037c1 <strcmp+0x17>
f01037bd:	3a 02                	cmp    (%edx),%al
f01037bf:	74 f4                	je     f01037b5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01037c1:	0f b6 c0             	movzbl %al,%eax
f01037c4:	0f b6 12             	movzbl (%edx),%edx
f01037c7:	29 d0                	sub    %edx,%eax
}
f01037c9:	5d                   	pop    %ebp
f01037ca:	c3                   	ret    

f01037cb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01037cb:	55                   	push   %ebp
f01037cc:	89 e5                	mov    %esp,%ebp
f01037ce:	53                   	push   %ebx
f01037cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01037d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037d5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f01037d8:	eb 03                	jmp    f01037dd <strncmp+0x12>
		n--, p++, q++;
f01037da:	4a                   	dec    %edx
f01037db:	40                   	inc    %eax
f01037dc:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01037dd:	85 d2                	test   %edx,%edx
f01037df:	74 14                	je     f01037f5 <strncmp+0x2a>
f01037e1:	8a 18                	mov    (%eax),%bl
f01037e3:	84 db                	test   %bl,%bl
f01037e5:	74 04                	je     f01037eb <strncmp+0x20>
f01037e7:	3a 19                	cmp    (%ecx),%bl
f01037e9:	74 ef                	je     f01037da <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01037eb:	0f b6 00             	movzbl (%eax),%eax
f01037ee:	0f b6 11             	movzbl (%ecx),%edx
f01037f1:	29 d0                	sub    %edx,%eax
f01037f3:	eb 05                	jmp    f01037fa <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01037f5:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01037fa:	5b                   	pop    %ebx
f01037fb:	5d                   	pop    %ebp
f01037fc:	c3                   	ret    

f01037fd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01037fd:	55                   	push   %ebp
f01037fe:	89 e5                	mov    %esp,%ebp
f0103800:	8b 45 08             	mov    0x8(%ebp),%eax
f0103803:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0103806:	eb 05                	jmp    f010380d <strchr+0x10>
		if (*s == c)
f0103808:	38 ca                	cmp    %cl,%dl
f010380a:	74 0c                	je     f0103818 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010380c:	40                   	inc    %eax
f010380d:	8a 10                	mov    (%eax),%dl
f010380f:	84 d2                	test   %dl,%dl
f0103811:	75 f5                	jne    f0103808 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f0103813:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103818:	5d                   	pop    %ebp
f0103819:	c3                   	ret    

f010381a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010381a:	55                   	push   %ebp
f010381b:	89 e5                	mov    %esp,%ebp
f010381d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103820:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0103823:	eb 05                	jmp    f010382a <strfind+0x10>
		if (*s == c)
f0103825:	38 ca                	cmp    %cl,%dl
f0103827:	74 07                	je     f0103830 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103829:	40                   	inc    %eax
f010382a:	8a 10                	mov    (%eax),%dl
f010382c:	84 d2                	test   %dl,%dl
f010382e:	75 f5                	jne    f0103825 <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0103830:	5d                   	pop    %ebp
f0103831:	c3                   	ret    

f0103832 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103832:	55                   	push   %ebp
f0103833:	89 e5                	mov    %esp,%ebp
f0103835:	57                   	push   %edi
f0103836:	56                   	push   %esi
f0103837:	53                   	push   %ebx
f0103838:	8b 7d 08             	mov    0x8(%ebp),%edi
f010383b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010383e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103841:	85 c9                	test   %ecx,%ecx
f0103843:	74 30                	je     f0103875 <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103845:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010384b:	75 25                	jne    f0103872 <memset+0x40>
f010384d:	f6 c1 03             	test   $0x3,%cl
f0103850:	75 20                	jne    f0103872 <memset+0x40>
		c &= 0xFF;
f0103852:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103855:	89 d3                	mov    %edx,%ebx
f0103857:	c1 e3 08             	shl    $0x8,%ebx
f010385a:	89 d6                	mov    %edx,%esi
f010385c:	c1 e6 18             	shl    $0x18,%esi
f010385f:	89 d0                	mov    %edx,%eax
f0103861:	c1 e0 10             	shl    $0x10,%eax
f0103864:	09 f0                	or     %esi,%eax
f0103866:	09 d0                	or     %edx,%eax
f0103868:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010386a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010386d:	fc                   	cld    
f010386e:	f3 ab                	rep stos %eax,%es:(%edi)
f0103870:	eb 03                	jmp    f0103875 <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103872:	fc                   	cld    
f0103873:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103875:	89 f8                	mov    %edi,%eax
f0103877:	5b                   	pop    %ebx
f0103878:	5e                   	pop    %esi
f0103879:	5f                   	pop    %edi
f010387a:	5d                   	pop    %ebp
f010387b:	c3                   	ret    

f010387c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010387c:	55                   	push   %ebp
f010387d:	89 e5                	mov    %esp,%ebp
f010387f:	57                   	push   %edi
f0103880:	56                   	push   %esi
f0103881:	8b 45 08             	mov    0x8(%ebp),%eax
f0103884:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103887:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010388a:	39 c6                	cmp    %eax,%esi
f010388c:	73 34                	jae    f01038c2 <memmove+0x46>
f010388e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103891:	39 d0                	cmp    %edx,%eax
f0103893:	73 2d                	jae    f01038c2 <memmove+0x46>
		s += n;
		d += n;
f0103895:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103898:	f6 c2 03             	test   $0x3,%dl
f010389b:	75 1b                	jne    f01038b8 <memmove+0x3c>
f010389d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01038a3:	75 13                	jne    f01038b8 <memmove+0x3c>
f01038a5:	f6 c1 03             	test   $0x3,%cl
f01038a8:	75 0e                	jne    f01038b8 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01038aa:	83 ef 04             	sub    $0x4,%edi
f01038ad:	8d 72 fc             	lea    -0x4(%edx),%esi
f01038b0:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01038b3:	fd                   	std    
f01038b4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038b6:	eb 07                	jmp    f01038bf <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01038b8:	4f                   	dec    %edi
f01038b9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01038bc:	fd                   	std    
f01038bd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01038bf:	fc                   	cld    
f01038c0:	eb 20                	jmp    f01038e2 <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038c2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01038c8:	75 13                	jne    f01038dd <memmove+0x61>
f01038ca:	a8 03                	test   $0x3,%al
f01038cc:	75 0f                	jne    f01038dd <memmove+0x61>
f01038ce:	f6 c1 03             	test   $0x3,%cl
f01038d1:	75 0a                	jne    f01038dd <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01038d3:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01038d6:	89 c7                	mov    %eax,%edi
f01038d8:	fc                   	cld    
f01038d9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038db:	eb 05                	jmp    f01038e2 <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01038dd:	89 c7                	mov    %eax,%edi
f01038df:	fc                   	cld    
f01038e0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01038e2:	5e                   	pop    %esi
f01038e3:	5f                   	pop    %edi
f01038e4:	5d                   	pop    %ebp
f01038e5:	c3                   	ret    

f01038e6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01038e6:	55                   	push   %ebp
f01038e7:	89 e5                	mov    %esp,%ebp
f01038e9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01038ec:	8b 45 10             	mov    0x10(%ebp),%eax
f01038ef:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01038fd:	89 04 24             	mov    %eax,(%esp)
f0103900:	e8 77 ff ff ff       	call   f010387c <memmove>
}
f0103905:	c9                   	leave  
f0103906:	c3                   	ret    

f0103907 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103907:	55                   	push   %ebp
f0103908:	89 e5                	mov    %esp,%ebp
f010390a:	57                   	push   %edi
f010390b:	56                   	push   %esi
f010390c:	53                   	push   %ebx
f010390d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103910:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103913:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103916:	ba 00 00 00 00       	mov    $0x0,%edx
f010391b:	eb 16                	jmp    f0103933 <memcmp+0x2c>
		if (*s1 != *s2)
f010391d:	8a 04 17             	mov    (%edi,%edx,1),%al
f0103920:	42                   	inc    %edx
f0103921:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f0103925:	38 c8                	cmp    %cl,%al
f0103927:	74 0a                	je     f0103933 <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f0103929:	0f b6 c0             	movzbl %al,%eax
f010392c:	0f b6 c9             	movzbl %cl,%ecx
f010392f:	29 c8                	sub    %ecx,%eax
f0103931:	eb 09                	jmp    f010393c <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103933:	39 da                	cmp    %ebx,%edx
f0103935:	75 e6                	jne    f010391d <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103937:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010393c:	5b                   	pop    %ebx
f010393d:	5e                   	pop    %esi
f010393e:	5f                   	pop    %edi
f010393f:	5d                   	pop    %ebp
f0103940:	c3                   	ret    

f0103941 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103941:	55                   	push   %ebp
f0103942:	89 e5                	mov    %esp,%ebp
f0103944:	8b 45 08             	mov    0x8(%ebp),%eax
f0103947:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010394a:	89 c2                	mov    %eax,%edx
f010394c:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010394f:	eb 05                	jmp    f0103956 <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103951:	38 08                	cmp    %cl,(%eax)
f0103953:	74 05                	je     f010395a <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103955:	40                   	inc    %eax
f0103956:	39 d0                	cmp    %edx,%eax
f0103958:	72 f7                	jb     f0103951 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010395a:	5d                   	pop    %ebp
f010395b:	c3                   	ret    

f010395c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010395c:	55                   	push   %ebp
f010395d:	89 e5                	mov    %esp,%ebp
f010395f:	57                   	push   %edi
f0103960:	56                   	push   %esi
f0103961:	53                   	push   %ebx
f0103962:	8b 55 08             	mov    0x8(%ebp),%edx
f0103965:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103968:	eb 01                	jmp    f010396b <strtol+0xf>
		s++;
f010396a:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010396b:	8a 02                	mov    (%edx),%al
f010396d:	3c 20                	cmp    $0x20,%al
f010396f:	74 f9                	je     f010396a <strtol+0xe>
f0103971:	3c 09                	cmp    $0x9,%al
f0103973:	74 f5                	je     f010396a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103975:	3c 2b                	cmp    $0x2b,%al
f0103977:	75 08                	jne    f0103981 <strtol+0x25>
		s++;
f0103979:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010397a:	bf 00 00 00 00       	mov    $0x0,%edi
f010397f:	eb 13                	jmp    f0103994 <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103981:	3c 2d                	cmp    $0x2d,%al
f0103983:	75 0a                	jne    f010398f <strtol+0x33>
		s++, neg = 1;
f0103985:	8d 52 01             	lea    0x1(%edx),%edx
f0103988:	bf 01 00 00 00       	mov    $0x1,%edi
f010398d:	eb 05                	jmp    f0103994 <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010398f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103994:	85 db                	test   %ebx,%ebx
f0103996:	74 05                	je     f010399d <strtol+0x41>
f0103998:	83 fb 10             	cmp    $0x10,%ebx
f010399b:	75 28                	jne    f01039c5 <strtol+0x69>
f010399d:	8a 02                	mov    (%edx),%al
f010399f:	3c 30                	cmp    $0x30,%al
f01039a1:	75 10                	jne    f01039b3 <strtol+0x57>
f01039a3:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01039a7:	75 0a                	jne    f01039b3 <strtol+0x57>
		s += 2, base = 16;
f01039a9:	83 c2 02             	add    $0x2,%edx
f01039ac:	bb 10 00 00 00       	mov    $0x10,%ebx
f01039b1:	eb 12                	jmp    f01039c5 <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f01039b3:	85 db                	test   %ebx,%ebx
f01039b5:	75 0e                	jne    f01039c5 <strtol+0x69>
f01039b7:	3c 30                	cmp    $0x30,%al
f01039b9:	75 05                	jne    f01039c0 <strtol+0x64>
		s++, base = 8;
f01039bb:	42                   	inc    %edx
f01039bc:	b3 08                	mov    $0x8,%bl
f01039be:	eb 05                	jmp    f01039c5 <strtol+0x69>
	else if (base == 0)
		base = 10;
f01039c0:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01039c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01039ca:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01039cc:	8a 0a                	mov    (%edx),%cl
f01039ce:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01039d1:	80 fb 09             	cmp    $0x9,%bl
f01039d4:	77 08                	ja     f01039de <strtol+0x82>
			dig = *s - '0';
f01039d6:	0f be c9             	movsbl %cl,%ecx
f01039d9:	83 e9 30             	sub    $0x30,%ecx
f01039dc:	eb 1e                	jmp    f01039fc <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f01039de:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01039e1:	80 fb 19             	cmp    $0x19,%bl
f01039e4:	77 08                	ja     f01039ee <strtol+0x92>
			dig = *s - 'a' + 10;
f01039e6:	0f be c9             	movsbl %cl,%ecx
f01039e9:	83 e9 57             	sub    $0x57,%ecx
f01039ec:	eb 0e                	jmp    f01039fc <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f01039ee:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01039f1:	80 fb 19             	cmp    $0x19,%bl
f01039f4:	77 12                	ja     f0103a08 <strtol+0xac>
			dig = *s - 'A' + 10;
f01039f6:	0f be c9             	movsbl %cl,%ecx
f01039f9:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01039fc:	39 f1                	cmp    %esi,%ecx
f01039fe:	7d 0c                	jge    f0103a0c <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f0103a00:	42                   	inc    %edx
f0103a01:	0f af c6             	imul   %esi,%eax
f0103a04:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103a06:	eb c4                	jmp    f01039cc <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103a08:	89 c1                	mov    %eax,%ecx
f0103a0a:	eb 02                	jmp    f0103a0e <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103a0c:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103a0e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a12:	74 05                	je     f0103a19 <strtol+0xbd>
		*endptr = (char *) s;
f0103a14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a17:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103a19:	85 ff                	test   %edi,%edi
f0103a1b:	74 04                	je     f0103a21 <strtol+0xc5>
f0103a1d:	89 c8                	mov    %ecx,%eax
f0103a1f:	f7 d8                	neg    %eax
}
f0103a21:	5b                   	pop    %ebx
f0103a22:	5e                   	pop    %esi
f0103a23:	5f                   	pop    %edi
f0103a24:	5d                   	pop    %ebp
f0103a25:	c3                   	ret    
	...

f0103a28 <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f0103a28:	55                   	push   %ebp
f0103a29:	57                   	push   %edi
f0103a2a:	56                   	push   %esi
f0103a2b:	83 ec 10             	sub    $0x10,%esp
f0103a2e:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103a32:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f0103a36:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103a3a:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f0103a3e:	89 cd                	mov    %ecx,%ebp
f0103a40:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0103a44:	85 c0                	test   %eax,%eax
f0103a46:	75 2c                	jne    f0103a74 <__udivdi3+0x4c>
    {
      if (d0 > n1)
f0103a48:	39 f9                	cmp    %edi,%ecx
f0103a4a:	77 68                	ja     f0103ab4 <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0103a4c:	85 c9                	test   %ecx,%ecx
f0103a4e:	75 0b                	jne    f0103a5b <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0103a50:	b8 01 00 00 00       	mov    $0x1,%eax
f0103a55:	31 d2                	xor    %edx,%edx
f0103a57:	f7 f1                	div    %ecx
f0103a59:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0103a5b:	31 d2                	xor    %edx,%edx
f0103a5d:	89 f8                	mov    %edi,%eax
f0103a5f:	f7 f1                	div    %ecx
f0103a61:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103a63:	89 f0                	mov    %esi,%eax
f0103a65:	f7 f1                	div    %ecx
f0103a67:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103a69:	89 f0                	mov    %esi,%eax
f0103a6b:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103a6d:	83 c4 10             	add    $0x10,%esp
f0103a70:	5e                   	pop    %esi
f0103a71:	5f                   	pop    %edi
f0103a72:	5d                   	pop    %ebp
f0103a73:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0103a74:	39 f8                	cmp    %edi,%eax
f0103a76:	77 2c                	ja     f0103aa4 <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0103a78:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f0103a7b:	83 f6 1f             	xor    $0x1f,%esi
f0103a7e:	75 4c                	jne    f0103acc <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103a80:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103a82:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103a87:	72 0a                	jb     f0103a93 <__udivdi3+0x6b>
f0103a89:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0103a8d:	0f 87 ad 00 00 00    	ja     f0103b40 <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103a93:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103a98:	89 f0                	mov    %esi,%eax
f0103a9a:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103a9c:	83 c4 10             	add    $0x10,%esp
f0103a9f:	5e                   	pop    %esi
f0103aa0:	5f                   	pop    %edi
f0103aa1:	5d                   	pop    %ebp
f0103aa2:	c3                   	ret    
f0103aa3:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0103aa4:	31 ff                	xor    %edi,%edi
f0103aa6:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103aa8:	89 f0                	mov    %esi,%eax
f0103aaa:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103aac:	83 c4 10             	add    $0x10,%esp
f0103aaf:	5e                   	pop    %esi
f0103ab0:	5f                   	pop    %edi
f0103ab1:	5d                   	pop    %ebp
f0103ab2:	c3                   	ret    
f0103ab3:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103ab4:	89 fa                	mov    %edi,%edx
f0103ab6:	89 f0                	mov    %esi,%eax
f0103ab8:	f7 f1                	div    %ecx
f0103aba:	89 c6                	mov    %eax,%esi
f0103abc:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103abe:	89 f0                	mov    %esi,%eax
f0103ac0:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103ac2:	83 c4 10             	add    $0x10,%esp
f0103ac5:	5e                   	pop    %esi
f0103ac6:	5f                   	pop    %edi
f0103ac7:	5d                   	pop    %ebp
f0103ac8:	c3                   	ret    
f0103ac9:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0103acc:	89 f1                	mov    %esi,%ecx
f0103ace:	d3 e0                	shl    %cl,%eax
f0103ad0:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f0103ad4:	b8 20 00 00 00       	mov    $0x20,%eax
f0103ad9:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f0103adb:	89 ea                	mov    %ebp,%edx
f0103add:	88 c1                	mov    %al,%cl
f0103adf:	d3 ea                	shr    %cl,%edx
f0103ae1:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f0103ae5:	09 ca                	or     %ecx,%edx
f0103ae7:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f0103aeb:	89 f1                	mov    %esi,%ecx
f0103aed:	d3 e5                	shl    %cl,%ebp
f0103aef:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f0103af3:	89 fd                	mov    %edi,%ebp
f0103af5:	88 c1                	mov    %al,%cl
f0103af7:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f0103af9:	89 fa                	mov    %edi,%edx
f0103afb:	89 f1                	mov    %esi,%ecx
f0103afd:	d3 e2                	shl    %cl,%edx
f0103aff:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103b03:	88 c1                	mov    %al,%cl
f0103b05:	d3 ef                	shr    %cl,%edi
f0103b07:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0103b09:	89 f8                	mov    %edi,%eax
f0103b0b:	89 ea                	mov    %ebp,%edx
f0103b0d:	f7 74 24 08          	divl   0x8(%esp)
f0103b11:	89 d1                	mov    %edx,%ecx
f0103b13:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f0103b15:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103b19:	39 d1                	cmp    %edx,%ecx
f0103b1b:	72 17                	jb     f0103b34 <__udivdi3+0x10c>
f0103b1d:	74 09                	je     f0103b28 <__udivdi3+0x100>
f0103b1f:	89 fe                	mov    %edi,%esi
f0103b21:	31 ff                	xor    %edi,%edi
f0103b23:	e9 41 ff ff ff       	jmp    f0103a69 <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0103b28:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103b2c:	89 f1                	mov    %esi,%ecx
f0103b2e:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103b30:	39 c2                	cmp    %eax,%edx
f0103b32:	73 eb                	jae    f0103b1f <__udivdi3+0xf7>
		{
		  q0--;
f0103b34:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0103b37:	31 ff                	xor    %edi,%edi
f0103b39:	e9 2b ff ff ff       	jmp    f0103a69 <__udivdi3+0x41>
f0103b3e:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103b40:	31 f6                	xor    %esi,%esi
f0103b42:	e9 22 ff ff ff       	jmp    f0103a69 <__udivdi3+0x41>
	...

f0103b48 <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f0103b48:	55                   	push   %ebp
f0103b49:	57                   	push   %edi
f0103b4a:	56                   	push   %esi
f0103b4b:	83 ec 20             	sub    $0x20,%esp
f0103b4e:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103b52:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f0103b56:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103b5a:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f0103b5e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103b62:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f0103b66:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f0103b68:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0103b6a:	85 ed                	test   %ebp,%ebp
f0103b6c:	75 16                	jne    f0103b84 <__umoddi3+0x3c>
    {
      if (d0 > n1)
f0103b6e:	39 f1                	cmp    %esi,%ecx
f0103b70:	0f 86 a6 00 00 00    	jbe    f0103c1c <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103b76:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f0103b78:	89 d0                	mov    %edx,%eax
f0103b7a:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103b7c:	83 c4 20             	add    $0x20,%esp
f0103b7f:	5e                   	pop    %esi
f0103b80:	5f                   	pop    %edi
f0103b81:	5d                   	pop    %ebp
f0103b82:	c3                   	ret    
f0103b83:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0103b84:	39 f5                	cmp    %esi,%ebp
f0103b86:	0f 87 ac 00 00 00    	ja     f0103c38 <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0103b8c:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f0103b8f:	83 f0 1f             	xor    $0x1f,%eax
f0103b92:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103b96:	0f 84 a8 00 00 00    	je     f0103c44 <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0103b9c:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103ba0:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f0103ba2:	bf 20 00 00 00       	mov    $0x20,%edi
f0103ba7:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f0103bab:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103baf:	89 f9                	mov    %edi,%ecx
f0103bb1:	d3 e8                	shr    %cl,%eax
f0103bb3:	09 e8                	or     %ebp,%eax
f0103bb5:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f0103bb9:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103bbd:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103bc1:	d3 e0                	shl    %cl,%eax
f0103bc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f0103bc7:	89 f2                	mov    %esi,%edx
f0103bc9:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f0103bcb:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103bcf:	d3 e0                	shl    %cl,%eax
f0103bd1:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f0103bd5:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103bd9:	89 f9                	mov    %edi,%ecx
f0103bdb:	d3 e8                	shr    %cl,%eax
f0103bdd:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f0103bdf:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0103be1:	89 f2                	mov    %esi,%edx
f0103be3:	f7 74 24 18          	divl   0x18(%esp)
f0103be7:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f0103be9:	f7 64 24 0c          	mull   0xc(%esp)
f0103bed:	89 c5                	mov    %eax,%ebp
f0103bef:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103bf1:	39 d6                	cmp    %edx,%esi
f0103bf3:	72 67                	jb     f0103c5c <__umoddi3+0x114>
f0103bf5:	74 75                	je     f0103c6c <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f0103bf7:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0103bfb:	29 e8                	sub    %ebp,%eax
f0103bfd:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f0103bff:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103c03:	d3 e8                	shr    %cl,%eax
f0103c05:	89 f2                	mov    %esi,%edx
f0103c07:	89 f9                	mov    %edi,%ecx
f0103c09:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f0103c0b:	09 d0                	or     %edx,%eax
f0103c0d:	89 f2                	mov    %esi,%edx
f0103c0f:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103c13:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103c15:	83 c4 20             	add    $0x20,%esp
f0103c18:	5e                   	pop    %esi
f0103c19:	5f                   	pop    %edi
f0103c1a:	5d                   	pop    %ebp
f0103c1b:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0103c1c:	85 c9                	test   %ecx,%ecx
f0103c1e:	75 0b                	jne    f0103c2b <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0103c20:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c25:	31 d2                	xor    %edx,%edx
f0103c27:	f7 f1                	div    %ecx
f0103c29:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0103c2b:	89 f0                	mov    %esi,%eax
f0103c2d:	31 d2                	xor    %edx,%edx
f0103c2f:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103c31:	89 f8                	mov    %edi,%eax
f0103c33:	e9 3e ff ff ff       	jmp    f0103b76 <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0103c38:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103c3a:	83 c4 20             	add    $0x20,%esp
f0103c3d:	5e                   	pop    %esi
f0103c3e:	5f                   	pop    %edi
f0103c3f:	5d                   	pop    %ebp
f0103c40:	c3                   	ret    
f0103c41:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103c44:	39 f5                	cmp    %esi,%ebp
f0103c46:	72 04                	jb     f0103c4c <__umoddi3+0x104>
f0103c48:	39 f9                	cmp    %edi,%ecx
f0103c4a:	77 06                	ja     f0103c52 <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103c4c:	89 f2                	mov    %esi,%edx
f0103c4e:	29 cf                	sub    %ecx,%edi
f0103c50:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f0103c52:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103c54:	83 c4 20             	add    $0x20,%esp
f0103c57:	5e                   	pop    %esi
f0103c58:	5f                   	pop    %edi
f0103c59:	5d                   	pop    %ebp
f0103c5a:	c3                   	ret    
f0103c5b:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0103c5c:	89 d1                	mov    %edx,%ecx
f0103c5e:	89 c5                	mov    %eax,%ebp
f0103c60:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f0103c64:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f0103c68:	eb 8d                	jmp    f0103bf7 <__umoddi3+0xaf>
f0103c6a:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103c6c:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f0103c70:	72 ea                	jb     f0103c5c <__umoddi3+0x114>
f0103c72:	89 f1                	mov    %esi,%ecx
f0103c74:	eb 81                	jmp    f0103bf7 <__umoddi3+0xaf>
