> Q1: Why are there missing keys with 2 or more threads, but not with 1 thread? Identify a sequence of events that can lead to keys missing for 2 threads.

因为两个线程的时候，插入哈希表时的cpu轮转导致节点出现偏差。  
HashTable的NBUCKET为5，插入10000个随机数，正常来说该哈希表的每个key都会有对应value。  
当核心数为1时，程序先把所有key、value都放进HashTable，然后读出key value，不会出什么问题。
但当核心数为2时。两个核心各自put一半的keys[], 意外的情况为：当thread 2执行到insert函数，还未执行`e->next = n;`进行链接时，轮转到thread 1，当它执行完insert函数，且正好插入的entry和thread 1在同一个bucket后， thread 2 的entry *n按道理应该为thread 1刚插入的entry，但是它保存的是旧值，所以thread 1的entry就没链接上了。
要想避免错误，就让插入函数不能被中断。

![](img.png)


> Q2: Test your code first with 1 thread, then test it with 2 threads. Is it correct (i.e. have you eliminated missing keys?)? Is the two-threaded version faster than the single-threaded version?

put和get都上锁：  
![](assets/two_lock.png)  
能看到两个线程的速度明显低于一个线程，说明有临界区时，多线程效率不一定高。  

只有put上锁：
![](assets/one_lock.png)


## 问题
问题pthread_join的作用是不是等待线程执行完？
为什么key要为线程数的整数倍
