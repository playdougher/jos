# Homework:xv6 lazy page allocation

操作系统可以与页表硬件进行的许多技巧之一是堆内存的延迟分配, Xv6的应用程序使用sbrk()系统调用向内核请求堆内存. 在内核中, 提供了一个sbrk()函数来分配物理内存, 以及将其映射到进程的虚拟地址空间. 有许多程序只分配了内存, 但是从来没使用过. 比如实现大型稀疏数组, 复杂的内核会延迟内存页的分配，直到应用程序尝试使用该页

## Part One: Eliminate allocation from sbrk()

第一个任务是删除sbrk(n)系统调用中的页分配语句. 该函数位于`sysproc.c`中的`sys_sbrk()`. sbrk(n)系统调用会为进程增加n字节的内存空间, 然后返回新分配空间的起始地址.  
现在要修改`sys_sbrk()`, 增加进程的空间大小(`myproc()->sz`), 返回原先的大小. 但是我们不马上分配内存, 所以要把`growproc()`注释掉  

```c
int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  // increase size
  myproc()->sz += n;
  //if(growproc(n) < 0)
  //  return -1;
  return addr;
}
```

修改后再运行内核, 会发现提示错误. 因为并没有为程序分配空间.  
下面的输出语句位于`trap.c`文件中, 识别到了该页面错误(trap 14, or T_PGFLT)  
`addr 0x4004`表明在虚拟地址`0x4004`处引起了该页面错误

```c
$ echo "sdaf"                                                     
pid 4 sh: trap 14 err 6 on cpu 0 eip 0x1010 addr 0x4004--kill proc
```

## Part Two: Lazy allocation

修改`trap.c`中的代码, 为出现错误的地方分配页面, 使进程能够正常执行.  
代码应该写在`cprintf("pid %d %s: trap %d err %d on cpu %d ..."`前面.  
> Hint: look at the cprintf arguments to see how to find the virtual address that caused the page fault.  

主要看输出语句中输出`0x4004`地址的变量  

![](img.png)

> Hint: steal code from allocuvm() in vm.c, which is what sbrk() calls (via growproc()).  

借鉴`vm.c`中的`allocuvm()`函数的代码, 就是刚才注释的`growproc()`用到的函数, 仿照着给出现错误的地方分配内存.  

> Hint: use PGROUNDDOWN(va) to round the faulting virtual address down to a page boundary.  
> Hint: break or return in order to avoid the cprintf and the myproc()->killed = 1.  

分配完后记得`break`, 否则会往后执行, 继续输出前面的错误提示.  

> Hint: you'll need to call mappages(). In order to do this you'll need to delete the static in the declaration of mappages() in vm.c, and you'll need to declare mappages() in trap.c. Add this declaration to trap.c before any call to mappages():

因为xv6中的`mappages()`定义为`static`, 只能在它所在的文件用, 我们要用该函数, 要把`static`去掉, 然后在用的地方声明该函数, 就能使用了.  

**vm.c**
![](img2.png)

> Hint: you can check whether a fault is a page fault by checking if tf->trapno is equal to T_PGFLT in trap().  

因为那个错误判断是在`switch` 中的`default`里面, 我们可以给该错误新建一个`case`, 在`T_PGFLT`的时候执行.  

### 具体实现
**trap.c**:  
```c
  //lazy allocation
  //为发生页面错误的地址分配内存
  //注意:得写大括号, 因为新设置了变量
  //rcr2(): 寄存器cr2包含发生页面错误时的虚拟地址.
  case T_PGFLT: //14
  {
      char *mem;
      uint a;

      a = PGROUNDDOWN(rcr2());
      uint newsz = myproc()->sz;
      extern int mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm);
      //判断内存分配是否正常
      uint flag = 0;
      for(; a < newsz; a += PGSIZE){
        mem = kalloc();
        if(mem == 0){
          flag = 1;
          cprintf("kalloc() out of memory\n");
        }
        memset(mem, 0, PGSIZE);
        if(mappages(myproc()->pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
          flag = 1;
          cprintf("mappages() out of memory (2)\n");
          break;
        }
      }
      //分配内存正常, 跳出. 否则进入default
      if(!flag) break;
  }
```
**实验结果:**  
```c
$ ls                      
.              1 1 512    
..             1 1 512    
README         2 2 2170   
cat            2 3 12176  
echo           2 4 11365  
forktest       2 5 7175   
grep           2 6 13692  
init           2 7 11750  
kill           2 8 11317  
ln             2 9 11295  
ls             2 10 13250 
mkdir          2 11 11374 
rm             2 12 11355 
sh             2 13 21174 
stressfs       2 14 11821 
usertests      2 15 49049 
wc             2 16 12690 
zombie         2 17 11103 
console        3 18 0     
$ echo "sdfasdf"          
"sdfasdf"                 
```
