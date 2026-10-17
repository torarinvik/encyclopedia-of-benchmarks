#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 128
#define MAX_INPUT_LENGTH (MAX_NODES + 1)

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t median_search2(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_NODES) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    for (size_t i = 0; i < count; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;

    int32_t next[MAX_NODES];
    for (size_t i = 0; i < count; ++i) next[i] = i + 1 < count ? (int32_t)(i + 1) : -1;
    int32_t found = 0, median_index = -1;
    if (count > 0) {
        int32_t slow = 0, fast = 0;
        while (next[fast] >= 0 && next[next[fast]] >= 0) {
            slow = next[slow];
            fast = next[next[fast]];
        }
        median_index = next[fast] >= 0 ? next[slow] : slow;
        found = 1;
    }
    if (output == NULL || capacity < 8) return -2;
    uint8_t buffer[8];
    put_i32_le(buffer, 0, median_index < 0 ? 0 : found);
    put_i32_le(buffer, 4, median_index);
    for (size_t i = 0; i < sizeof buffer; ++i) output[i] = buffer[i];
    return 8;
}
