#include "y/y.h"
#include "z/z.h"
#include <stdio.h>

void YSayHello(void) {
    printf("Hello from y!\n");
    printf("In y using z... 1 + 1 = %d\n", ZSum(1, 1));
}