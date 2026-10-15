#include <stdint.h>

int64_t fermat_numbers_sequence(int64_t index) {
    if (index < 0 || index > 5) return -1;
    int64_t value = 2;
    for (int64_t i = 0; i < index; ++i) value *= value;
    return value + 1;
}
