// This is a tiny wrapper that converts the extra arv[0] argument
// from binfmt-misc with the P flag enabled to QEMU parameters.
// It also prevents LD_* environment variables from being applied
// to QEMU itself.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef TARGET_QEMU
#error "Define TARGET_QEMU to be the path to the qemu-user binary (e.g., -DTARGET_QEMU=\"/full/path/to/qemu-riscv64\")"
#endif

extern char **environ;

void realloc_ptr_array(char ***arr, size_t *alloc, size_t count) {
    if (count > *alloc) {
        *alloc = count;
        *arr = (char**)realloc(*arr, (*alloc + 1) * sizeof(char**));

        if (!*arr) {
            fprintf(stderr, "FATAL: Failed to realloc\n");
            abort();
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "%s: This should be run as the binfmt interpreter with the P flag\n", argv[0]);
        fprintf(stderr, "%s: My preconfigured qemu-user binary: %s\n", argv[0], TARGET_QEMU);
        return 1;
    }

    size_t new_argc = 3;
    size_t new_argv_alloc = argc + 10; // 2 for -0 argv0, rest for potential -E LD_ args
    char **new_argv = (char**)malloc((new_argv_alloc + 1) * sizeof(char**));
    if (!new_argv) {
        fprintf(stderr, "FATAL: Failed to allocate new argv array\n");
        abort();
    }

    new_argv[0] = TARGET_QEMU;
    new_argv[1] = "-0";
    new_argv[2] = argv[2];

    // Pass all LD_ env variables as -E and unset in environ
    size_t new_environc = 0;
    size_t new_environ_alloc = 100;
    char **new_environ = (char**)malloc((new_environ_alloc + 1) * sizeof(char**));
    if (!new_environ) {
        fprintf(stderr, "FATAL: Failed to allocate new environ array\n");
        abort();
    }

    for (char **cur = environ; *cur != NULL; ++cur) {
        if (strncmp("LD_", *cur, 3) == 0) {
            realloc_ptr_array(&new_argv, &new_argv_alloc, new_argc + 2);
            new_argv[new_argc++] = "-E";
            new_argv[new_argc++] = *cur;
        } else {
            realloc_ptr_array(&new_environ, &new_environ_alloc, new_environc + 1);
            new_environ[new_environc++] = *cur;
        }
    }
    new_environ[new_environc] = NULL;

    size_t new_arg_start = new_argc;
    new_argc += argc - 3 + 2; // [ "--", full_binary_path ]

    realloc_ptr_array(&new_argv, &new_argv_alloc, new_argc);

    if (argc > 3) {
        memcpy(&new_argv[new_arg_start + 2], &argv[3], (argc - 3) * sizeof(char**));
    }

    new_argv[new_arg_start] = "--";
    new_argv[new_arg_start + 1] = argv[1];
    new_argv[new_argc] = NULL;

#ifdef DEBUG
    for (size_t i = 0; i < new_argc; ++i) {
        fprintf(stderr, "argv[%zu] = %s\n", i, new_argv[i]);
    }
#endif

    return execve(new_argv[0], new_argv, new_environ);
}

// vim: et:ts=4:sw=4
