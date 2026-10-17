#include <stddef.h>
#include <stdint.h>

int64_t multiplexer(const int64_t *values, size_t length) {
    if (values == NULL || length != 3) return -1;
    const int64_t input0 = values[0];
    const int64_t input1 = values[1];
    const int64_t select = values[2];
    if ((input0 != 0 && input0 != 1) ||
        (input1 != 0 && input1 != 1) ||
        (select != 0 && select != 1)) return -1;
    return select == 1 ? input1 : input0;
}
