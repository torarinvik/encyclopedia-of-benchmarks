#include <stddef.h>
#include <stdint.h>

int64_t nimply_gate(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return -1;
    const int64_t a = values[0], b = values[1];
    if ((a != 0 && a != 1) || (b != 0 && b != 1)) return -1;
    return a == 1 && b == 0 ? 1 : 0;
}
