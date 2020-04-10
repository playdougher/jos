
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
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 18 10 f0 	movl   $0xf0101860,(%esp)
f0100055:	e8 74 09 00 00       	call   f01009ce <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 cb 06 00 00       	call   f0100752 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 18 10 f0 	movl   $0xf010187c,(%esp)
f0100092:	e8 37 09 00 00       	call   f01009ce <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 40 a9 11 f0       	mov    $0xf011a940,%eax
f01000a8:	2d 00 a3 11 f0       	sub    $0xf011a300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 a3 11 f0 	movl   $0xf011a300,(%esp)
f01000c0:	e8 55 13 00 00       	call   f010141a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 77 04 00 00       	call   f0100541 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 18 10 f0 	movl   $0xf0101897,(%esp)
f01000d9:	e8 f0 08 00 00       	call   f01009ce <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 fe 06 00 00       	call   f01007f4 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 44 a9 11 f0 00 	cmpl   $0x0,0xf011a944
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 44 a9 11 f0    	mov    %esi,0xf011a944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 18 10 f0 	movl   $0xf01018b2,(%esp)
f010012c:	e8 9d 08 00 00       	call   f01009ce <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 5e 08 00 00       	call   f010099b <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f0100144:	e8 85 08 00 00       	call   f01009ce <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 9f 06 00 00       	call   f01007f4 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 18 10 f0 	movl   $0xf01018ca,(%esp)
f0100176:	e8 53 08 00 00       	call   f01009ce <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 11 08 00 00       	call   f010099b <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 18 10 f0 	movl   $0xf01018ee,(%esp)
f0100191:	e8 38 08 00 00       	call   f01009ce <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    

f010019c <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010019c:	55                   	push   %ebp
f010019d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010019f:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a4:	ec                   	in     (%dx),%al
f01001a5:	ec                   	in     (%dx),%al
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b2:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b3:	a8 01                	test   $0x1,%al
f01001b5:	74 08                	je     f01001bf <serial_proc_data+0x15>
f01001b7:	b2 f8                	mov    $0xf8,%dl
f01001b9:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001ba:	0f b6 c0             	movzbl %al,%eax
f01001bd:	eb 05                	jmp    f01001c4 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c4:	5d                   	pop    %ebp
f01001c5:	c3                   	ret    

f01001c6 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001c6:	55                   	push   %ebp
f01001c7:	89 e5                	mov    %esp,%ebp
f01001c9:	53                   	push   %ebx
f01001ca:	83 ec 04             	sub    $0x4,%esp
f01001cd:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001cf:	eb 29                	jmp    f01001fa <cons_intr+0x34>
		if (c == 0)
f01001d1:	85 c0                	test   %eax,%eax
f01001d3:	74 25                	je     f01001fa <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d5:	8b 15 24 a5 11 f0    	mov    0xf011a524,%edx
f01001db:	88 82 20 a3 11 f0    	mov    %al,-0xfee5ce0(%edx)
f01001e1:	8d 42 01             	lea    0x1(%edx),%eax
f01001e4:	a3 24 a5 11 f0       	mov    %eax,0xf011a524
		if (cons.wpos == CONSBUFSIZE)
f01001e9:	3d 00 02 00 00       	cmp    $0x200,%eax
f01001ee:	75 0a                	jne    f01001fa <cons_intr+0x34>
			cons.wpos = 0;
f01001f0:	c7 05 24 a5 11 f0 00 	movl   $0x0,0xf011a524
f01001f7:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d0                	jne    f01001d1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c6                	mov    %eax,%esi
f0100212:	bb 01 32 00 00       	mov    $0x3201,%ebx
f0100217:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010021c:	eb 05                	jmp    f0100223 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010021e:	e8 79 ff ff ff       	call   f010019c <delay>
f0100223:	89 fa                	mov    %edi,%edx
f0100225:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100226:	a8 20                	test   $0x20,%al
f0100228:	75 03                	jne    f010022d <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022a:	4b                   	dec    %ebx
f010022b:	75 f1                	jne    f010021e <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010022d:	89 f2                	mov    %esi,%edx
f010022f:	89 f0                	mov    %esi,%eax
f0100231:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100234:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100239:	ee                   	out    %al,(%dx)
f010023a:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010023f:	bf 79 03 00 00       	mov    $0x379,%edi
f0100244:	eb 05                	jmp    f010024b <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f0100246:	e8 51 ff ff ff       	call   f010019c <delay>
f010024b:	89 fa                	mov    %edi,%edx
f010024d:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024e:	84 c0                	test   %al,%al
f0100250:	78 03                	js     f0100255 <cons_putc+0x4e>
f0100252:	4b                   	dec    %ebx
f0100253:	75 f1                	jne    f0100246 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100255:	ba 78 03 00 00       	mov    $0x378,%edx
f010025a:	8a 45 e7             	mov    -0x19(%ebp),%al
f010025d:	ee                   	out    %al,(%dx)
f010025e:	b2 7a                	mov    $0x7a,%dl
f0100260:	b0 0d                	mov    $0xd,%al
f0100262:	ee                   	out    %al,(%dx)
f0100263:	b0 08                	mov    $0x8,%al
f0100265:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100266:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f010026c:	75 06                	jne    f0100274 <cons_putc+0x6d>
		c |= 0x0700;
f010026e:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100274:	89 f0                	mov    %esi,%eax
f0100276:	25 ff 00 00 00       	and    $0xff,%eax
f010027b:	83 f8 09             	cmp    $0x9,%eax
f010027e:	74 78                	je     f01002f8 <cons_putc+0xf1>
f0100280:	83 f8 09             	cmp    $0x9,%eax
f0100283:	7f 0b                	jg     f0100290 <cons_putc+0x89>
f0100285:	83 f8 08             	cmp    $0x8,%eax
f0100288:	0f 85 9e 00 00 00    	jne    f010032c <cons_putc+0x125>
f010028e:	eb 10                	jmp    f01002a0 <cons_putc+0x99>
f0100290:	83 f8 0a             	cmp    $0xa,%eax
f0100293:	74 39                	je     f01002ce <cons_putc+0xc7>
f0100295:	83 f8 0d             	cmp    $0xd,%eax
f0100298:	0f 85 8e 00 00 00    	jne    f010032c <cons_putc+0x125>
f010029e:	eb 36                	jmp    f01002d6 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f01002a0:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f01002a6:	66 85 c0             	test   %ax,%ax
f01002a9:	0f 84 e2 00 00 00    	je     f0100391 <cons_putc+0x18a>
			crt_pos--;
f01002af:	48                   	dec    %eax
f01002b0:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002b6:	0f b7 c0             	movzwl %ax,%eax
f01002b9:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f01002bf:	83 ce 20             	or     $0x20,%esi
f01002c2:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f01002c8:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f01002cc:	eb 78                	jmp    f0100346 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002ce:	66 83 05 34 a5 11 f0 	addw   $0x50,0xf011a534
f01002d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002d6:	66 8b 0d 34 a5 11 f0 	mov    0xf011a534,%cx
f01002dd:	bb 50 00 00 00       	mov    $0x50,%ebx
f01002e2:	89 c8                	mov    %ecx,%eax
f01002e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01002e9:	66 f7 f3             	div    %bx
f01002ec:	66 29 d1             	sub    %dx,%cx
f01002ef:	66 89 0d 34 a5 11 f0 	mov    %cx,0xf011a534
f01002f6:	eb 4e                	jmp    f0100346 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f01002f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fd:	e8 05 ff ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100302:	b8 20 00 00 00       	mov    $0x20,%eax
f0100307:	e8 fb fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010030c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100311:	e8 f1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100316:	b8 20 00 00 00       	mov    $0x20,%eax
f010031b:	e8 e7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100320:	b8 20 00 00 00       	mov    $0x20,%eax
f0100325:	e8 dd fe ff ff       	call   f0100207 <cons_putc>
f010032a:	eb 1a                	jmp    f0100346 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010032c:	66 a1 34 a5 11 f0    	mov    0xf011a534,%ax
f0100332:	0f b7 c8             	movzwl %ax,%ecx
f0100335:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
f010033b:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f010033f:	40                   	inc    %eax
f0100340:	66 a3 34 a5 11 f0    	mov    %ax,0xf011a534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100346:	66 81 3d 34 a5 11 f0 	cmpw   $0x7cf,0xf011a534
f010034d:	cf 07 
f010034f:	76 40                	jbe    f0100391 <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100351:	a1 30 a5 11 f0       	mov    0xf011a530,%eax
f0100356:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010035d:	00 
f010035e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100364:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100368:	89 04 24             	mov    %eax,(%esp)
f010036b:	e8 f4 10 00 00       	call   f0101464 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100370:	8b 15 30 a5 11 f0    	mov    0xf011a530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100376:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010037b:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100381:	40                   	inc    %eax
f0100382:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100387:	75 f2                	jne    f010037b <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100389:	66 83 2d 34 a5 11 f0 	subw   $0x50,0xf011a534
f0100390:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100391:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f0100397:	b0 0e                	mov    $0xe,%al
f0100399:	89 ca                	mov    %ecx,%edx
f010039b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010039c:	66 8b 35 34 a5 11 f0 	mov    0xf011a534,%si
f01003a3:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003a6:	89 f0                	mov    %esi,%eax
f01003a8:	66 c1 e8 08          	shr    $0x8,%ax
f01003ac:	89 da                	mov    %ebx,%edx
f01003ae:	ee                   	out    %al,(%dx)
f01003af:	b0 0f                	mov    $0xf,%al
f01003b1:	89 ca                	mov    %ecx,%edx
f01003b3:	ee                   	out    %al,(%dx)
f01003b4:	89 f0                	mov    %esi,%eax
f01003b6:	89 da                	mov    %ebx,%edx
f01003b8:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b9:	83 c4 2c             	add    $0x2c,%esp
f01003bc:	5b                   	pop    %ebx
f01003bd:	5e                   	pop    %esi
f01003be:	5f                   	pop    %edi
f01003bf:	5d                   	pop    %ebp
f01003c0:	c3                   	ret    

f01003c1 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003c1:	55                   	push   %ebp
f01003c2:	89 e5                	mov    %esp,%ebp
f01003c4:	53                   	push   %ebx
f01003c5:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c8:	ba 64 00 00 00       	mov    $0x64,%edx
f01003cd:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003ce:	0f b6 c0             	movzbl %al,%eax
f01003d1:	a8 01                	test   $0x1,%al
f01003d3:	0f 84 e0 00 00 00    	je     f01004b9 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003d9:	a8 20                	test   $0x20,%al
f01003db:	0f 85 df 00 00 00    	jne    f01004c0 <kbd_proc_data+0xff>
f01003e1:	b2 60                	mov    $0x60,%dl
f01003e3:	ec                   	in     (%dx),%al
f01003e4:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003e6:	3c e0                	cmp    $0xe0,%al
f01003e8:	75 11                	jne    f01003fb <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f01003ea:	83 0d 28 a5 11 f0 40 	orl    $0x40,0xf011a528
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 ca 00 00 00       	jmp    f01004c5 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f01003fb:	84 c0                	test   %al,%al
f01003fd:	79 33                	jns    f0100432 <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003ff:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f0100405:	f6 c1 40             	test   $0x40,%cl
f0100408:	75 05                	jne    f010040f <kbd_proc_data+0x4e>
f010040a:	88 c2                	mov    %al,%dl
f010040c:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010040f:	0f b6 d2             	movzbl %dl,%edx
f0100412:	8a 82 20 19 10 f0    	mov    -0xfefe6e0(%edx),%al
f0100418:	83 c8 40             	or     $0x40,%eax
f010041b:	0f b6 c0             	movzbl %al,%eax
f010041e:	f7 d0                	not    %eax
f0100420:	21 c1                	and    %eax,%ecx
f0100422:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
		return 0;
f0100428:	bb 00 00 00 00       	mov    $0x0,%ebx
f010042d:	e9 93 00 00 00       	jmp    f01004c5 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f0100432:	8b 0d 28 a5 11 f0    	mov    0xf011a528,%ecx
f0100438:	f6 c1 40             	test   $0x40,%cl
f010043b:	74 0e                	je     f010044b <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010043d:	88 c2                	mov    %al,%dl
f010043f:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100442:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100445:	89 0d 28 a5 11 f0    	mov    %ecx,0xf011a528
	}

	shift |= shiftcode[data];
f010044b:	0f b6 d2             	movzbl %dl,%edx
f010044e:	0f b6 82 20 19 10 f0 	movzbl -0xfefe6e0(%edx),%eax
f0100455:	0b 05 28 a5 11 f0    	or     0xf011a528,%eax
	shift ^= togglecode[data];
f010045b:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f0100462:	31 c8                	xor    %ecx,%eax
f0100464:	a3 28 a5 11 f0       	mov    %eax,0xf011a528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100469:	89 c1                	mov    %eax,%ecx
f010046b:	83 e1 03             	and    $0x3,%ecx
f010046e:	8b 0c 8d 20 1b 10 f0 	mov    -0xfefe4e0(,%ecx,4),%ecx
f0100475:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100479:	a8 08                	test   $0x8,%al
f010047b:	74 18                	je     f0100495 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f010047d:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100480:	83 fa 19             	cmp    $0x19,%edx
f0100483:	77 05                	ja     f010048a <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100485:	83 eb 20             	sub    $0x20,%ebx
f0100488:	eb 0b                	jmp    f0100495 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f010048a:	8d 53 bf             	lea    -0x41(%ebx),%edx
f010048d:	83 fa 19             	cmp    $0x19,%edx
f0100490:	77 03                	ja     f0100495 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f0100492:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100495:	f7 d0                	not    %eax
f0100497:	a8 06                	test   $0x6,%al
f0100499:	75 2a                	jne    f01004c5 <kbd_proc_data+0x104>
f010049b:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a1:	75 22                	jne    f01004c5 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01004a3:	c7 04 24 e4 18 10 f0 	movl   $0xf01018e4,(%esp)
f01004aa:	e8 1f 05 00 00       	call   f01009ce <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004af:	ba 92 00 00 00       	mov    $0x92,%edx
f01004b4:	b0 03                	mov    $0x3,%al
f01004b6:	ee                   	out    %al,(%dx)
f01004b7:	eb 0c                	jmp    f01004c5 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004b9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004be:	eb 05                	jmp    f01004c5 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004c0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004c5:	89 d8                	mov    %ebx,%eax
f01004c7:	83 c4 14             	add    $0x14,%esp
f01004ca:	5b                   	pop    %ebx
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004cd:	55                   	push   %ebp
f01004ce:	89 e5                	mov    %esp,%ebp
f01004d0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004d3:	80 3d 00 a3 11 f0 00 	cmpb   $0x0,0xf011a300
f01004da:	74 0a                	je     f01004e6 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004dc:	b8 aa 01 10 f0       	mov    $0xf01001aa,%eax
f01004e1:	e8 e0 fc ff ff       	call   f01001c6 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	c3                   	ret    

f01004e8 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e8:	55                   	push   %ebp
f01004e9:	89 e5                	mov    %esp,%ebp
f01004eb:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ee:	b8 c1 03 10 f0       	mov    $0xf01003c1,%eax
f01004f3:	e8 ce fc ff ff       	call   f01001c6 <cons_intr>
}
f01004f8:	c9                   	leave  
f01004f9:	c3                   	ret    

f01004fa <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fa:	55                   	push   %ebp
f01004fb:	89 e5                	mov    %esp,%ebp
f01004fd:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100500:	e8 c8 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100505:	e8 de ff ff ff       	call   f01004e8 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050a:	8b 15 20 a5 11 f0    	mov    0xf011a520,%edx
f0100510:	3b 15 24 a5 11 f0    	cmp    0xf011a524,%edx
f0100516:	74 22                	je     f010053a <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f0100518:	0f b6 82 20 a3 11 f0 	movzbl -0xfee5ce0(%edx),%eax
f010051f:	42                   	inc    %edx
f0100520:	89 15 20 a5 11 f0    	mov    %edx,0xf011a520
		if (cons.rpos == CONSBUFSIZE)
f0100526:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052c:	75 11                	jne    f010053f <cons_getc+0x45>
			cons.rpos = 0;
f010052e:	c7 05 20 a5 11 f0 00 	movl   $0x0,0xf011a520
f0100535:	00 00 00 
f0100538:	eb 05                	jmp    f010053f <cons_getc+0x45>
		return c;
	}
	return 0;
f010053a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010053f:	c9                   	leave  
f0100540:	c3                   	ret    

f0100541 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100541:	55                   	push   %ebp
f0100542:	89 e5                	mov    %esp,%ebp
f0100544:	57                   	push   %edi
f0100545:	56                   	push   %esi
f0100546:	53                   	push   %ebx
f0100547:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054a:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f0100551:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100558:	5a a5 
	if (*cp != 0xA55A) {
f010055a:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100560:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100564:	74 11                	je     f0100577 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100566:	c7 05 2c a5 11 f0 b4 	movl   $0x3b4,0xf011a52c
f010056d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100570:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100575:	eb 16                	jmp    f010058d <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100577:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010057e:	c7 05 2c a5 11 f0 d4 	movl   $0x3d4,0xf011a52c
f0100585:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100588:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058d:	8b 0d 2c a5 11 f0    	mov    0xf011a52c,%ecx
f0100593:	b0 0e                	mov    $0xe,%al
f0100595:	89 ca                	mov    %ecx,%edx
f0100597:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100598:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059b:	89 da                	mov    %ebx,%edx
f010059d:	ec                   	in     (%dx),%al
f010059e:	0f b6 f8             	movzbl %al,%edi
f01005a1:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a4:	b0 0f                	mov    $0xf,%al
f01005a6:	89 ca                	mov    %ecx,%edx
f01005a8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a9:	89 da                	mov    %ebx,%edx
f01005ab:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ac:	89 35 30 a5 11 f0    	mov    %esi,0xf011a530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005b2:	0f b6 d8             	movzbl %al,%ebx
f01005b5:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005b7:	66 89 3d 34 a5 11 f0 	mov    %di,0xf011a534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005be:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005c3:	b0 00                	mov    $0x0,%al
f01005c5:	89 da                	mov    %ebx,%edx
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	b2 fb                	mov    $0xfb,%dl
f01005ca:	b0 80                	mov    $0x80,%al
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005d2:	b0 0c                	mov    $0xc,%al
f01005d4:	89 ca                	mov    %ecx,%edx
f01005d6:	ee                   	out    %al,(%dx)
f01005d7:	b2 f9                	mov    $0xf9,%dl
f01005d9:	b0 00                	mov    $0x0,%al
f01005db:	ee                   	out    %al,(%dx)
f01005dc:	b2 fb                	mov    $0xfb,%dl
f01005de:	b0 03                	mov    $0x3,%al
f01005e0:	ee                   	out    %al,(%dx)
f01005e1:	b2 fc                	mov    $0xfc,%dl
f01005e3:	b0 00                	mov    $0x0,%al
f01005e5:	ee                   	out    %al,(%dx)
f01005e6:	b2 f9                	mov    $0xf9,%dl
f01005e8:	b0 01                	mov    $0x1,%al
f01005ea:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005eb:	b2 fd                	mov    $0xfd,%dl
f01005ed:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005ee:	3c ff                	cmp    $0xff,%al
f01005f0:	0f 95 45 e7          	setne  -0x19(%ebp)
f01005f4:	8a 45 e7             	mov    -0x19(%ebp),%al
f01005f7:	a2 00 a3 11 f0       	mov    %al,0xf011a300
f01005fc:	89 da                	mov    %ebx,%edx
f01005fe:	ec                   	in     (%dx),%al
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100602:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f0100606:	75 0c                	jne    f0100614 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f0100608:	c7 04 24 f0 18 10 f0 	movl   $0xf01018f0,(%esp)
f010060f:	e8 ba 03 00 00       	call   f01009ce <cprintf>
}
f0100614:	83 c4 2c             	add    $0x2c,%esp
f0100617:	5b                   	pop    %ebx
f0100618:	5e                   	pop    %esi
f0100619:	5f                   	pop    %edi
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    

f010061c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010061c:	55                   	push   %ebp
f010061d:	89 e5                	mov    %esp,%ebp
f010061f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100622:	8b 45 08             	mov    0x8(%ebp),%eax
f0100625:	e8 dd fb ff ff       	call   f0100207 <cons_putc>
}
f010062a:	c9                   	leave  
f010062b:	c3                   	ret    

f010062c <getchar>:

int
getchar(void)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100632:	e8 c3 fe ff ff       	call   f01004fa <cons_getc>
f0100637:	85 c0                	test   %eax,%eax
f0100639:	74 f7                	je     f0100632 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010063b:	c9                   	leave  
f010063c:	c3                   	ret    

f010063d <iscons>:

int
iscons(int fdnum)
{
f010063d:	55                   	push   %ebp
f010063e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100640:	b8 01 00 00 00       	mov    $0x1,%eax
f0100645:	5d                   	pop    %ebp
f0100646:	c3                   	ret    
	...

f0100648 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100648:	55                   	push   %ebp
f0100649:	89 e5                	mov    %esp,%ebp
f010064b:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010064e:	c7 04 24 30 1b 10 f0 	movl   $0xf0101b30,(%esp)
f0100655:	e8 74 03 00 00       	call   f01009ce <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010065a:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100661:	00 
f0100662:	c7 04 24 20 1c 10 f0 	movl   $0xf0101c20,(%esp)
f0100669:	e8 60 03 00 00       	call   f01009ce <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010066e:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100675:	00 
f0100676:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 48 1c 10 f0 	movl   $0xf0101c48,(%esp)
f0100685:	e8 44 03 00 00       	call   f01009ce <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068a:	c7 44 24 08 5e 18 10 	movl   $0x10185e,0x8(%esp)
f0100691:	00 
f0100692:	c7 44 24 04 5e 18 10 	movl   $0xf010185e,0x4(%esp)
f0100699:	f0 
f010069a:	c7 04 24 6c 1c 10 f0 	movl   $0xf0101c6c,(%esp)
f01006a1:	e8 28 03 00 00       	call   f01009ce <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a6:	c7 44 24 08 00 a3 11 	movl   $0x11a300,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 00 a3 11 	movl   $0xf011a300,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 90 1c 10 f0 	movl   $0xf0101c90,(%esp)
f01006bd:	e8 0c 03 00 00       	call   f01009ce <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c2:	c7 44 24 08 40 a9 11 	movl   $0x11a940,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 40 a9 11 	movl   $0xf011a940,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 b4 1c 10 f0 	movl   $0xf0101cb4,(%esp)
f01006d9:	e8 f0 02 00 00       	call   f01009ce <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006de:	b8 3f ad 11 f0       	mov    $0xf011ad3f,%eax
f01006e3:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ed:	89 c2                	mov    %eax,%edx
f01006ef:	85 c0                	test   %eax,%eax
f01006f1:	79 06                	jns    f01006f9 <mon_kerninfo+0xb1>
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	c1 fa 0a             	sar    $0xa,%edx
f01006fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100700:	c7 04 24 d8 1c 10 f0 	movl   $0xf0101cd8,(%esp)
f0100707:	e8 c2 02 00 00       	call   f01009ce <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	53                   	push   %ebx
f0100717:	83 ec 14             	sub    $0x14,%esp
f010071a:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010071f:	8b 83 c4 1d 10 f0    	mov    -0xfefe23c(%ebx),%eax
f0100725:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100729:	8b 83 c0 1d 10 f0    	mov    -0xfefe240(%ebx),%eax
f010072f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100733:	c7 04 24 49 1b 10 f0 	movl   $0xf0101b49,(%esp)
f010073a:	e8 8f 02 00 00       	call   f01009ce <cprintf>
f010073f:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100742:	83 fb 24             	cmp    $0x24,%ebx
f0100745:	75 d8                	jne    f010071f <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100747:	b8 00 00 00 00       	mov    $0x0,%eax
f010074c:	83 c4 14             	add    $0x14,%esp
f010074f:	5b                   	pop    %ebx
f0100750:	5d                   	pop    %ebp
f0100751:	c3                   	ret    

f0100752 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100752:	55                   	push   %ebp
f0100753:	89 e5                	mov    %esp,%ebp
f0100755:	57                   	push   %edi
f0100756:	56                   	push   %esi
f0100757:	53                   	push   %ebx
f0100758:	83 ec 4c             	sub    $0x4c,%esp
        ebp = (uint32_t *)*ebp;
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
f010075b:	89 eb                	mov    %ebp,%ebx
    while(ebp){
        eip = ebp[1];
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", *ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
        if (debuginfo_eip(eip, &info) == 0){
f010075d:	8d 7d d0             	lea    -0x30(%ebp),%edi
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
    while(ebp){
f0100760:	eb 7d                	jmp    f01007df <mon_backtrace+0x8d>
        eip = ebp[1];
f0100762:	8b 73 04             	mov    0x4(%ebx),%esi
        cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", *ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f0100765:	8b 43 18             	mov    0x18(%ebx),%eax
f0100768:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010076c:	8b 43 14             	mov    0x14(%ebx),%eax
f010076f:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100773:	8b 43 10             	mov    0x10(%ebx),%eax
f0100776:	89 44 24 14          	mov    %eax,0x14(%esp)
f010077a:	8b 43 0c             	mov    0xc(%ebx),%eax
f010077d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100781:	8b 43 08             	mov    0x8(%ebx),%eax
f0100784:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100788:	89 74 24 08          	mov    %esi,0x8(%esp)
f010078c:	8b 03                	mov    (%ebx),%eax
f010078e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100792:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f0100799:	e8 30 02 00 00       	call   f01009ce <cprintf>
        if (debuginfo_eip(eip, &info) == 0){
f010079e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007a2:	89 34 24             	mov    %esi,(%esp)
f01007a5:	e8 1e 03 00 00       	call   f0100ac8 <debuginfo_eip>
f01007aa:	85 c0                	test   %eax,%eax
f01007ac:	75 2f                	jne    f01007dd <mon_backtrace+0x8b>
            int fn_offset = eip - info.eip_fn_addr;
f01007ae:	2b 75 e0             	sub    -0x20(%ebp),%esi
            cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);
f01007b1:	89 74 24 14          	mov    %esi,0x14(%esp)
f01007b5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007b8:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007bc:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d1:	c7 04 24 52 1b 10 f0 	movl   $0xf0101b52,(%esp)
f01007d8:	e8 f1 01 00 00       	call   f01009ce <cprintf>
        }
        ebp = (uint32_t *)*ebp;
f01007dd:	8b 1b                	mov    (%ebx),%ebx
    }
    */
    uint32_t *ebp, eip, *p;
    struct Eipdebuginfo info;
    ebp = (uint32_t *)read_ebp();
    while(ebp){
f01007df:	85 db                	test   %ebx,%ebx
f01007e1:	0f 85 7b ff ff ff    	jne    f0100762 <mon_backtrace+0x10>
            cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);
        }
        ebp = (uint32_t *)*ebp;
    }
	return 0;
}
f01007e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ec:	83 c4 4c             	add    $0x4c,%esp
f01007ef:	5b                   	pop    %ebx
f01007f0:	5e                   	pop    %esi
f01007f1:	5f                   	pop    %edi
f01007f2:	5d                   	pop    %ebp
f01007f3:	c3                   	ret    

f01007f4 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f4:	55                   	push   %ebp
f01007f5:	89 e5                	mov    %esp,%ebp
f01007f7:	57                   	push   %edi
f01007f8:	56                   	push   %esi
f01007f9:	53                   	push   %ebx
f01007fa:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fd:	c7 04 24 34 1d 10 f0 	movl   $0xf0101d34,(%esp)
f0100804:	e8 c5 01 00 00       	call   f01009ce <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100809:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f0100810:	e8 b9 01 00 00       	call   f01009ce <cprintf>
    
    int x = 1, y = 3, z = 4;
    cprintf("x %d, y %x, z %d\n", x, y, z);
f0100815:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010081c:	00 
f010081d:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f0100824:	00 
f0100825:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010082c:	00 
f010082d:	c7 04 24 63 1b 10 f0 	movl   $0xf0101b63,(%esp)
f0100834:	e8 95 01 00 00       	call   f01009ce <cprintf>

    unsigned int i = 0x00646c72;
f0100839:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
    cprintf("H%x Wo%s\n", 57616, &i);
f0100840:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100843:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100847:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f010084e:	00 
f010084f:	c7 04 24 75 1b 10 f0 	movl   $0xf0101b75,(%esp)
f0100856:	e8 73 01 00 00       	call   f01009ce <cprintf>

    cprintf("x=%d y=%d\n", 3);
f010085b:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0100862:	00 
f0100863:	c7 04 24 7f 1b 10 f0 	movl   $0xf0101b7f,(%esp)
f010086a:	e8 5f 01 00 00       	call   f01009ce <cprintf>
    int j = 0xf0116fbc;
    cprintf("0xf0116fbc:%d\n", j);
f010086f:	c7 44 24 04 bc 6f 11 	movl   $0xf0116fbc,0x4(%esp)
f0100876:	f0 
f0100877:	c7 04 24 8a 1b 10 f0 	movl   $0xf0101b8a,(%esp)
f010087e:	e8 4b 01 00 00       	call   f01009ce <cprintf>
	while (1) {
		buf = readline("K> ");
f0100883:	c7 04 24 99 1b 10 f0 	movl   $0xf0101b99,(%esp)
f010088a:	e8 61 09 00 00       	call   f01011f0 <readline>
f010088f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100891:	85 c0                	test   %eax,%eax
f0100893:	74 ee                	je     f0100883 <monitor+0x8f>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100895:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010089c:	be 00 00 00 00       	mov    $0x0,%esi
f01008a1:	eb 04                	jmp    f01008a7 <monitor+0xb3>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008a3:	c6 03 00             	movb   $0x0,(%ebx)
f01008a6:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008a7:	8a 03                	mov    (%ebx),%al
f01008a9:	84 c0                	test   %al,%al
f01008ab:	74 5e                	je     f010090b <monitor+0x117>
f01008ad:	0f be c0             	movsbl %al,%eax
f01008b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b4:	c7 04 24 9d 1b 10 f0 	movl   $0xf0101b9d,(%esp)
f01008bb:	e8 25 0b 00 00       	call   f01013e5 <strchr>
f01008c0:	85 c0                	test   %eax,%eax
f01008c2:	75 df                	jne    f01008a3 <monitor+0xaf>
			*buf++ = 0;
		if (*buf == 0)
f01008c4:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008c7:	74 42                	je     f010090b <monitor+0x117>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008c9:	83 fe 0f             	cmp    $0xf,%esi
f01008cc:	75 16                	jne    f01008e4 <monitor+0xf0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ce:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008d5:	00 
f01008d6:	c7 04 24 a2 1b 10 f0 	movl   $0xf0101ba2,(%esp)
f01008dd:	e8 ec 00 00 00       	call   f01009ce <cprintf>
f01008e2:	eb 9f                	jmp    f0100883 <monitor+0x8f>
			return 0;
		}
		argv[argc++] = buf;
f01008e4:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f01008e8:	46                   	inc    %esi
f01008e9:	eb 01                	jmp    f01008ec <monitor+0xf8>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008eb:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ec:	8a 03                	mov    (%ebx),%al
f01008ee:	84 c0                	test   %al,%al
f01008f0:	74 b5                	je     f01008a7 <monitor+0xb3>
f01008f2:	0f be c0             	movsbl %al,%eax
f01008f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f9:	c7 04 24 9d 1b 10 f0 	movl   $0xf0101b9d,(%esp)
f0100900:	e8 e0 0a 00 00       	call   f01013e5 <strchr>
f0100905:	85 c0                	test   %eax,%eax
f0100907:	74 e2                	je     f01008eb <monitor+0xf7>
f0100909:	eb 9c                	jmp    f01008a7 <monitor+0xb3>
			buf++;
	}
	argv[argc] = 0;
f010090b:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100912:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100913:	85 f6                	test   %esi,%esi
f0100915:	0f 84 68 ff ff ff    	je     f0100883 <monitor+0x8f>
f010091b:	bb c0 1d 10 f0       	mov    $0xf0101dc0,%ebx
f0100920:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100925:	8b 03                	mov    (%ebx),%eax
f0100927:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092b:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 5c 0a 00 00       	call   f0101392 <strcmp>
f0100936:	85 c0                	test   %eax,%eax
f0100938:	75 24                	jne    f010095e <monitor+0x16a>
			return commands[i].func(argc, argv, tf);
f010093a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010093d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100940:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100944:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f0100947:	89 54 24 04          	mov    %edx,0x4(%esp)
f010094b:	89 34 24             	mov    %esi,(%esp)
f010094e:	ff 14 85 c8 1d 10 f0 	call   *-0xfefe238(,%eax,4)
    int j = 0xf0116fbc;
    cprintf("0xf0116fbc:%d\n", j);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100955:	85 c0                	test   %eax,%eax
f0100957:	78 26                	js     f010097f <monitor+0x18b>
f0100959:	e9 25 ff ff ff       	jmp    f0100883 <monitor+0x8f>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010095e:	47                   	inc    %edi
f010095f:	83 c3 0c             	add    $0xc,%ebx
f0100962:	83 ff 03             	cmp    $0x3,%edi
f0100965:	75 be                	jne    f0100925 <monitor+0x131>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100967:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010096a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096e:	c7 04 24 bf 1b 10 f0 	movl   $0xf0101bbf,(%esp)
f0100975:	e8 54 00 00 00       	call   f01009ce <cprintf>
f010097a:	e9 04 ff ff ff       	jmp    f0100883 <monitor+0x8f>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010097f:	83 c4 6c             	add    $0x6c,%esp
f0100982:	5b                   	pop    %ebx
f0100983:	5e                   	pop    %esi
f0100984:	5f                   	pop    %edi
f0100985:	5d                   	pop    %ebp
f0100986:	c3                   	ret    
	...

f0100988 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100988:	55                   	push   %ebp
f0100989:	89 e5                	mov    %esp,%ebp
f010098b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010098e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100991:	89 04 24             	mov    %eax,(%esp)
f0100994:	e8 83 fc ff ff       	call   f010061c <cputchar>
	*cnt++;
}
f0100999:	c9                   	leave  
f010099a:	c3                   	ret    

f010099b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010099b:	55                   	push   %ebp
f010099c:	89 e5                	mov    %esp,%ebp
f010099e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009af:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009bd:	c7 04 24 88 09 10 f0 	movl   $0xf0100988,(%esp)
f01009c4:	e8 11 04 00 00       	call   f0100dda <vprintfmt>
	return cnt;
}
f01009c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009cc:	c9                   	leave  
f01009cd:	c3                   	ret    

f01009ce <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ce:	55                   	push   %ebp
f01009cf:	89 e5                	mov    %esp,%ebp
f01009d1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009d4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009db:	8b 45 08             	mov    0x8(%ebp),%eax
f01009de:	89 04 24             	mov    %eax,(%esp)
f01009e1:	e8 b5 ff ff ff       	call   f010099b <vcprintf>
	va_end(ap);

	return cnt;
}
f01009e6:	c9                   	leave  
f01009e7:	c3                   	ret    

f01009e8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	57                   	push   %edi
f01009ec:	56                   	push   %esi
f01009ed:	53                   	push   %ebx
f01009ee:	83 ec 10             	sub    $0x10,%esp
f01009f1:	89 c3                	mov    %eax,%ebx
f01009f3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009f6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009f9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009fc:	8b 0a                	mov    (%edx),%ecx
f01009fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a01:	8b 00                	mov    (%eax),%eax
f0100a03:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a06:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a0d:	eb 77                	jmp    f0100a86 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a12:	01 c8                	add    %ecx,%eax
f0100a14:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a19:	99                   	cltd   
f0100a1a:	f7 ff                	idiv   %edi
f0100a1c:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a1e:	eb 01                	jmp    f0100a21 <stab_binsearch+0x39>
			m--;
f0100a20:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a21:	39 ca                	cmp    %ecx,%edx
f0100a23:	7c 1d                	jl     f0100a42 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a25:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a28:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a2d:	39 f7                	cmp    %esi,%edi
f0100a2f:	75 ef                	jne    f0100a20 <stab_binsearch+0x38>
f0100a31:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a34:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100a37:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100a3b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a3e:	73 18                	jae    f0100a58 <stab_binsearch+0x70>
f0100a40:	eb 05                	jmp    f0100a47 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a42:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a45:	eb 3f                	jmp    f0100a86 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a47:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a4a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a4c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a4f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a56:	eb 2e                	jmp    f0100a86 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a58:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a5b:	76 15                	jbe    f0100a72 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a5d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a60:	4f                   	dec    %edi
f0100a61:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a67:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a69:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a70:	eb 14                	jmp    f0100a86 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a72:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a75:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a78:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100a7a:	ff 45 0c             	incl   0xc(%ebp)
f0100a7d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a7f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a86:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100a89:	7e 84                	jle    f0100a0f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a8b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a8f:	75 0d                	jne    f0100a9e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100a91:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a94:	8b 02                	mov    (%edx),%eax
f0100a96:	48                   	dec    %eax
f0100a97:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a9a:	89 01                	mov    %eax,(%ecx)
f0100a9c:	eb 22                	jmp    f0100ac0 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aa1:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aa3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aa6:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa8:	eb 01                	jmp    f0100aab <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aaa:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aab:	39 c1                	cmp    %eax,%ecx
f0100aad:	7d 0c                	jge    f0100abb <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100aaf:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100ab2:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100ab7:	39 f2                	cmp    %esi,%edx
f0100ab9:	75 ef                	jne    f0100aaa <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100abb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100abe:	89 02                	mov    %eax,(%edx)
	}
}
f0100ac0:	83 c4 10             	add    $0x10,%esp
f0100ac3:	5b                   	pop    %ebx
f0100ac4:	5e                   	pop    %esi
f0100ac5:	5f                   	pop    %edi
f0100ac6:	5d                   	pop    %ebp
f0100ac7:	c3                   	ret    

f0100ac8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ac8:	55                   	push   %ebp
f0100ac9:	89 e5                	mov    %esp,%ebp
f0100acb:	57                   	push   %edi
f0100acc:	56                   	push   %esi
f0100acd:	53                   	push   %ebx
f0100ace:	83 ec 2c             	sub    $0x2c,%esp
f0100ad1:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ad4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ad7:	c7 03 e4 1d 10 f0    	movl   $0xf0101de4,(%ebx)
	info->eip_line = 0;
f0100add:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ae4:	c7 43 08 e4 1d 10 f0 	movl   $0xf0101de4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aeb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100af2:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100af5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100afc:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b02:	76 12                	jbe    f0100b16 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b04:	b8 c2 f0 10 f0       	mov    $0xf010f0c2,%eax
f0100b09:	3d ad 65 10 f0       	cmp    $0xf01065ad,%eax
f0100b0e:	0f 86 50 01 00 00    	jbe    f0100c64 <debuginfo_eip+0x19c>
f0100b14:	eb 1c                	jmp    f0100b32 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b16:	c7 44 24 08 ee 1d 10 	movl   $0xf0101dee,0x8(%esp)
f0100b1d:	f0 
f0100b1e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b25:	00 
f0100b26:	c7 04 24 fb 1d 10 f0 	movl   $0xf0101dfb,(%esp)
f0100b2d:	e8 c6 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b37:	80 3d c1 f0 10 f0 00 	cmpb   $0x0,0xf010f0c1
f0100b3e:	0f 85 2c 01 00 00    	jne    f0100c70 <debuginfo_eip+0x1a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b44:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b4b:	b8 ac 65 10 f0       	mov    $0xf01065ac,%eax
f0100b50:	2d 1c 20 10 f0       	sub    $0xf010201c,%eax
f0100b55:	c1 f8 02             	sar    $0x2,%eax
f0100b58:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b5e:	48                   	dec    %eax
f0100b5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b62:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b66:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b6d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b70:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b73:	b8 1c 20 10 f0       	mov    $0xf010201c,%eax
f0100b78:	e8 6b fe ff ff       	call   f01009e8 <stab_binsearch>
	if (lfile == 0)
f0100b7d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100b85:	85 d2                	test   %edx,%edx
f0100b87:	0f 84 e3 00 00 00    	je     f0100c70 <debuginfo_eip+0x1a8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b8d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100b90:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b93:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b96:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b9a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ba1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ba4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ba7:	b8 1c 20 10 f0       	mov    $0xf010201c,%eax
f0100bac:	e8 37 fe ff ff       	call   f01009e8 <stab_binsearch>

	if (lfun <= rfun) {
f0100bb1:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100bb4:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100bb7:	7f 2e                	jg     f0100be7 <debuginfo_eip+0x11f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bb9:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bbc:	8d 90 1c 20 10 f0    	lea    -0xfefdfe4(%eax),%edx
f0100bc2:	8b 80 1c 20 10 f0    	mov    -0xfefdfe4(%eax),%eax
f0100bc8:	b9 c2 f0 10 f0       	mov    $0xf010f0c2,%ecx
f0100bcd:	81 e9 ad 65 10 f0    	sub    $0xf01065ad,%ecx
f0100bd3:	39 c8                	cmp    %ecx,%eax
f0100bd5:	73 08                	jae    f0100bdf <debuginfo_eip+0x117>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bd7:	05 ad 65 10 f0       	add    $0xf01065ad,%eax
f0100bdc:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bdf:	8b 42 08             	mov    0x8(%edx),%eax
f0100be2:	89 43 10             	mov    %eax,0x10(%ebx)
f0100be5:	eb 06                	jmp    f0100bed <debuginfo_eip+0x125>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100be7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bed:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bf4:	00 
f0100bf5:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bf8:	89 04 24             	mov    %eax,(%esp)
f0100bfb:	e8 02 08 00 00       	call   f0101402 <strfind>
f0100c00:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c03:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c06:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100c09:	eb 01                	jmp    f0100c0c <debuginfo_eip+0x144>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c0b:	4f                   	dec    %edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c0c:	39 cf                	cmp    %ecx,%edi
f0100c0e:	7c 24                	jl     f0100c34 <debuginfo_eip+0x16c>
	       && stabs[lline].n_type != N_SOL
f0100c10:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100c13:	8d 14 85 1c 20 10 f0 	lea    -0xfefdfe4(,%eax,4),%edx
f0100c1a:	8a 42 04             	mov    0x4(%edx),%al
f0100c1d:	3c 84                	cmp    $0x84,%al
f0100c1f:	74 57                	je     f0100c78 <debuginfo_eip+0x1b0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c21:	3c 64                	cmp    $0x64,%al
f0100c23:	75 e6                	jne    f0100c0b <debuginfo_eip+0x143>
f0100c25:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c29:	74 e0                	je     f0100c0b <debuginfo_eip+0x143>
f0100c2b:	eb 4b                	jmp    f0100c78 <debuginfo_eip+0x1b0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c2d:	05 ad 65 10 f0       	add    $0xf01065ad,%eax
f0100c32:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c34:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c37:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c3a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c3f:	39 d1                	cmp    %edx,%ecx
f0100c41:	7d 2d                	jge    f0100c70 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
f0100c43:	8d 41 01             	lea    0x1(%ecx),%eax
f0100c46:	eb 04                	jmp    f0100c4c <debuginfo_eip+0x184>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c48:	ff 43 14             	incl   0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c4b:	40                   	inc    %eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c4c:	39 d0                	cmp    %edx,%eax
f0100c4e:	74 1b                	je     f0100c6b <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c50:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100c53:	80 3c 8d 20 20 10 f0 	cmpb   $0xa0,-0xfefdfe0(,%ecx,4)
f0100c5a:	a0 
f0100c5b:	74 eb                	je     f0100c48 <debuginfo_eip+0x180>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c62:	eb 0c                	jmp    f0100c70 <debuginfo_eip+0x1a8>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c69:	eb 05                	jmp    f0100c70 <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c70:	83 c4 2c             	add    $0x2c,%esp
f0100c73:	5b                   	pop    %ebx
f0100c74:	5e                   	pop    %esi
f0100c75:	5f                   	pop    %edi
f0100c76:	5d                   	pop    %ebp
f0100c77:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c78:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c7b:	8b 87 1c 20 10 f0    	mov    -0xfefdfe4(%edi),%eax
f0100c81:	ba c2 f0 10 f0       	mov    $0xf010f0c2,%edx
f0100c86:	81 ea ad 65 10 f0    	sub    $0xf01065ad,%edx
f0100c8c:	39 d0                	cmp    %edx,%eax
f0100c8e:	72 9d                	jb     f0100c2d <debuginfo_eip+0x165>
f0100c90:	eb a2                	jmp    f0100c34 <debuginfo_eip+0x16c>
	...

f0100c94 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c94:	55                   	push   %ebp
f0100c95:	89 e5                	mov    %esp,%ebp
f0100c97:	57                   	push   %edi
f0100c98:	56                   	push   %esi
f0100c99:	53                   	push   %ebx
f0100c9a:	83 ec 3c             	sub    $0x3c,%esp
f0100c9d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ca0:	89 d7                	mov    %edx,%edi
f0100ca2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ca5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ca8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cab:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cae:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100cb1:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cb4:	85 c0                	test   %eax,%eax
f0100cb6:	75 08                	jne    f0100cc0 <printnum+0x2c>
f0100cb8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cbb:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cbe:	77 57                	ja     f0100d17 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cc0:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100cc4:	4b                   	dec    %ebx
f0100cc5:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100cc9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ccc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cd0:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100cd4:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100cd8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cdf:	00 
f0100ce0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ce3:	89 04 24             	mov    %eax,(%esp)
f0100ce6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ce9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ced:	e8 1e 09 00 00       	call   f0101610 <__udivdi3>
f0100cf2:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cf6:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cfa:	89 04 24             	mov    %eax,(%esp)
f0100cfd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d01:	89 fa                	mov    %edi,%edx
f0100d03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d06:	e8 89 ff ff ff       	call   f0100c94 <printnum>
f0100d0b:	eb 0f                	jmp    f0100d1c <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d0d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d11:	89 34 24             	mov    %esi,(%esp)
f0100d14:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d17:	4b                   	dec    %ebx
f0100d18:	85 db                	test   %ebx,%ebx
f0100d1a:	7f f1                	jg     f0100d0d <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d1c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d20:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d24:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d27:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d2b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d32:	00 
f0100d33:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d36:	89 04 24             	mov    %eax,(%esp)
f0100d39:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d40:	e8 eb 09 00 00       	call   f0101730 <__umoddi3>
f0100d45:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d49:	0f be 80 09 1e 10 f0 	movsbl -0xfefe1f7(%eax),%eax
f0100d50:	89 04 24             	mov    %eax,(%esp)
f0100d53:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d56:	83 c4 3c             	add    $0x3c,%esp
f0100d59:	5b                   	pop    %ebx
f0100d5a:	5e                   	pop    %esi
f0100d5b:	5f                   	pop    %edi
f0100d5c:	5d                   	pop    %ebp
f0100d5d:	c3                   	ret    

f0100d5e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d5e:	55                   	push   %ebp
f0100d5f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d61:	83 fa 01             	cmp    $0x1,%edx
f0100d64:	7e 0e                	jle    f0100d74 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d66:	8b 10                	mov    (%eax),%edx
f0100d68:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d6b:	89 08                	mov    %ecx,(%eax)
f0100d6d:	8b 02                	mov    (%edx),%eax
f0100d6f:	8b 52 04             	mov    0x4(%edx),%edx
f0100d72:	eb 22                	jmp    f0100d96 <getuint+0x38>
	else if (lflag)
f0100d74:	85 d2                	test   %edx,%edx
f0100d76:	74 10                	je     f0100d88 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d78:	8b 10                	mov    (%eax),%edx
f0100d7a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d7d:	89 08                	mov    %ecx,(%eax)
f0100d7f:	8b 02                	mov    (%edx),%eax
f0100d81:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d86:	eb 0e                	jmp    f0100d96 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d88:	8b 10                	mov    (%eax),%edx
f0100d8a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8d:	89 08                	mov    %ecx,(%eax)
f0100d8f:	8b 02                	mov    (%edx),%eax
f0100d91:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d96:	5d                   	pop    %ebp
f0100d97:	c3                   	ret    

f0100d98 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d98:	55                   	push   %ebp
f0100d99:	89 e5                	mov    %esp,%ebp
f0100d9b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d9e:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100da1:	8b 10                	mov    (%eax),%edx
f0100da3:	3b 50 04             	cmp    0x4(%eax),%edx
f0100da6:	73 08                	jae    f0100db0 <sprintputch+0x18>
		*b->buf++ = ch;
f0100da8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100dab:	88 0a                	mov    %cl,(%edx)
f0100dad:	42                   	inc    %edx
f0100dae:	89 10                	mov    %edx,(%eax)
}
f0100db0:	5d                   	pop    %ebp
f0100db1:	c3                   	ret    

f0100db2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100db2:	55                   	push   %ebp
f0100db3:	89 e5                	mov    %esp,%ebp
f0100db5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100db8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dbf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dc2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dc9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dcd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dd0:	89 04 24             	mov    %eax,(%esp)
f0100dd3:	e8 02 00 00 00       	call   f0100dda <vprintfmt>
	va_end(ap);
}
f0100dd8:	c9                   	leave  
f0100dd9:	c3                   	ret    

f0100dda <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dda:	55                   	push   %ebp
f0100ddb:	89 e5                	mov    %esp,%ebp
f0100ddd:	57                   	push   %edi
f0100dde:	56                   	push   %esi
f0100ddf:	53                   	push   %ebx
f0100de0:	83 ec 4c             	sub    $0x4c,%esp
f0100de3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100de6:	8b 75 10             	mov    0x10(%ebp),%esi
f0100de9:	eb 12                	jmp    f0100dfd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100deb:	85 c0                	test   %eax,%eax
f0100ded:	0f 84 6b 03 00 00    	je     f010115e <vprintfmt+0x384>
				return;
			putch(ch, putdat);
f0100df3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100df7:	89 04 24             	mov    %eax,(%esp)
f0100dfa:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dfd:	0f b6 06             	movzbl (%esi),%eax
f0100e00:	46                   	inc    %esi
f0100e01:	83 f8 25             	cmp    $0x25,%eax
f0100e04:	75 e5                	jne    f0100deb <vprintfmt+0x11>
f0100e06:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e0a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e11:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100e16:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e22:	eb 26                	jmp    f0100e4a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e24:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e27:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e2b:	eb 1d                	jmp    f0100e4a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e30:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e34:	eb 14                	jmp    f0100e4a <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e36:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100e39:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e40:	eb 08                	jmp    f0100e4a <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e42:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100e45:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4a:	0f b6 06             	movzbl (%esi),%eax
f0100e4d:	8d 56 01             	lea    0x1(%esi),%edx
f0100e50:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e53:	8a 16                	mov    (%esi),%dl
f0100e55:	83 ea 23             	sub    $0x23,%edx
f0100e58:	80 fa 55             	cmp    $0x55,%dl
f0100e5b:	0f 87 e1 02 00 00    	ja     f0101142 <vprintfmt+0x368>
f0100e61:	0f b6 d2             	movzbl %dl,%edx
f0100e64:	ff 24 95 98 1e 10 f0 	jmp    *-0xfefe168(,%edx,4)
f0100e6b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100e6e:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e73:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100e76:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100e7a:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e7d:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100e80:	83 fa 09             	cmp    $0x9,%edx
f0100e83:	77 2a                	ja     f0100eaf <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e85:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e86:	eb eb                	jmp    f0100e73 <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e88:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8b:	8d 50 04             	lea    0x4(%eax),%edx
f0100e8e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e91:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e93:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e96:	eb 17                	jmp    f0100eaf <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f0100e98:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e9c:	78 98                	js     f0100e36 <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100ea1:	eb a7                	jmp    f0100e4a <vprintfmt+0x70>
f0100ea3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ea6:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100ead:	eb 9b                	jmp    f0100e4a <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f0100eaf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100eb3:	79 95                	jns    f0100e4a <vprintfmt+0x70>
f0100eb5:	eb 8b                	jmp    f0100e42 <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eb7:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ebb:	eb 8d                	jmp    f0100e4a <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ebd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec0:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eca:	8b 00                	mov    (%eax),%eax
f0100ecc:	89 04 24             	mov    %eax,(%esp)
f0100ecf:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ed5:	e9 23 ff ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eda:	8b 45 14             	mov    0x14(%ebp),%eax
f0100edd:	8d 50 04             	lea    0x4(%eax),%edx
f0100ee0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee3:	8b 00                	mov    (%eax),%eax
f0100ee5:	85 c0                	test   %eax,%eax
f0100ee7:	79 02                	jns    f0100eeb <vprintfmt+0x111>
f0100ee9:	f7 d8                	neg    %eax
f0100eeb:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eed:	83 f8 06             	cmp    $0x6,%eax
f0100ef0:	7f 0b                	jg     f0100efd <vprintfmt+0x123>
f0100ef2:	8b 04 85 f0 1f 10 f0 	mov    -0xfefe010(,%eax,4),%eax
f0100ef9:	85 c0                	test   %eax,%eax
f0100efb:	75 23                	jne    f0100f20 <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f0100efd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f01:	c7 44 24 08 21 1e 10 	movl   $0xf0101e21,0x8(%esp)
f0100f08:	f0 
f0100f09:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f10:	89 04 24             	mov    %eax,(%esp)
f0100f13:	e8 9a fe ff ff       	call   f0100db2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f18:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f1b:	e9 dd fe ff ff       	jmp    f0100dfd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100f20:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f24:	c7 44 24 08 2a 1e 10 	movl   $0xf0101e2a,0x8(%esp)
f0100f2b:	f0 
f0100f2c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f30:	8b 55 08             	mov    0x8(%ebp),%edx
f0100f33:	89 14 24             	mov    %edx,(%esp)
f0100f36:	e8 77 fe ff ff       	call   f0100db2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f3e:	e9 ba fe ff ff       	jmp    f0100dfd <vprintfmt+0x23>
f0100f43:	89 f9                	mov    %edi,%ecx
f0100f45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f48:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f51:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f54:	8b 30                	mov    (%eax),%esi
f0100f56:	85 f6                	test   %esi,%esi
f0100f58:	75 05                	jne    f0100f5f <vprintfmt+0x185>
				p = "(null)";
f0100f5a:	be 1a 1e 10 f0       	mov    $0xf0101e1a,%esi
			if (width > 0 && padc != '-')
f0100f5f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100f63:	0f 8e 84 00 00 00    	jle    f0100fed <vprintfmt+0x213>
f0100f69:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100f6d:	74 7e                	je     f0100fed <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f6f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f73:	89 34 24             	mov    %esi,(%esp)
f0100f76:	e8 53 03 00 00       	call   f01012ce <strnlen>
f0100f7b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f7e:	29 c2                	sub    %eax,%edx
f0100f80:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f0100f83:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100f87:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0100f8a:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0100f8d:	89 de                	mov    %ebx,%esi
f0100f8f:	89 d3                	mov    %edx,%ebx
f0100f91:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f93:	eb 0b                	jmp    f0100fa0 <vprintfmt+0x1c6>
					putch(padc, putdat);
f0100f95:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f99:	89 3c 24             	mov    %edi,(%esp)
f0100f9c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f9f:	4b                   	dec    %ebx
f0100fa0:	85 db                	test   %ebx,%ebx
f0100fa2:	7f f1                	jg     f0100f95 <vprintfmt+0x1bb>
f0100fa4:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0100fa7:	89 f3                	mov    %esi,%ebx
f0100fa9:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0100fac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100faf:	85 c0                	test   %eax,%eax
f0100fb1:	79 05                	jns    f0100fb8 <vprintfmt+0x1de>
f0100fb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fbb:	29 c2                	sub    %eax,%edx
f0100fbd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fc0:	eb 2b                	jmp    f0100fed <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fc2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fc6:	74 18                	je     f0100fe0 <vprintfmt+0x206>
f0100fc8:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100fcb:	83 fa 5e             	cmp    $0x5e,%edx
f0100fce:	76 10                	jbe    f0100fe0 <vprintfmt+0x206>
					putch('?', putdat);
f0100fd0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fd4:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fdb:	ff 55 08             	call   *0x8(%ebp)
f0100fde:	eb 0a                	jmp    f0100fea <vprintfmt+0x210>
				else
					putch(ch, putdat);
f0100fe0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fe4:	89 04 24             	mov    %eax,(%esp)
f0100fe7:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fea:	ff 4d e4             	decl   -0x1c(%ebp)
f0100fed:	0f be 06             	movsbl (%esi),%eax
f0100ff0:	46                   	inc    %esi
f0100ff1:	85 c0                	test   %eax,%eax
f0100ff3:	74 21                	je     f0101016 <vprintfmt+0x23c>
f0100ff5:	85 ff                	test   %edi,%edi
f0100ff7:	78 c9                	js     f0100fc2 <vprintfmt+0x1e8>
f0100ff9:	4f                   	dec    %edi
f0100ffa:	79 c6                	jns    f0100fc2 <vprintfmt+0x1e8>
f0100ffc:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fff:	89 de                	mov    %ebx,%esi
f0101001:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101004:	eb 18                	jmp    f010101e <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101006:	89 74 24 04          	mov    %esi,0x4(%esp)
f010100a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101011:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101013:	4b                   	dec    %ebx
f0101014:	eb 08                	jmp    f010101e <vprintfmt+0x244>
f0101016:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101019:	89 de                	mov    %ebx,%esi
f010101b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010101e:	85 db                	test   %ebx,%ebx
f0101020:	7f e4                	jg     f0101006 <vprintfmt+0x22c>
f0101022:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101025:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101027:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010102a:	e9 ce fd ff ff       	jmp    f0100dfd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010102f:	83 f9 01             	cmp    $0x1,%ecx
f0101032:	7e 10                	jle    f0101044 <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f0101034:	8b 45 14             	mov    0x14(%ebp),%eax
f0101037:	8d 50 08             	lea    0x8(%eax),%edx
f010103a:	89 55 14             	mov    %edx,0x14(%ebp)
f010103d:	8b 30                	mov    (%eax),%esi
f010103f:	8b 78 04             	mov    0x4(%eax),%edi
f0101042:	eb 26                	jmp    f010106a <vprintfmt+0x290>
	else if (lflag)
f0101044:	85 c9                	test   %ecx,%ecx
f0101046:	74 12                	je     f010105a <vprintfmt+0x280>
		return va_arg(*ap, long);
f0101048:	8b 45 14             	mov    0x14(%ebp),%eax
f010104b:	8d 50 04             	lea    0x4(%eax),%edx
f010104e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101051:	8b 30                	mov    (%eax),%esi
f0101053:	89 f7                	mov    %esi,%edi
f0101055:	c1 ff 1f             	sar    $0x1f,%edi
f0101058:	eb 10                	jmp    f010106a <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f010105a:	8b 45 14             	mov    0x14(%ebp),%eax
f010105d:	8d 50 04             	lea    0x4(%eax),%edx
f0101060:	89 55 14             	mov    %edx,0x14(%ebp)
f0101063:	8b 30                	mov    (%eax),%esi
f0101065:	89 f7                	mov    %esi,%edi
f0101067:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010106a:	85 ff                	test   %edi,%edi
f010106c:	78 0a                	js     f0101078 <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010106e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101073:	e9 8c 00 00 00       	jmp    f0101104 <vprintfmt+0x32a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0101078:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010107c:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101083:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101086:	f7 de                	neg    %esi
f0101088:	83 d7 00             	adc    $0x0,%edi
f010108b:	f7 df                	neg    %edi
			}
			base = 10;
f010108d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101092:	eb 70                	jmp    f0101104 <vprintfmt+0x32a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101094:	89 ca                	mov    %ecx,%edx
f0101096:	8d 45 14             	lea    0x14(%ebp),%eax
f0101099:	e8 c0 fc ff ff       	call   f0100d5e <getuint>
f010109e:	89 c6                	mov    %eax,%esi
f01010a0:	89 d7                	mov    %edx,%edi
			base = 10;
f01010a2:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01010a7:	eb 5b                	jmp    f0101104 <vprintfmt+0x32a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap,lflag);
f01010a9:	89 ca                	mov    %ecx,%edx
f01010ab:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ae:	e8 ab fc ff ff       	call   f0100d5e <getuint>
f01010b3:	89 c6                	mov    %eax,%esi
f01010b5:	89 d7                	mov    %edx,%edi
            base = 8;
f01010b7:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f01010bc:	eb 46                	jmp    f0101104 <vprintfmt+0x32a>
//			putch('X', putdat);
//			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010c9:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01010cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010d0:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010d7:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010da:	8b 45 14             	mov    0x14(%ebp),%eax
f01010dd:	8d 50 04             	lea    0x4(%eax),%edx
f01010e0:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010e3:	8b 30                	mov    (%eax),%esi
f01010e5:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010ea:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01010ef:	eb 13                	jmp    f0101104 <vprintfmt+0x32a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010f1:	89 ca                	mov    %ecx,%edx
f01010f3:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f6:	e8 63 fc ff ff       	call   f0100d5e <getuint>
f01010fb:	89 c6                	mov    %eax,%esi
f01010fd:	89 d7                	mov    %edx,%edi
			base = 16;
f01010ff:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101104:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0101108:	89 54 24 10          	mov    %edx,0x10(%esp)
f010110c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010110f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101113:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101117:	89 34 24             	mov    %esi,(%esp)
f010111a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010111e:	89 da                	mov    %ebx,%edx
f0101120:	8b 45 08             	mov    0x8(%ebp),%eax
f0101123:	e8 6c fb ff ff       	call   f0100c94 <printnum>
			break;
f0101128:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010112b:	e9 cd fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101130:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101134:	89 04 24             	mov    %eax,(%esp)
f0101137:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010113a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010113d:	e9 bb fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101142:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101146:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010114d:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101150:	eb 01                	jmp    f0101153 <vprintfmt+0x379>
f0101152:	4e                   	dec    %esi
f0101153:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101157:	75 f9                	jne    f0101152 <vprintfmt+0x378>
f0101159:	e9 9f fc ff ff       	jmp    f0100dfd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010115e:	83 c4 4c             	add    $0x4c,%esp
f0101161:	5b                   	pop    %ebx
f0101162:	5e                   	pop    %esi
f0101163:	5f                   	pop    %edi
f0101164:	5d                   	pop    %ebp
f0101165:	c3                   	ret    

f0101166 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101166:	55                   	push   %ebp
f0101167:	89 e5                	mov    %esp,%ebp
f0101169:	83 ec 28             	sub    $0x28,%esp
f010116c:	8b 45 08             	mov    0x8(%ebp),%eax
f010116f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101172:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101175:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101179:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010117c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101183:	85 c0                	test   %eax,%eax
f0101185:	74 30                	je     f01011b7 <vsnprintf+0x51>
f0101187:	85 d2                	test   %edx,%edx
f0101189:	7e 33                	jle    f01011be <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010118b:	8b 45 14             	mov    0x14(%ebp),%eax
f010118e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101192:	8b 45 10             	mov    0x10(%ebp),%eax
f0101195:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101199:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010119c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011a0:	c7 04 24 98 0d 10 f0 	movl   $0xf0100d98,(%esp)
f01011a7:	e8 2e fc ff ff       	call   f0100dda <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011af:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b5:	eb 0c                	jmp    f01011c3 <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011b7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01011bc:	eb 05                	jmp    f01011c3 <vsnprintf+0x5d>
f01011be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011c3:	c9                   	leave  
f01011c4:	c3                   	ret    

f01011c5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011c5:	55                   	push   %ebp
f01011c6:	89 e5                	mov    %esp,%ebp
f01011c8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011cb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011ce:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01011d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e3:	89 04 24             	mov    %eax,(%esp)
f01011e6:	e8 7b ff ff ff       	call   f0101166 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011eb:	c9                   	leave  
f01011ec:	c3                   	ret    
f01011ed:	00 00                	add    %al,(%eax)
	...

f01011f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011f0:	55                   	push   %ebp
f01011f1:	89 e5                	mov    %esp,%ebp
f01011f3:	57                   	push   %edi
f01011f4:	56                   	push   %esi
f01011f5:	53                   	push   %ebx
f01011f6:	83 ec 1c             	sub    $0x1c,%esp
f01011f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011fc:	85 c0                	test   %eax,%eax
f01011fe:	74 10                	je     f0101210 <readline+0x20>
		cprintf("%s", prompt);
f0101200:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101204:	c7 04 24 2a 1e 10 f0 	movl   $0xf0101e2a,(%esp)
f010120b:	e8 be f7 ff ff       	call   f01009ce <cprintf>

	i = 0;
	echoing = iscons(0);
f0101210:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101217:	e8 21 f4 ff ff       	call   f010063d <iscons>
f010121c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010121e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101223:	e8 04 f4 ff ff       	call   f010062c <getchar>
f0101228:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010122a:	85 c0                	test   %eax,%eax
f010122c:	79 17                	jns    f0101245 <readline+0x55>
			cprintf("read error: %e\n", c);
f010122e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101232:	c7 04 24 0c 20 10 f0 	movl   $0xf010200c,(%esp)
f0101239:	e8 90 f7 ff ff       	call   f01009ce <cprintf>
			return NULL;
f010123e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101243:	eb 69                	jmp    f01012ae <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101245:	83 f8 08             	cmp    $0x8,%eax
f0101248:	74 05                	je     f010124f <readline+0x5f>
f010124a:	83 f8 7f             	cmp    $0x7f,%eax
f010124d:	75 17                	jne    f0101266 <readline+0x76>
f010124f:	85 f6                	test   %esi,%esi
f0101251:	7e 13                	jle    f0101266 <readline+0x76>
			if (echoing)
f0101253:	85 ff                	test   %edi,%edi
f0101255:	74 0c                	je     f0101263 <readline+0x73>
				cputchar('\b');
f0101257:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010125e:	e8 b9 f3 ff ff       	call   f010061c <cputchar>
			i--;
f0101263:	4e                   	dec    %esi
f0101264:	eb bd                	jmp    f0101223 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101266:	83 fb 1f             	cmp    $0x1f,%ebx
f0101269:	7e 1d                	jle    f0101288 <readline+0x98>
f010126b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101271:	7f 15                	jg     f0101288 <readline+0x98>
			if (echoing)
f0101273:	85 ff                	test   %edi,%edi
f0101275:	74 08                	je     f010127f <readline+0x8f>
				cputchar(c);
f0101277:	89 1c 24             	mov    %ebx,(%esp)
f010127a:	e8 9d f3 ff ff       	call   f010061c <cputchar>
			buf[i++] = c;
f010127f:	88 9e 40 a5 11 f0    	mov    %bl,-0xfee5ac0(%esi)
f0101285:	46                   	inc    %esi
f0101286:	eb 9b                	jmp    f0101223 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101288:	83 fb 0a             	cmp    $0xa,%ebx
f010128b:	74 05                	je     f0101292 <readline+0xa2>
f010128d:	83 fb 0d             	cmp    $0xd,%ebx
f0101290:	75 91                	jne    f0101223 <readline+0x33>
			if (echoing)
f0101292:	85 ff                	test   %edi,%edi
f0101294:	74 0c                	je     f01012a2 <readline+0xb2>
				cputchar('\n');
f0101296:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010129d:	e8 7a f3 ff ff       	call   f010061c <cputchar>
			buf[i] = 0;
f01012a2:	c6 86 40 a5 11 f0 00 	movb   $0x0,-0xfee5ac0(%esi)
			return buf;
f01012a9:	b8 40 a5 11 f0       	mov    $0xf011a540,%eax
		}
	}
}
f01012ae:	83 c4 1c             	add    $0x1c,%esp
f01012b1:	5b                   	pop    %ebx
f01012b2:	5e                   	pop    %esi
f01012b3:	5f                   	pop    %edi
f01012b4:	5d                   	pop    %ebp
f01012b5:	c3                   	ret    
	...

f01012b8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012b8:	55                   	push   %ebp
f01012b9:	89 e5                	mov    %esp,%ebp
f01012bb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012be:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c3:	eb 01                	jmp    f01012c6 <strlen+0xe>
		n++;
f01012c5:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012c6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012ca:	75 f9                	jne    f01012c5 <strlen+0xd>
		n++;
	return n;
}
f01012cc:	5d                   	pop    %ebp
f01012cd:	c3                   	ret    

f01012ce <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012ce:	55                   	push   %ebp
f01012cf:	89 e5                	mov    %esp,%ebp
f01012d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01012d4:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01012dc:	eb 01                	jmp    f01012df <strnlen+0x11>
		n++;
f01012de:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012df:	39 d0                	cmp    %edx,%eax
f01012e1:	74 06                	je     f01012e9 <strnlen+0x1b>
f01012e3:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01012e7:	75 f5                	jne    f01012de <strnlen+0x10>
		n++;
	return n;
}
f01012e9:	5d                   	pop    %ebp
f01012ea:	c3                   	ret    

f01012eb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012eb:	55                   	push   %ebp
f01012ec:	89 e5                	mov    %esp,%ebp
f01012ee:	53                   	push   %ebx
f01012ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01012fa:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f01012fd:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101300:	42                   	inc    %edx
f0101301:	84 c9                	test   %cl,%cl
f0101303:	75 f5                	jne    f01012fa <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101305:	5b                   	pop    %ebx
f0101306:	5d                   	pop    %ebp
f0101307:	c3                   	ret    

f0101308 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101308:	55                   	push   %ebp
f0101309:	89 e5                	mov    %esp,%ebp
f010130b:	53                   	push   %ebx
f010130c:	83 ec 08             	sub    $0x8,%esp
f010130f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101312:	89 1c 24             	mov    %ebx,(%esp)
f0101315:	e8 9e ff ff ff       	call   f01012b8 <strlen>
	strcpy(dst + len, src);
f010131a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010131d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101321:	01 d8                	add    %ebx,%eax
f0101323:	89 04 24             	mov    %eax,(%esp)
f0101326:	e8 c0 ff ff ff       	call   f01012eb <strcpy>
	return dst;
}
f010132b:	89 d8                	mov    %ebx,%eax
f010132d:	83 c4 08             	add    $0x8,%esp
f0101330:	5b                   	pop    %ebx
f0101331:	5d                   	pop    %ebp
f0101332:	c3                   	ret    

f0101333 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101333:	55                   	push   %ebp
f0101334:	89 e5                	mov    %esp,%ebp
f0101336:	56                   	push   %esi
f0101337:	53                   	push   %ebx
f0101338:	8b 45 08             	mov    0x8(%ebp),%eax
f010133b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010133e:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101341:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101346:	eb 0c                	jmp    f0101354 <strncpy+0x21>
		*dst++ = *src;
f0101348:	8a 1a                	mov    (%edx),%bl
f010134a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010134d:	80 3a 01             	cmpb   $0x1,(%edx)
f0101350:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101353:	41                   	inc    %ecx
f0101354:	39 f1                	cmp    %esi,%ecx
f0101356:	75 f0                	jne    f0101348 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101358:	5b                   	pop    %ebx
f0101359:	5e                   	pop    %esi
f010135a:	5d                   	pop    %ebp
f010135b:	c3                   	ret    

f010135c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010135c:	55                   	push   %ebp
f010135d:	89 e5                	mov    %esp,%ebp
f010135f:	56                   	push   %esi
f0101360:	53                   	push   %ebx
f0101361:	8b 75 08             	mov    0x8(%ebp),%esi
f0101364:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101367:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010136a:	85 d2                	test   %edx,%edx
f010136c:	75 0a                	jne    f0101378 <strlcpy+0x1c>
f010136e:	89 f0                	mov    %esi,%eax
f0101370:	eb 1a                	jmp    f010138c <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101372:	88 18                	mov    %bl,(%eax)
f0101374:	40                   	inc    %eax
f0101375:	41                   	inc    %ecx
f0101376:	eb 02                	jmp    f010137a <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101378:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f010137a:	4a                   	dec    %edx
f010137b:	74 0a                	je     f0101387 <strlcpy+0x2b>
f010137d:	8a 19                	mov    (%ecx),%bl
f010137f:	84 db                	test   %bl,%bl
f0101381:	75 ef                	jne    f0101372 <strlcpy+0x16>
f0101383:	89 c2                	mov    %eax,%edx
f0101385:	eb 02                	jmp    f0101389 <strlcpy+0x2d>
f0101387:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101389:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f010138c:	29 f0                	sub    %esi,%eax
}
f010138e:	5b                   	pop    %ebx
f010138f:	5e                   	pop    %esi
f0101390:	5d                   	pop    %ebp
f0101391:	c3                   	ret    

f0101392 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101398:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010139b:	eb 02                	jmp    f010139f <strcmp+0xd>
		p++, q++;
f010139d:	41                   	inc    %ecx
f010139e:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010139f:	8a 01                	mov    (%ecx),%al
f01013a1:	84 c0                	test   %al,%al
f01013a3:	74 04                	je     f01013a9 <strcmp+0x17>
f01013a5:	3a 02                	cmp    (%edx),%al
f01013a7:	74 f4                	je     f010139d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013a9:	0f b6 c0             	movzbl %al,%eax
f01013ac:	0f b6 12             	movzbl (%edx),%edx
f01013af:	29 d0                	sub    %edx,%eax
}
f01013b1:	5d                   	pop    %ebp
f01013b2:	c3                   	ret    

f01013b3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013b3:	55                   	push   %ebp
f01013b4:	89 e5                	mov    %esp,%ebp
f01013b6:	53                   	push   %ebx
f01013b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013bd:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f01013c0:	eb 03                	jmp    f01013c5 <strncmp+0x12>
		n--, p++, q++;
f01013c2:	4a                   	dec    %edx
f01013c3:	40                   	inc    %eax
f01013c4:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013c5:	85 d2                	test   %edx,%edx
f01013c7:	74 14                	je     f01013dd <strncmp+0x2a>
f01013c9:	8a 18                	mov    (%eax),%bl
f01013cb:	84 db                	test   %bl,%bl
f01013cd:	74 04                	je     f01013d3 <strncmp+0x20>
f01013cf:	3a 19                	cmp    (%ecx),%bl
f01013d1:	74 ef                	je     f01013c2 <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013d3:	0f b6 00             	movzbl (%eax),%eax
f01013d6:	0f b6 11             	movzbl (%ecx),%edx
f01013d9:	29 d0                	sub    %edx,%eax
f01013db:	eb 05                	jmp    f01013e2 <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013dd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013e2:	5b                   	pop    %ebx
f01013e3:	5d                   	pop    %ebp
f01013e4:	c3                   	ret    

f01013e5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013e5:	55                   	push   %ebp
f01013e6:	89 e5                	mov    %esp,%ebp
f01013e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013eb:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01013ee:	eb 05                	jmp    f01013f5 <strchr+0x10>
		if (*s == c)
f01013f0:	38 ca                	cmp    %cl,%dl
f01013f2:	74 0c                	je     f0101400 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013f4:	40                   	inc    %eax
f01013f5:	8a 10                	mov    (%eax),%dl
f01013f7:	84 d2                	test   %dl,%dl
f01013f9:	75 f5                	jne    f01013f0 <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	8b 45 08             	mov    0x8(%ebp),%eax
f0101408:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010140b:	eb 05                	jmp    f0101412 <strfind+0x10>
		if (*s == c)
f010140d:	38 ca                	cmp    %cl,%dl
f010140f:	74 07                	je     f0101418 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101411:	40                   	inc    %eax
f0101412:	8a 10                	mov    (%eax),%dl
f0101414:	84 d2                	test   %dl,%dl
f0101416:	75 f5                	jne    f010140d <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f0101418:	5d                   	pop    %ebp
f0101419:	c3                   	ret    

f010141a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010141a:	55                   	push   %ebp
f010141b:	89 e5                	mov    %esp,%ebp
f010141d:	57                   	push   %edi
f010141e:	56                   	push   %esi
f010141f:	53                   	push   %ebx
f0101420:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101423:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101426:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101429:	85 c9                	test   %ecx,%ecx
f010142b:	74 30                	je     f010145d <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010142d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101433:	75 25                	jne    f010145a <memset+0x40>
f0101435:	f6 c1 03             	test   $0x3,%cl
f0101438:	75 20                	jne    f010145a <memset+0x40>
		c &= 0xFF;
f010143a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010143d:	89 d3                	mov    %edx,%ebx
f010143f:	c1 e3 08             	shl    $0x8,%ebx
f0101442:	89 d6                	mov    %edx,%esi
f0101444:	c1 e6 18             	shl    $0x18,%esi
f0101447:	89 d0                	mov    %edx,%eax
f0101449:	c1 e0 10             	shl    $0x10,%eax
f010144c:	09 f0                	or     %esi,%eax
f010144e:	09 d0                	or     %edx,%eax
f0101450:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101452:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101455:	fc                   	cld    
f0101456:	f3 ab                	rep stos %eax,%es:(%edi)
f0101458:	eb 03                	jmp    f010145d <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010145a:	fc                   	cld    
f010145b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010145d:	89 f8                	mov    %edi,%eax
f010145f:	5b                   	pop    %ebx
f0101460:	5e                   	pop    %esi
f0101461:	5f                   	pop    %edi
f0101462:	5d                   	pop    %ebp
f0101463:	c3                   	ret    

f0101464 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101464:	55                   	push   %ebp
f0101465:	89 e5                	mov    %esp,%ebp
f0101467:	57                   	push   %edi
f0101468:	56                   	push   %esi
f0101469:	8b 45 08             	mov    0x8(%ebp),%eax
f010146c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010146f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101472:	39 c6                	cmp    %eax,%esi
f0101474:	73 34                	jae    f01014aa <memmove+0x46>
f0101476:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101479:	39 d0                	cmp    %edx,%eax
f010147b:	73 2d                	jae    f01014aa <memmove+0x46>
		s += n;
		d += n;
f010147d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101480:	f6 c2 03             	test   $0x3,%dl
f0101483:	75 1b                	jne    f01014a0 <memmove+0x3c>
f0101485:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010148b:	75 13                	jne    f01014a0 <memmove+0x3c>
f010148d:	f6 c1 03             	test   $0x3,%cl
f0101490:	75 0e                	jne    f01014a0 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101492:	83 ef 04             	sub    $0x4,%edi
f0101495:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101498:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010149b:	fd                   	std    
f010149c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010149e:	eb 07                	jmp    f01014a7 <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01014a0:	4f                   	dec    %edi
f01014a1:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014a4:	fd                   	std    
f01014a5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014a7:	fc                   	cld    
f01014a8:	eb 20                	jmp    f01014ca <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014aa:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014b0:	75 13                	jne    f01014c5 <memmove+0x61>
f01014b2:	a8 03                	test   $0x3,%al
f01014b4:	75 0f                	jne    f01014c5 <memmove+0x61>
f01014b6:	f6 c1 03             	test   $0x3,%cl
f01014b9:	75 0a                	jne    f01014c5 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01014bb:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01014be:	89 c7                	mov    %eax,%edi
f01014c0:	fc                   	cld    
f01014c1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014c3:	eb 05                	jmp    f01014ca <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014c5:	89 c7                	mov    %eax,%edi
f01014c7:	fc                   	cld    
f01014c8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014ca:	5e                   	pop    %esi
f01014cb:	5f                   	pop    %edi
f01014cc:	5d                   	pop    %ebp
f01014cd:	c3                   	ret    

f01014ce <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014ce:	55                   	push   %ebp
f01014cf:	89 e5                	mov    %esp,%ebp
f01014d1:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01014d4:	8b 45 10             	mov    0x10(%ebp),%eax
f01014d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e5:	89 04 24             	mov    %eax,(%esp)
f01014e8:	e8 77 ff ff ff       	call   f0101464 <memmove>
}
f01014ed:	c9                   	leave  
f01014ee:	c3                   	ret    

f01014ef <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014ef:	55                   	push   %ebp
f01014f0:	89 e5                	mov    %esp,%ebp
f01014f2:	57                   	push   %edi
f01014f3:	56                   	push   %esi
f01014f4:	53                   	push   %ebx
f01014f5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014f8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014fe:	ba 00 00 00 00       	mov    $0x0,%edx
f0101503:	eb 16                	jmp    f010151b <memcmp+0x2c>
		if (*s1 != *s2)
f0101505:	8a 04 17             	mov    (%edi,%edx,1),%al
f0101508:	42                   	inc    %edx
f0101509:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f010150d:	38 c8                	cmp    %cl,%al
f010150f:	74 0a                	je     f010151b <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f0101511:	0f b6 c0             	movzbl %al,%eax
f0101514:	0f b6 c9             	movzbl %cl,%ecx
f0101517:	29 c8                	sub    %ecx,%eax
f0101519:	eb 09                	jmp    f0101524 <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010151b:	39 da                	cmp    %ebx,%edx
f010151d:	75 e6                	jne    f0101505 <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010151f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101524:	5b                   	pop    %ebx
f0101525:	5e                   	pop    %esi
f0101526:	5f                   	pop    %edi
f0101527:	5d                   	pop    %ebp
f0101528:	c3                   	ret    

f0101529 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101529:	55                   	push   %ebp
f010152a:	89 e5                	mov    %esp,%ebp
f010152c:	8b 45 08             	mov    0x8(%ebp),%eax
f010152f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101532:	89 c2                	mov    %eax,%edx
f0101534:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101537:	eb 05                	jmp    f010153e <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101539:	38 08                	cmp    %cl,(%eax)
f010153b:	74 05                	je     f0101542 <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010153d:	40                   	inc    %eax
f010153e:	39 d0                	cmp    %edx,%eax
f0101540:	72 f7                	jb     f0101539 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101542:	5d                   	pop    %ebp
f0101543:	c3                   	ret    

f0101544 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101544:	55                   	push   %ebp
f0101545:	89 e5                	mov    %esp,%ebp
f0101547:	57                   	push   %edi
f0101548:	56                   	push   %esi
f0101549:	53                   	push   %ebx
f010154a:	8b 55 08             	mov    0x8(%ebp),%edx
f010154d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101550:	eb 01                	jmp    f0101553 <strtol+0xf>
		s++;
f0101552:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101553:	8a 02                	mov    (%edx),%al
f0101555:	3c 20                	cmp    $0x20,%al
f0101557:	74 f9                	je     f0101552 <strtol+0xe>
f0101559:	3c 09                	cmp    $0x9,%al
f010155b:	74 f5                	je     f0101552 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010155d:	3c 2b                	cmp    $0x2b,%al
f010155f:	75 08                	jne    f0101569 <strtol+0x25>
		s++;
f0101561:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101562:	bf 00 00 00 00       	mov    $0x0,%edi
f0101567:	eb 13                	jmp    f010157c <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101569:	3c 2d                	cmp    $0x2d,%al
f010156b:	75 0a                	jne    f0101577 <strtol+0x33>
		s++, neg = 1;
f010156d:	8d 52 01             	lea    0x1(%edx),%edx
f0101570:	bf 01 00 00 00       	mov    $0x1,%edi
f0101575:	eb 05                	jmp    f010157c <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101577:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010157c:	85 db                	test   %ebx,%ebx
f010157e:	74 05                	je     f0101585 <strtol+0x41>
f0101580:	83 fb 10             	cmp    $0x10,%ebx
f0101583:	75 28                	jne    f01015ad <strtol+0x69>
f0101585:	8a 02                	mov    (%edx),%al
f0101587:	3c 30                	cmp    $0x30,%al
f0101589:	75 10                	jne    f010159b <strtol+0x57>
f010158b:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010158f:	75 0a                	jne    f010159b <strtol+0x57>
		s += 2, base = 16;
f0101591:	83 c2 02             	add    $0x2,%edx
f0101594:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101599:	eb 12                	jmp    f01015ad <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f010159b:	85 db                	test   %ebx,%ebx
f010159d:	75 0e                	jne    f01015ad <strtol+0x69>
f010159f:	3c 30                	cmp    $0x30,%al
f01015a1:	75 05                	jne    f01015a8 <strtol+0x64>
		s++, base = 8;
f01015a3:	42                   	inc    %edx
f01015a4:	b3 08                	mov    $0x8,%bl
f01015a6:	eb 05                	jmp    f01015ad <strtol+0x69>
	else if (base == 0)
		base = 10;
f01015a8:	bb 0a 00 00 00       	mov    $0xa,%ebx
f01015ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b2:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015b4:	8a 0a                	mov    (%edx),%cl
f01015b6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01015b9:	80 fb 09             	cmp    $0x9,%bl
f01015bc:	77 08                	ja     f01015c6 <strtol+0x82>
			dig = *s - '0';
f01015be:	0f be c9             	movsbl %cl,%ecx
f01015c1:	83 e9 30             	sub    $0x30,%ecx
f01015c4:	eb 1e                	jmp    f01015e4 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f01015c6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01015c9:	80 fb 19             	cmp    $0x19,%bl
f01015cc:	77 08                	ja     f01015d6 <strtol+0x92>
			dig = *s - 'a' + 10;
f01015ce:	0f be c9             	movsbl %cl,%ecx
f01015d1:	83 e9 57             	sub    $0x57,%ecx
f01015d4:	eb 0e                	jmp    f01015e4 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f01015d6:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01015d9:	80 fb 19             	cmp    $0x19,%bl
f01015dc:	77 12                	ja     f01015f0 <strtol+0xac>
			dig = *s - 'A' + 10;
f01015de:	0f be c9             	movsbl %cl,%ecx
f01015e1:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01015e4:	39 f1                	cmp    %esi,%ecx
f01015e6:	7d 0c                	jge    f01015f4 <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f01015e8:	42                   	inc    %edx
f01015e9:	0f af c6             	imul   %esi,%eax
f01015ec:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01015ee:	eb c4                	jmp    f01015b4 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01015f0:	89 c1                	mov    %eax,%ecx
f01015f2:	eb 02                	jmp    f01015f6 <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01015f4:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01015f6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015fa:	74 05                	je     f0101601 <strtol+0xbd>
		*endptr = (char *) s;
f01015fc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01015ff:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101601:	85 ff                	test   %edi,%edi
f0101603:	74 04                	je     f0101609 <strtol+0xc5>
f0101605:	89 c8                	mov    %ecx,%eax
f0101607:	f7 d8                	neg    %eax
}
f0101609:	5b                   	pop    %ebx
f010160a:	5e                   	pop    %esi
f010160b:	5f                   	pop    %edi
f010160c:	5d                   	pop    %ebp
f010160d:	c3                   	ret    
	...

f0101610 <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f0101610:	55                   	push   %ebp
f0101611:	57                   	push   %edi
f0101612:	56                   	push   %esi
f0101613:	83 ec 10             	sub    $0x10,%esp
f0101616:	8b 74 24 20          	mov    0x20(%esp),%esi
f010161a:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f010161e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101622:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f0101626:	89 cd                	mov    %ecx,%ebp
f0101628:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f010162c:	85 c0                	test   %eax,%eax
f010162e:	75 2c                	jne    f010165c <__udivdi3+0x4c>
    {
      if (d0 > n1)
f0101630:	39 f9                	cmp    %edi,%ecx
f0101632:	77 68                	ja     f010169c <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101634:	85 c9                	test   %ecx,%ecx
f0101636:	75 0b                	jne    f0101643 <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0101638:	b8 01 00 00 00       	mov    $0x1,%eax
f010163d:	31 d2                	xor    %edx,%edx
f010163f:	f7 f1                	div    %ecx
f0101641:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101643:	31 d2                	xor    %edx,%edx
f0101645:	89 f8                	mov    %edi,%eax
f0101647:	f7 f1                	div    %ecx
f0101649:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010164b:	89 f0                	mov    %esi,%eax
f010164d:	f7 f1                	div    %ecx
f010164f:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101651:	89 f0                	mov    %esi,%eax
f0101653:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101655:	83 c4 10             	add    $0x10,%esp
f0101658:	5e                   	pop    %esi
f0101659:	5f                   	pop    %edi
f010165a:	5d                   	pop    %ebp
f010165b:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f010165c:	39 f8                	cmp    %edi,%eax
f010165e:	77 2c                	ja     f010168c <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0101660:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f0101663:	83 f6 1f             	xor    $0x1f,%esi
f0101666:	75 4c                	jne    f01016b4 <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101668:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f010166a:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010166f:	72 0a                	jb     f010167b <__udivdi3+0x6b>
f0101671:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101675:	0f 87 ad 00 00 00    	ja     f0101728 <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f010167b:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101680:	89 f0                	mov    %esi,%eax
f0101682:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101684:	83 c4 10             	add    $0x10,%esp
f0101687:	5e                   	pop    %esi
f0101688:	5f                   	pop    %edi
f0101689:	5d                   	pop    %ebp
f010168a:	c3                   	ret    
f010168b:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f010168c:	31 ff                	xor    %edi,%edi
f010168e:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0101690:	89 f0                	mov    %esi,%eax
f0101692:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0101694:	83 c4 10             	add    $0x10,%esp
f0101697:	5e                   	pop    %esi
f0101698:	5f                   	pop    %edi
f0101699:	5d                   	pop    %ebp
f010169a:	c3                   	ret    
f010169b:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010169c:	89 fa                	mov    %edi,%edx
f010169e:	89 f0                	mov    %esi,%eax
f01016a0:	f7 f1                	div    %ecx
f01016a2:	89 c6                	mov    %eax,%esi
f01016a4:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01016a6:	89 f0                	mov    %esi,%eax
f01016a8:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01016aa:	83 c4 10             	add    $0x10,%esp
f01016ad:	5e                   	pop    %esi
f01016ae:	5f                   	pop    %edi
f01016af:	5d                   	pop    %ebp
f01016b0:	c3                   	ret    
f01016b1:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f01016b4:	89 f1                	mov    %esi,%ecx
f01016b6:	d3 e0                	shl    %cl,%eax
f01016b8:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f01016bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01016c1:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f01016c3:	89 ea                	mov    %ebp,%edx
f01016c5:	88 c1                	mov    %al,%cl
f01016c7:	d3 ea                	shr    %cl,%edx
f01016c9:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f01016cd:	09 ca                	or     %ecx,%edx
f01016cf:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f01016d3:	89 f1                	mov    %esi,%ecx
f01016d5:	d3 e5                	shl    %cl,%ebp
f01016d7:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f01016db:	89 fd                	mov    %edi,%ebp
f01016dd:	88 c1                	mov    %al,%cl
f01016df:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f01016e1:	89 fa                	mov    %edi,%edx
f01016e3:	89 f1                	mov    %esi,%ecx
f01016e5:	d3 e2                	shl    %cl,%edx
f01016e7:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01016eb:	88 c1                	mov    %al,%cl
f01016ed:	d3 ef                	shr    %cl,%edi
f01016ef:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f01016f1:	89 f8                	mov    %edi,%eax
f01016f3:	89 ea                	mov    %ebp,%edx
f01016f5:	f7 74 24 08          	divl   0x8(%esp)
f01016f9:	89 d1                	mov    %edx,%ecx
f01016fb:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f01016fd:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101701:	39 d1                	cmp    %edx,%ecx
f0101703:	72 17                	jb     f010171c <__udivdi3+0x10c>
f0101705:	74 09                	je     f0101710 <__udivdi3+0x100>
f0101707:	89 fe                	mov    %edi,%esi
f0101709:	31 ff                	xor    %edi,%edi
f010170b:	e9 41 ff ff ff       	jmp    f0101651 <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0101710:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101714:	89 f1                	mov    %esi,%ecx
f0101716:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101718:	39 c2                	cmp    %eax,%edx
f010171a:	73 eb                	jae    f0101707 <__udivdi3+0xf7>
		{
		  q0--;
f010171c:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f010171f:	31 ff                	xor    %edi,%edi
f0101721:	e9 2b ff ff ff       	jmp    f0101651 <__udivdi3+0x41>
f0101726:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0101728:	31 f6                	xor    %esi,%esi
f010172a:	e9 22 ff ff ff       	jmp    f0101651 <__udivdi3+0x41>
	...

f0101730 <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f0101730:	55                   	push   %ebp
f0101731:	57                   	push   %edi
f0101732:	56                   	push   %esi
f0101733:	83 ec 20             	sub    $0x20,%esp
f0101736:	8b 44 24 30          	mov    0x30(%esp),%eax
f010173a:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f010173e:	89 44 24 14          	mov    %eax,0x14(%esp)
f0101742:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f0101746:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010174a:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f010174e:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f0101750:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0101752:	85 ed                	test   %ebp,%ebp
f0101754:	75 16                	jne    f010176c <__umoddi3+0x3c>
    {
      if (d0 > n1)
f0101756:	39 f1                	cmp    %esi,%ecx
f0101758:	0f 86 a6 00 00 00    	jbe    f0101804 <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f010175e:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f0101760:	89 d0                	mov    %edx,%eax
f0101762:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101764:	83 c4 20             	add    $0x20,%esp
f0101767:	5e                   	pop    %esi
f0101768:	5f                   	pop    %edi
f0101769:	5d                   	pop    %ebp
f010176a:	c3                   	ret    
f010176b:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f010176c:	39 f5                	cmp    %esi,%ebp
f010176e:	0f 87 ac 00 00 00    	ja     f0101820 <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0101774:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f0101777:	83 f0 1f             	xor    $0x1f,%eax
f010177a:	89 44 24 10          	mov    %eax,0x10(%esp)
f010177e:	0f 84 a8 00 00 00    	je     f010182c <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0101784:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0101788:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f010178a:	bf 20 00 00 00       	mov    $0x20,%edi
f010178f:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f0101793:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101797:	89 f9                	mov    %edi,%ecx
f0101799:	d3 e8                	shr    %cl,%eax
f010179b:	09 e8                	or     %ebp,%eax
f010179d:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f01017a1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01017a5:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01017a9:	d3 e0                	shl    %cl,%eax
f01017ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01017af:	89 f2                	mov    %esi,%edx
f01017b1:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f01017b3:	8b 44 24 14          	mov    0x14(%esp),%eax
f01017b7:	d3 e0                	shl    %cl,%eax
f01017b9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f01017bd:	8b 44 24 14          	mov    0x14(%esp),%eax
f01017c1:	89 f9                	mov    %edi,%ecx
f01017c3:	d3 e8                	shr    %cl,%eax
f01017c5:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f01017c7:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f01017c9:	89 f2                	mov    %esi,%edx
f01017cb:	f7 74 24 18          	divl   0x18(%esp)
f01017cf:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f01017d1:	f7 64 24 0c          	mull   0xc(%esp)
f01017d5:	89 c5                	mov    %eax,%ebp
f01017d7:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f01017d9:	39 d6                	cmp    %edx,%esi
f01017db:	72 67                	jb     f0101844 <__umoddi3+0x114>
f01017dd:	74 75                	je     f0101854 <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f01017df:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01017e3:	29 e8                	sub    %ebp,%eax
f01017e5:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f01017e7:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01017eb:	d3 e8                	shr    %cl,%eax
f01017ed:	89 f2                	mov    %esi,%edx
f01017ef:	89 f9                	mov    %edi,%ecx
f01017f1:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f01017f3:	09 d0                	or     %edx,%eax
f01017f5:	89 f2                	mov    %esi,%edx
f01017f7:	8a 4c 24 10          	mov    0x10(%esp),%cl
f01017fb:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f01017fd:	83 c4 20             	add    $0x20,%esp
f0101800:	5e                   	pop    %esi
f0101801:	5f                   	pop    %edi
f0101802:	5d                   	pop    %ebp
f0101803:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0101804:	85 c9                	test   %ecx,%ecx
f0101806:	75 0b                	jne    f0101813 <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0101808:	b8 01 00 00 00       	mov    $0x1,%eax
f010180d:	31 d2                	xor    %edx,%edx
f010180f:	f7 f1                	div    %ecx
f0101811:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0101813:	89 f0                	mov    %esi,%eax
f0101815:	31 d2                	xor    %edx,%edx
f0101817:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0101819:	89 f8                	mov    %edi,%eax
f010181b:	e9 3e ff ff ff       	jmp    f010175e <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0101820:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0101822:	83 c4 20             	add    $0x20,%esp
f0101825:	5e                   	pop    %esi
f0101826:	5f                   	pop    %edi
f0101827:	5d                   	pop    %ebp
f0101828:	c3                   	ret    
f0101829:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f010182c:	39 f5                	cmp    %esi,%ebp
f010182e:	72 04                	jb     f0101834 <__umoddi3+0x104>
f0101830:	39 f9                	cmp    %edi,%ecx
f0101832:	77 06                	ja     f010183a <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0101834:	89 f2                	mov    %esi,%edx
f0101836:	29 cf                	sub    %ecx,%edi
f0101838:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f010183a:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f010183c:	83 c4 20             	add    $0x20,%esp
f010183f:	5e                   	pop    %esi
f0101840:	5f                   	pop    %edi
f0101841:	5d                   	pop    %ebp
f0101842:	c3                   	ret    
f0101843:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0101844:	89 d1                	mov    %edx,%ecx
f0101846:	89 c5                	mov    %eax,%ebp
f0101848:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f010184c:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f0101850:	eb 8d                	jmp    f01017df <__umoddi3+0xaf>
f0101852:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0101854:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f0101858:	72 ea                	jb     f0101844 <__umoddi3+0x114>
f010185a:	89 f1                	mov    %esi,%ecx
f010185c:	eb 81                	jmp    f01017df <__umoddi3+0xaf>
