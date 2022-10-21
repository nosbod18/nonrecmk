#include "liby/liby.h"
#include "libz/libz.h"
#include <stdio.h>

void libySayHello(void) {
    printf("Hello from libb! 1 + 1 = %d\n", libzSum(1, 1));
}