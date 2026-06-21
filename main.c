#include <stdio.h>

extern void process_args(int argc, char *argv[]);

int main(int argc, char *argv[]){
    if (argv == NULL) {
        fprintf(stderr, "argv invalido (NULL), abortando\n");
        return 1;
    }
    if (argc < 0) {
        fprintf(stderr, "argc invalido (%d), abortando\n", argc);
        return 1;
    }

    process_args(argc, argv);

    return 0;
}