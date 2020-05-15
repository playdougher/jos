
<!-- vim-markdown-toc GFM -->

* [Lab 3: User Environments](#lab-3-user-environments)
	* [Part A: User Environments and Exception Handling](#part-a-user-environments-and-exception-handling)
		* [Environment State](#environment-state)
		* [Allocating the Environments Array](#allocating-the-environments-array)
			* [Exercise 1](#exercise-1)
		* [Creating and Running Environments](#creating-and-running-environments)
			* [Exercise 2.](#exercise-2)
		* [Handling Interrupts and Exceptions](#handling-interrupts-and-exceptions)
			* [Exercise 3.](#exercise-3)
		* [Basics of Protected Control Transfer](#basics-of-protected-control-transfer)
		* [Types of Exceptions and Interrupts](#types-of-exceptions-and-interrupts)

<!-- vim-markdown-toc -->

#Lab 3: User Environments

## Part A: User Environments and Exception Handling

一些全局变量的作用：  
```
struct Env *envs = NULL;		// All environments
struct Env *curenv = NULL;		// The current env
static struct Env *env_free_list;	// Free environment list
NENV： 最多有NENV个环境同时运行
```

### Environment State

inc/env.h中的Env结构体：  
```c
struct Env {
	struct Trapframe env_tf;	// Saved registers
	struct Env *env_link;		// Next free Env
	envid_t env_id;			// Unique environment identifier
	envid_t env_parent_id;		// env_id of this env's parent
	enum EnvType env_type;		// Indicates special system environments
	unsigned env_status;		// Status of the environment
	uint32_t env_runs;		// Number of times environment has run

	// Address space
	pde_t *env_pgdir;		// Kernel virtual address of page dir
};
```

像Unix进程一样，JOS环境将“线程”和“地址空间”的概念结合在一起。**线程**主要由保存的寄存器（env_tf字段）定义，**地址空间**由env_pgdir指向的页目录和页表定义。 要想运行一个环境，两样都要配置好。  
在JOS中，各个环境不像xv6中的进程那样具有自己的内核堆栈。 在内核中，一次只能有一个活动的JOS环境，因此JOS只需要一个内核堆栈。

### Allocating the Environments Array

#### Exercise 1

修改kern/pmap.c中的mem_init()来分配和映射envs数组。分配的页面权限为用户只读(inc/memlayout.h有定义)，这样用户就能读取该数组。

```c
    // LAB 3: Your code here.
    envs =(struct Env *)boot_alloc(NENV*sizeof(struct Env));
    memset(envs, 0, NENV*sizeof(struct Env));
    
    // LAB 3: Your code here.
    boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
```
![](assets/img1.png)

### Creating and Running Environments

#### Exercise 2.

在kern/env.c中, 完成如下函数：
env_init()，env_setup_vm()，region_alloc()，load_icode()，env_create()，env_run()
作用如下： 
env_init()：  
初始化envs数组中的所有Env结构体，并将它们添加到env_free_list中。并且调用env_init_percpu，它用不同的段为特权级别0(内核)和特权级别3(用户)配置分段硬件。  
env_setup_vm()：  
为新环境分配一个页面目录，并初始化新环境地址空间的内核部分。  
region_alloc()：  
为环境分配和映射物理内存。  
load_icode()：  
需要解析一个ELF二进制映像，就像boot loader程序一样，并将其内容加载到新环境的用户地址空间中。  
env_create()：  
使用env_alloc分配一个环境，并调用load_icode将ELF二进制文件加载到其中。  
env_run()：  
在用户模式中运行该环境。

1. env_init(void):

将`envs`数组设为free, env_id置为0, 并插入`env_free_list`.  
确保env_free_list中的顺序和envs数组中的顺序是一样的.  这里我们用头插法
```c
void
env_init(void)
{
    // Set up envs array
    // LAB 3: Your code here.

    for(int i = NENV-1; i >= 0; i--){
        envs[i].env_id = 0;
        envs[i].env_link = env_free_list;
        env_free_list = &envs[i];
    }

    // Per-CPU part of the initialization
    env_init_percpu();
}
```

2. env_setup_vm(struct Env *e)

设置e->env_pgdir, 初始化页目录, 该页目录有两部分组成, `内核部分`和`用户部分`. 内核部分直接复制kern_pgdir, 用户部分设为0. 实现方法和lab2类似, 用到了mem_init和pgdir_walk中的一些代码.

Virtual Memory Map:  
![](img2.png) 

C:\Users\Administrator\Desktop2\1\lab3\env_setup_vm.ngm

```c
    // LAB 3: Your code here.
    // 页面转虚拟地址
    e->env_pgdir = (pde_t *)page2kva(p);
    //increment env_pgdir's pp_ref for env_free to work correctly
    p->pp_ref++;

    // use kern_pgdir as a template
    //memcpy(env_pgdir, kern_pgdir, PGSIZE);

    //map the pgdir entries below UTOP
    for(i = 0; i < PDX(UTOP); i++){
        e->env_pgdir[i] = 0;
    }
    //map entries above UTOP
    for(; i < NENV; i++){
        e->env_pgdir[i] = kern_pgdir[i];
    }

    //UVPT对应的页目录项指向该env_pgdir页目录表
    //Permissions: kernel R, User R
    e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
```

3. region_alloc(struct Env *e, void *va, size_t len)

为环境e在虚拟地址va处分配len字节的物理内存.  页面对`用户`和`内核`是可写的. 若分配失败, 需要写`panic`语句

先分配页面, 然后用page_insert插入到页目录中.
```c
static void
region_alloc(struct Env *e, void *va, size_t len)
{
    // LAB 3: Your code here.
    // (But only if you need it for load_icode.)
    //
    // Hint: It is easier to use region_alloc if the caller can pass
    //   'va' and 'len' values that are not page-aligned.
    //   You should round va down, and round (va + len) up.
    //   (Watch out for corner-cases!)

    void * beg = ROUNDDOWN(va, PGSIZE);
    void * end = ROUNDUP(va+len, PGSIZE);

    struct PageInfo *pp = NULL;
    for(void * i = beg; i < end; i+= PGSIZE){
        pp = page_alloc(ALLOC_ZERO);
        if(pp == NULL){
            panic("region_alloc() failed.");
        }

        int ret = page_insert(e->env_pgdir, pp, i, PTE_W | PTE_U);
        if(ret < 0){
            panic("region_alloc() failed: %e", ret);
        }
    }
}
```

static void
4. load_icode(struct Env *e, uint8_t *binary)

设置用户进程的初始程序二进制、堆栈和处理器标志。
这个函数只在内核初始化期间调用，然后运行第一个用户模式环境。

这个函数将ELF二进制映像中的所有可加载段加载到环境的用户内存中，从ELF程序头中指定的适当虚拟地址开始。同时，它为那些在程序头中被标记为映射，但实际上不存在于ELF文件中的段（即程序的bss部分）置为0。

该函数和boot loader很像， 但是bootloader 是从硬盘中读取代码。可以从boot/main.c中参考代码

最后，这个函数为程序的初始堆栈映射一个页面。

```c
    struct Elf *ELFHDR = (struct Elf *)binary;
    struct Proghdr *ph, *eph;

    // is this a valid ELF?
    if (ELFHDR->e_magic != ELF_MAGIC)
        panic("Not a valid ELF");

    // load each program segment (ignores ph flags)
    ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    eph = ph + ELFHDR->e_phnum;

    // ??5. Use lcr3() to switch to its address space.
    lcr3(PADDR(e->env_pgdir));

    for (; ph < eph; ph++){
        // p_pa is the load address of this segment (as well
        // as the physical address)
        if(ph->p_type == ELF_PROG_LOAD){
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);

            // Any remaining memory bytes should be cleared to zero.
            memset((void *)ph->p_va, 0, ph->p_memsz);
            // The ELF header should have ph->p_filesz <= ph->p_memsz.
            memcpy((void *)ph->p_va, binary+ph->p_offset, ph->p_filesz);
        }
    }

    // call the entry point from the ELF header
    e->env_tf.tf_eip = ELFHDR->e_entry;
    lcr3(PADDR(kern_pgdir));

    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.

    // LAB 3: Your code here.
    region_alloc(e, (void *)USTACKTOP - PGSIZE, PGSIZE);
            // The ELF header should have ph->p_filesz <= ph->p_memsz.
            memcpy(ph->p_va, binary+ph->p_offset, ph->p_filesz);

    // call the entry point from the ELF header
    e->env_tf->tf->eip = ELFHDR->e_entry;
    lcr3(PADDR(kern_pgdir));

    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.

    // LAB 3: Your code here.
    region_alloc(e, USTACKTOP - PGSIZE, PGSIZE);
```

void
5. env_create(uint8_t *binary, enum EnvType type)

用env_alloc分配一个新环境，用load_icode加载命名的elf二进制文件，并设置它的env_type。这个函数只在内核初始化期间调用，然后运行第一个用户模式环境。新环境的父ID被设置为0。

```c
void
env_create(uint8_t *binary, enum EnvType type)
{
    // LAB 3: Your code here.
    struct Env *env = NULL;
    int ret = env_alloc(&env, 0);
    if(ret < 0){
        panic("region_alloc() failed: %e", ret);
    }

    load_icode(env, binary);
    env->env_type = type;
}
```
void
6. env_run(struct Env *e)

上下文环境由curenv切换到`e`。 若这是第一次运行env_run， 当前环境curenv为NULL

```c
void
env_run(struct Env *e)
{
    // Step 1: If this is a context switch (a new environment is running):
    //     1. Set the current environment (if any) back to
    //        ENV_RUNNABLE if it is ENV_RUNNING (think about
    //        what other states it can be in),
    //     2. Set 'curenv' to the new environment,
    //     3. Set its status to ENV_RUNNING,
    //     4. Update its 'env_runs' counter,
    //     5. Use lcr3() to switch to its address space.
    // Step 2: Use env_pop_tf() to restore the environment's
    //     registers and drop into user mode in the
    //     environment.

    // Hint: This function loads the new environment's state from
    //  e->env_tf.  Go back through the code you wrote above
    //  and make sure you have set the relevant parts of
    //  e->env_tf to sensible values.

    // LAB 3: Your code here.
    if(curenv && curenv->env_status == ENV_RUNNING)
        curenv->env_status = ENV_RUNNABLE;
    curenv = e;
    curenv->env_status = ENV_RUNNING;
    curenv->env_runs++;
    lcr3(PADDR(curenv->env_pgdir));

    env_pop_tf(&curenv->env_tf);

    //panic("env_run not yet implemented");
}
```

下面是在调用用户代码之前的代码调用图:  

-   `start`  (`kern/entry.S`)
-   `i386_init`  (`kern/init.c`)
    -   `cons_init`
    -   `mem_init`
    -   `env_init`
    -   `trap_init`  (still incomplete at this point)
    -   `env_create`
    -   `env_run`
        -   `env_pop_tf`

完成之后，在QEMU下运行。正常来说，系统会用户空间并执行hello二进制代码，直到它跑到系统中断`int`。这时会出现问题，因为JOS没有设置硬件来允许从用户空间到内核的转换。当CPU发现它没有建立这个系统调用中断处理,会生成一个异常,发现它无法处理,生成一个`double fault`异常,发现还是无法处理,最后抛出“triple fault”。通常，会看到CPU重置和重新启动。但这里用了6.828补丁的QEMU，只会看到一个寄存器信息和一个“triple fault”消息。

这个问题后面会解决，现在先检查有没有正常进入用户模式  
在env_pop_tf设置断点，这个函数是进入用户模式前执行的最后一个函数。若正常，会像下面这样：  

![](assets/img3.png)  

Now use b *0x... to set a breakpoint at the `int $0x30` in `sys_cputs()` in hello (see obj/user/hello.asm for the user-space address
然后找`obj/user/hello.asm`中的`sys_cputs()`中的`int $0x30` ，设置断点。`continue`到当前行，若不能跑到这里，说明前面的代码有问题，需要改正

![](assets/img4.png)  

### Handling Interrupts and Exceptions

一旦执行到`int $0x30`，需要系统调用，程序就卡住了，因为目前只能进入用户模式，但出不来。现在需要实现一些基本的异常和系统调用句柄，以便让内核从用户模式中接管cpu的控制权。首先要彻底熟悉x86中断和异常机制

#### Exercise 3.

读手册第九章.Exceptions and Interrupts

中断和异常之间的区别是：中断用于处理处理器外部的异步事件，而异常处理处理器本身在执行指令过程中检测到的条件。

### Basics of Protected Control Transfer

exception 和 interrupts都是“受保护的控制权转移”，会让处理器从用户态转到内核态(CPL=0)。
interrupts是由异步事件引起的，比如外部IO活动的消息通知。
exception是由当前代码同步引起的，比如除以0或访问无效内存

处理器的中断异常机制能确保当前运行的代码在出现中断异常的时候，内核能进入指定的控制条件中。在x86中，有两种机制确保控制权的安全转移：  
1. **The Interrupt Descriptor Table** (中断描述符表)。
x86提供了256个不同的中断向量， 也就是0-255的数字，代表不同的异常情况。CPU用这些中断向量作为IDT(Interrupt Descriptor Table)的索引，这个IDT只能内核访问，和GDT很像。找到后，CPU就加载该IDT项：  
* 其中一个值加载到`EIP`寄存器，指向指定用于处理此类异常的内核代码。
* 另一个值加载到`CS`寄存器，在位0-1中包括运行异常处理程序的特权级别。 (在JOS中，所有异常都在内核模式下处理，权限级别为0。)
2. **The Task State Segment.**  (任务状态段)
处理器处理的时候需要保存旧的处理器状态，如`EIP`和`CS`值，以便恢复现场。但是旧处理器状态的这个保存区域必须依次受到保护，以防受到非特权用户模式代码的影响。否则，恶意代码会损害内核。  
因此在处理中断异常的时候，处理器会切换到内核当中的一个栈中，这个栈的结构叫做_task state segment_ (TSS)。处理器会把SS, ESP, EFLAGS, CS, EIP, 和一个error code放进来。 然后从interrupt descriptor中加载CS 和 EIP，最后设置ESP和SS来建立新的栈。  
JOS中只用TSS来实现从用户到内核态的转换。由于JOS中的“内核模式”在x86上的特权级别为0，因此处理器在进入内核模式时使用TSS的ESP0和SS0字段来定义内核堆栈。 其他TSS字段JOS不作使用。

### Types of Exceptions and Interrupts



