#include <sys/types.h>
#include <string.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
int
main(int argc,char *argv[]){
    int pipefd[2];
    pid_t cpid;
    char buf;

    if (argc != 2){
        fprintf(stderr,"Usage: %s <string>\n",argv[0]);
        exit(EXIT_FAILURE);
    }
    
    if (pipe(pipefd) == -1){
        perror("pipe error");
        exit(EXIT_FAILURE);
    }

    cpid = fork();
    if (cpid==-1){
        perror("fork error");
        exit(EXIT_FAILURE);
    }

    if (cpid==0){ //child
        close(pipefd[1]);

        while (read(pipefd[0], &buf, 1)){
            write(STDOUT_FILENO, &buf, 1);
        }

        write(STDOUT_FILENO, "\n", 1);
        close(pipefd[0]);
        _exit(EXIT_SUCCESS);//use _exit() in child

    } else{ //parent
        close(pipefd[0]);
        write(pipefd[1], argv[1], strlen(argv[1]));
        close(pipefd[1]);
        wait(NULL);
        exit(EXIT_SUCCESS);
    }
}
