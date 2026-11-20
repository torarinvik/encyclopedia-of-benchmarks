#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(64)
#define MAX_VALUE INT64_C(255)
#define ABSENT_CODE INT64_C(64)
#define PACK_BASE INT64_C(65)

int64_t bond_sequential_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 68) return -1;
    const int64_t count_value = input[0];
    const int64_t key_a = input[1];
    const int64_t key_b = input[2];
    if (count_value < 0 || count_value > MAX_N
            || length != (size_t)count_value + 3
            || key_a < 0 || key_a > MAX_VALUE
            || key_b < 0 || key_b > MAX_VALUE || key_a == key_b) return -1;

    const size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[i + 3];
        if (value < 0 || value > MAX_VALUE) return -1;
    }

    int64_t index_a = ABSENT_CODE;
    int64_t index_b = ABSENT_CODE;
    const int64_t composite = key_a | key_b;
    for (size_t i = 0; i < count && (index_a == ABSENT_CODE || index_b == ABSENT_CODE); ++i) {
        const int64_t value = input[i + 3];
        if ((value & composite) != value) continue;
        if (index_a == ABSENT_CODE && value == key_a) index_a = (int64_t)i;
        if (index_b == ABSENT_CODE && value == key_b) index_b = (int64_t)i;
    }
    return index_a * PACK_BASE + index_b;
}
