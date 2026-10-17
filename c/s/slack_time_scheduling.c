#include <stddef.h>
#include <stdint.h>
#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 2 * MAX_N)
#define MAX_TIME INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 255); bits >>= 8; }
}

int64_t slack_time_scheduling(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    int64_t execution[MAX_N], deadline[MAX_N], slack[MAX_N];
    size_t order[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        execution[i] = input[1 + 2 * i];
        deadline[i] = input[2 + 2 * i];
        if (execution[i] < 0 || execution[i] > MAX_TIME || deadline[i] < 0 || deadline[i] > MAX_TIME) return -1;
        slack[i] = deadline[i] - execution[i];
        order[i] = i;
    }
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && slack[key] < slack[order[j - 1]]) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, i * 8, (int64_t)order[i]);
    return (int64_t)bytes;
}
