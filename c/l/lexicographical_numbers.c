#include <stddef.h>
#include <stdint.h>

#define MAX_NUMBER INT64_C(4096)
#define STACK_CAPACITY 4112

int64_t lexicographical_numbers(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 0 || values[0] > MAX_NUMBER) return -1;
    int64_t stack[STACK_CAPACITY];
    size_t top = 0;
    stack[top++] = 1;
    int64_t index = 0, checksum = 0;
    while (top > 0) {
        const int64_t number = stack[--top];
        if (number <= values[0]) {
            checksum += (++index) * number;
            if (number % 10 != 9) stack[top++] = number + 1;
            stack[top++] = number * 10;
        }
    }
    return checksum;
}
