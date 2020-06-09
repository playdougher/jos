#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

// Simplifed xv6 shell.

#define MAXARGS 10

// All commands have at least a type. Have looked at the type, the code
// typically casts the *cmd to some specific cmd type.
struct cmd {
  int type;          //  ' ' (exec), | (pipe), '<' or '>' for redirection
};

struct execcmd {
  int type;              // ' '
  char *argv[MAXARGS];   // arguments to the command to be exec-ed
};

struct redircmd {
  int type;          // < or > 
  struct cmd *cmd;   // the command to be run (e.g., an execcmd)
  char *file;        // the input/output file
  int flags;         // flags for open() indicating read or write
  int fd;            // the file descriptor number to use for the file
};

struct pipecmd {
  int type;          // |
  struct cmd *left;  // left side of pipe
  struct cmd *right; // right side of pipe
};

int fork1(void);  // Fork but exits on failure.
struct cmd *parsecmd(char*);

// Execute cmd.  Never returns.
void
runcmd(struct cmd *cmd)
{
  int p[2], r;
  struct execcmd *ecmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
    _exit(0);
  
  switch(cmd->type){
  default:
    fprintf(stderr, "unknown runcmd\n");
    _exit(-1);
/*
    execcmd：执行普通命令
    newpath：设置命令所在目录。ls位于/bin/，sort、uniq、wc位于/usr/bin/，a.out位于./。
*/
  case ' ':
    ecmd = (struct execcmd*)cmd;
    if(ecmd->argv[0] == 0)
      _exit(0);
    //fprintf(stderr, "exec not implemented\n");
    // Your code here ...

    char newpath[MAXARGS]="/bin/"; 
    strcat(newpath, ecmd->argv[0]);
    if(execv(newpath,ecmd->argv) == -1){
        strcpy(newpath,"/usr/bin/");
        strcat(newpath,ecmd->argv[0]);    
        if(execv(newpath,ecmd->argv) == -1){
            strcpy(newpath,"./");
            strcat(newpath,ecmd->argv[0]);
            if(execv(newpath,ecmd->argv) == -1){
                fprintf(stderr, "Command %s can't find.\n",ecmd->argv[0]);
            }
        }
    }
    break;
/*
   redircmd：执行重定向命令。
*/
  case '>':
  case '<':
    rcmd = (struct redircmd*)cmd;
    //fprintf(stderr, "redir not implemented\n");
    // Your code here ...
    close(rcmd->fd); //关闭标准输入：0或输出：1，以便open函数能够读取或写入文件。不关闭的话open读不到文件。

    if(open(rcmd->file, rcmd->flags, S_IRUSR|S_IWUSR) < 0) //user has read and write  permission,如果不设置权限，文件除了root没人能访问。
    {
        fprintf(stderr, "Try to open :%s failed\n", rcmd->file);
        _exit(0);
    }
    runcmd(rcmd->cmd);
    break;

    case '|':
    pcmd = (struct pipecmd*)cmd;
    //fprintf(stderr, "pipe not implemented\n");
    // Your code here ...
    if(pipe(p)<0)
        fprintf(stderr,"create pipe failed");
    if(fork()==0){
        close(1);
        dup(p[1]);
        close(p[0]);
        close(p[1]);
        runcmd(pcmd->left);
    }
    if(fork()==0){
        close(0);
        dup(p[0]);
        close(p[0]);
        close(p[1]);
        runcmd(pcmd->right);
    }    
    close(p[0]);
    close(p[1]);    
    wait(&r);
    wait(&r);
    break;
  }    
  _exit(0);
}

int
getcmd(char *buf, int nbuf)
{
  if (isatty(fileno(stdin)))
    fprintf(stdout, "6.828$ ");
  memset(buf, 0, nbuf);
  if(fgets(buf, nbuf, stdin) == 0)
    return -1; // EOF
  return 0;
}

int
main(void)
{
  static char buf[100];
  int fd, r;

  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){ //cat < xxx.txt
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
      // Clumsy but will have to do for now.
      // Chdir has no effect on the parent if run in the child.
      buf[strlen(buf)-1] = 0;  // chop \n
      if(chdir(buf+3) < 0)
        fprintf(stderr, "cannot cd %s\n", buf+3);
      continue;
    }
    if(fork1() == 0)
      runcmd(parsecmd(buf));
    wait(&r);
  }
  exit(0);
}

int
fork1(void)
{
  int pid;
  
  pid = fork();
  if(pid == -1)
    perror("fork");
  return pid;
}

struct cmd*
execcmd(void)
{
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
  memset(cmd, 0, sizeof(*cmd));
  cmd->type = ' ';
  return (struct cmd*)cmd;
}
/*
    取名subcmd是因为：比如cat < y < z，首先构造"cat < y"，其中cmd->subcmd="cat"。然后继续构造"< z"，其中cmd->subcmd->subcmd="cat < y"
*/
struct cmd*
redircmd(struct cmd *subcmd, char *file, int type) //这里subcmd->type和 type的值一样，是因为struct cmd把另外几种struct execcmd之类的抽象出来，方便函数的编写。

{
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
  memset(cmd, 0, sizeof(*cmd));
  cmd->type = type;
  cmd->cmd = subcmd;
  cmd->file = file;
  cmd->flags = (type == '<') ?  O_RDONLY : O_WRONLY|O_CREAT|O_TRUNC; 
  cmd->fd = (type == '<') ? 0 : 1; //0为标准输入，1为标准输出。
  return (struct cmd*)cmd;
}

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
  memset(cmd, 0, sizeof(*cmd));
  cmd->type = '|';
  cmd->left = left;
  cmd->right = right;
  return (struct cmd*)cmd;
}

// Parsing

char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>";

/*
从parseexec进入：
    in:
        *ps="cat < z", es = ps的结尾, *q = 非0数，  *eq= 非0数。
    out:
        *ps="< z" , es = '\0', *q = "cat < z", *eq = " < z"
从parseredirs进入：
    in: 
        ..., *q = 0, *eq = 0
return:
    'a' or
    '|' '<' '>'
*/
int
gettoken(char **ps, char *es, char **q, char **eq)
{
  char *s;
  int ret;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s)) //strchr作用是返回*s在whitespace里出现的第一个位置
    s++;
  if(q)
    *q = s;
  ret = *s;
  switch(*s){
  case 0: //到达命令结束位置
    break;
  case '|':
  case '<':
    s++;
    break;
  case '>':
    s++;
    break;
  default:
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s)) //out: s = " < z"; 搜索第一个symbol位置，即"<|>"位置
      s++;
    break;
  }
  if(eq)
    *eq = s;
  
  while(s < es && strchr(whitespace, *s)) // out: s = "< z"，去掉了前面的空格。
    s++;
  *ps = s;//*ps删去空格，作为下一次指令分析的开端。*eq保留空格，以便后面取出“cat”指令。
  return ret;
}

//跳过命令前的无用字符，查看第一个有效字符是否为toks中的某个字符。
int
peek(char **ps, char *es, char *toks)
{
  char *s;
  
  s = *ps;
  while(s < es && strchr(whitespace, *s)) //跳过" \t\r\n\v";
    s++;
  *ps = s;
  //这里不能省略*s的判断，因为*s为0时，即命令解析完成时，strchr返回的是toks最后一个'\0'的地址，意思是找到了'<','>'或'|'的地址，而命令已经到底了，并没有找到toks，这就会导致误会。
  return *s && strchr(toks, *s);//若*s为空，命令解析完毕，返回0。若不为空且当前字符为"<" or ">"，返回1。
}

struct cmd *parseline(char**, char*);
struct cmd *parsepipe(char**, char*);
struct cmd *parseexec(char**, char*);

// make a copy of the characters in the input buffer, starting from s through es.
// null-terminate the copy to make it a string.

// 用于获取系统命令"cat"、"ls"或文件名之类
char 
*mkcopy(char *s, char *es)
{
  int n = es - s;
  char *c = malloc(n+1);
  assert(c);
  strncpy(c, s, n);
  c[n] = 0;
  return c;
}

struct cmd*
parsecmd(char *s)
{
  char *es;
  struct cmd *cmd;

  es = s + strlen(s);
  cmd = parseline(&s, es);
  peek(&s, es, "");
  if(s != es){
    fprintf(stderr, "leftovers: %s\n", s);
    exit(-1);
  }
  return cmd;
}

struct cmd*
parseline(char **ps, char *es)
{
  struct cmd *cmd;
  cmd = parsepipe(ps, es);
  return cmd;
}

struct cmd*
parsepipe(char **ps, char *es)
{
  struct cmd *cmd;

  cmd = parseexec(ps, es);
  if(peek(ps, es, "|")){
    gettoken(ps, es, 0, 0);
    cmd = pipecmd(cmd, parsepipe(ps, es));
  }
  return cmd;
}

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
    tok = gettoken(ps, es, 0, 0);
    if(gettoken(ps, es, &q, &eq) != 'a') { //此时*ps="z"，目的是判断'<'后面有没有操作数。函数执行完后*ps=""。
      fprintf(stderr, "missing file for redirection\n");
      exit(-1);
    }
    switch(tok){
    case '<':
      cmd = redircmd(cmd, mkcopy(q, eq), '<'); //mkcopy获取"z"，即被操作的文件名。
      break;
    case '>':
      cmd = redircmd(cmd, mkcopy(q, eq), '>');
      break;
    }
  }
  return cmd;
}

struct cmd*
parseexec(char **ps, char *es)
{
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;
  
  ret = execcmd();
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es); //检查命令里是否有"<"或">"，有则解析为重定向命令。
  while(!peek(ps, es, "|")){ //若下个非" \t\r"等字符不是管道，则继续往后取，取到的字符串就是当前execcmd的参数。
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
      break;
    if(tok != 'a') {
      fprintf(stderr, "syntax error\n");
      exit(-1);
    }
    cmd->argv[argc] = mkcopy(q, eq);
    argc++;
    if(argc >= MAXARGS) {
      fprintf(stderr, "too many args\n");
      exit(-1);
    }
    ret = parseredirs(ret, ps, es); //此时*ps为"< z",继续解析
  }
  cmd->argv[argc] = 0;//参数最后设为0，以标记结束位置。
  return ret;
}
