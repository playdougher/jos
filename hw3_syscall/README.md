# Homework: xv6 system calls

## Part One: System call tracing

>Q: 修改xv6内核，输出每个系统调用的返回值，若成功，能看到类似的输出：
>...
>fork -> 2
>exec -> 0
>open -> 3
>close -> 0
>$write -> 1
> write -> 1

在syscall.c文件中，
```c
static int (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
...
};
```
该语句表示初始化syscalls为指向函数的指针数组。作用就是传入前面的字符串，返回对应的函数指针。  
因为该结构只返回函数指针而没有函数名，所以要仿照着写一个函数名的对应数组才能输出函数名，再插入一句输出语句就能满足要求：  
```c
static char sysnames[][10] = {
[SYS_fork]    "fork",
[SYS_exit]    "exit",
[SYS_wait]    "wait",
[SYS_pipe]    "pipe",
[SYS_read]    "read",
[SYS_kill]    "kill",
[SYS_exec]    "exec",
[SYS_fstat]   "fstat",
[SYS_chdir]   "chdir",
[SYS_dup]     "dup",
[SYS_getpid]  "getpid",
[SYS_sbrk]    "sbrk",
[SYS_sleep]   "sleep",
[SYS_uptime]  "uptime",
[SYS_open]    "open",
[SYS_write]   "write",
[SYS_mknod]   "mknod",
[SYS_unlink]  "unlink",
[SYS_link]    "link",
[SYS_mkdir]   "mkdir",
[SYS_close]   "close",
};
void
syscall(void)
{
  int num;
  struct proc *curproc = myproc();
  num = curproc->tf->eax; //SYS_fork、SYS_exit之类的函数调用值
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num](); //系统调用的返回值
    cprintf("%s -> %d\n", sysnames[num], curproc->tf->eax);
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
```  
输出如下：num对应的是系统调用的值。

| sys call 	|    	| return value 	| num 	|
|----------	|----	|--------------	|-----	|
| exec     	| -> 	| 0            	| 7   	|
| open     	| -> 	| 0            	| 15  	|
| dup      	| -> 	| 1            	| 10  	|
| dup      	| -> 	| 2            	| 10  	|
| iwrite   	| -> 	| 1            	| i16 	|
| nwrite   	| -> 	| 1            	| n16 	|
| iwrite   	| -> 	| 1            	| i16 	|
| twrite   	| -> 	| 1            	| t16 	|
| :write   	| -> 	| 1            	| :16 	|
| write    	| -> 	| 1            	| 16  	|
| swrite   	| -> 	| 1            	| s16 	|
| twrite   	| -> 	| 1            	| t16 	|
| awrite   	| -> 	| 1            	| a16 	|
| rwrite   	| -> 	| 1            	| r16 	|
| twrite   	| -> 	| 1            	| t16 	|
| iwrite   	| -> 	| 1            	| i16 	|
| nwrite   	| -> 	| 1            	| n16 	|
| gwrite   	| -> 	| 1            	| g16 	|
| write    	| -> 	| 1            	| 16  	|
| swrite   	| -> 	| 1            	| s16 	|
| hwrite   	| -> 	| 1            	| h16 	|
| write    	| -> 	| 1            	| 16  	|
| fork     	| -> 	| 2            	| 1   	|
| exec     	| -> 	| 0            	| 7   	|
| open     	| -> 	| 3            	| 15  	|
| close    	| -> 	| 0            	| 21  	|
| $write   	| -> 	| 1            	| $16 	|
| write    	| -> 	| 1            	| 16  	|  

上面的输出内容表明fork出一个sh程序 (sh会确保只打开两个文件描述符)。

## Part Two: Date system call
该部分让我们自己实现一个系统调用，以熟悉系统调用机制。
实现的大致流程如下:
1. 执行$ grep -n uptime *.[chS]，查看已有系统调用实现所涉及的文件：
	```c
	syscall.c:105:extern int sys_uptime(void);
	syscall.c:121:[SYS_uptime]  sys_uptime,   
	syscall.h:15:#define SYS_uptime 14        
	sysproc.c:83:sys_uptime(void)             
	user.h:25:int uptime(void);               
	usys.S:31:SYSCALL(uptime)                 
	```
2. 按照上面出现的文件一一增添date系统调用的代码。
3. 编写 date.c 文件、把文件名加入到Makefile中以便能在xv6的shell中执行。
4. 注释掉part one代码，否则shell无法运行。

### 实现细节

2.  对照涉及的文件, 实现```date()```的系统调用:  
	*  ```syscall.c:105:extern int sys_uptime(void);```  //添加系统调用的外部声明
	![](image1.png)
	* ```syscall.c:121:[SYS_uptime]  sys_uptime,```  
	![](image2.png)
	* ```syscall.h:15:#define SYS_uptime 14```  //添加系统调用对应的整数
	![](image3.png)
	* ```sysproc.c:83:sys_uptime(void) ```  //系统调用具体实现  
	其中的`int argptr(int n, char **pp, int size)`用于获取第n个字大小的系统调用参数，作为指向大小为`size`字节的内存块的指针。检查指针是否位于进程地址空间中
	![](image4.png)
	* ```user.h:25:int uptime(void);```  //用户态的函数定义
	![](image5.png)
	* ```usys.S:31:SYSCALL(uptime)```  //用户态的函数实现
	![](image6.png)

3. 编写date.c, 文件名加入到Makefile
```c
#include "types.h"
#include "user.h"
#include "date.h"

int
main(int argc, char *argv[])
{
  struct rtcdate r;

  if (date(&r)) {
    printf(2, "date failed\n");
    exit();
  }

  // your code to print the time in any format you like...
  printf(1, "month/day/year time : %d/%d/%d %dh:%dm:%ds\n", r.month, r.day, r.year,r.hour, r.minute, r.second);
  exit();
}
```
4. 注释part one 代码


