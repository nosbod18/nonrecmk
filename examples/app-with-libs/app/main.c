#include "libx/libx.h"
#include "liby/liby.h"
#include <stdio.h>

int main(void) {
    libxSayHello();
    libySayHello();
    printf("Hello from app!\n");
}