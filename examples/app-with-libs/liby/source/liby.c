#include "liby/liby.h"
#include "libz/libz.h"
#include <stdio.h>

void libySayHello(void) {
    printf("Hello from liby!\n");
    printf("In liby using libz... 1 + 1 = %d\n", libzSum(1, 1));
}