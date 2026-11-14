#include <stddef.h>
#include <stdint.h>

int64_t walker_vose_alias_sampling(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 83) return -1;
    int64_t n_raw = input[0], q_raw = input[1];
    if (n_raw < 1 || n_raw > 16 || q_raw < 0 || q_raw > 32) return -1;
    size_t n = (size_t)n_raw, q = (size_t)q_raw;
    if (length != 2 + n + 2 * q) return -1;
    int64_t mass[16], threshold[16], total = 0;
    size_t alias[16], small[16], large[16], ns = 0, nl = 0;
    for (size_t i = 0; i < n; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 100) return -1;
        total += input[2 + i];
    }
    if (total == 0) return -1;
    for (size_t i = 0; i < q; ++i) {
        int64_t column = input[2 + n + 2 * i];
        int64_t ticket = input[3 + n + 2 * i];
        if (column < 0 || column >= n_raw || ticket < 0 || ticket >= total) return -1;
    }
    if (q == 0) return 0;
    if (output == NULL || capacity < 8 * q) return -2;
    for (size_t i = 0; i < n; ++i) {
        mass[i] = n_raw * input[2 + i];
        threshold[i] = total;
        alias[i] = i;
        if (mass[i] < total) small[ns++] = i;
        else large[nl++] = i;
    }
    while (ns && nl) {
        size_t low = small[--ns], high = large[--nl];
        threshold[low] = mass[low];
        alias[low] = high;
        mass[high] -= total - mass[low];
        if (mass[high] < total) small[ns++] = high;
        else large[nl++] = high;
    }
    uint8_t staged[256];
    for (size_t i = 0; i < q; ++i) {
        size_t column = (size_t)input[2 + n + 2 * i];
        int64_t ticket = input[3 + n + 2 * i];
        uint64_t result = (uint64_t)(ticket < threshold[column] ? column : alias[column]);
        for (size_t byte = 0; byte < 8; ++byte)
            staged[8 * i + byte] = (uint8_t)(result >> (8 * byte));
    }
    for (size_t i = 0; i < 8 * q; ++i) output[i] = staged[i];
    return (int64_t)(8 * q);
}
