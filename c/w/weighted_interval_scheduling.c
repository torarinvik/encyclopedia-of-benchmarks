#include <stddef.h>
#include <stdint.h>

#define MAX_INTERVALS 64
#define MAX_INPUT_LENGTH (1 + 3 * MAX_INTERVALS)
#define MAX_OUTPUT_BYTES (16 + 4 * MAX_INTERVALS)

static int64_t start_at(const int64_t *input, size_t index) { return input[1 + index * 3]; }
static int64_t end_at(const int64_t *input, size_t index) { return input[2 + index * 3]; }
static int64_t weight_at(const int64_t *input, size_t index) { return input[3 + index * 3]; }

static void put_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t weighted_interval_scheduling(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > MAX_INTERVALS) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 3 * n) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t start = start_at(input, i), end = end_at(input, i), weight = weight_at(input, i);
        if (start < -100000 || start > 100000 || end < -100000 || end > 100000 || start >= end
            || weight < 0 || weight > 1000000) return -1;
    }

    size_t order[MAX_INTERVALS], predecessors[MAX_INTERVALS], selected[MAX_INTERVALS];
    int64_t dp[MAX_INTERVALS + 1] = {0};
    for (size_t i = 0; i < n; ++i) order[i] = i;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0 && end_at(input, order[j - 1]) > end_at(input, key)) { order[j] = order[j - 1]; --j; }
        order[j] = key;
    }
    for (size_t j = 0; j < n; ++j) {
        size_t low = 0, high = n;
        while (low < high) {
            const size_t mid = low + (high - low) / 2;
            if (end_at(input, order[mid]) <= start_at(input, order[j])) low = mid + 1;
            else high = mid;
        }
        predecessors[j] = low;
        const int64_t include = weight_at(input, order[j]) + dp[low];
        dp[j + 1] = include > dp[j] ? include : dp[j];
    }
    size_t selected_count = 0, current = n;
    while (current > 0) {
        const size_t j = current - 1;
        const int64_t include = weight_at(input, order[j]) + dp[predecessors[j]];
        if (include > dp[current - 1]) { selected[selected_count++] = order[j]; current = predecessors[j]; }
        else --current;
    }
    for (size_t i = 0; i < selected_count / 2; ++i) {
        const size_t temp = selected[i]; selected[i] = selected[selected_count - 1 - i]; selected[selected_count - 1 - i] = temp;
    }
    const size_t needed = 16 + 4 * selected_count;
    if (output == NULL || capacity < needed) return -2;
    put_i64_le(output, 0, dp[n]);
    put_i64_le(output, 8, (int64_t)selected_count);
    for (size_t i = 0; i < selected_count; ++i) put_i32_le(output, 16 + 4 * i, (int32_t)selected[i]);
    return (int64_t)needed;
}
