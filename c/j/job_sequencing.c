#include <stddef.h>
#include <stdint.h>

#define MAX_JOBS 32
#define MAX_INPUT_LENGTH (1 + 3 * MAX_JOBS + 1)
#define MAX_PROFIT INT64_C(1000000)

int64_t job_sequencing(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_JOBS) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 3 * n) return -1;
    uint8_t seen[128] = {0};
    int64_t previous_profit = MAX_PROFIT + 1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t id = input[1 + 3 * i], deadline = input[2 + 3 * i], profit = input[3 + 3 * i];
        const int is_letter = (id >= 'A' && id <= 'Z') || (id >= 'a' && id <= 'z');
        if (!is_letter || seen[id] || deadline < 1 || deadline > (int64_t)n || profit < 1 || profit > MAX_PROFIT || profit >= previous_profit) return -1;
        seen[id] = 1; previous_profit = profit;
    }
    uint8_t slots[MAX_JOBS] = {0};
    int64_t total_profit = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t deadline = (size_t)input[2 + 3 * i];
        for (size_t remaining = deadline; remaining > 0; --remaining) {
            const size_t slot = remaining - 1;
            if (slots[slot] == 0) { slots[slot] = (uint8_t)input[1 + 3 * i]; total_profit += input[3 + 3 * i]; break; }
        }
    }
    size_t count = 0; for (size_t i = 0; i < n; ++i) if (slots[i] != 0) ++count;
    const size_t required = 9 + count;
    if (output == NULL || capacity < required) return -2;
    output[0] = (uint8_t)count;
    const uint64_t profit_bits = (uint64_t)total_profit;
    for (size_t i = 0; i < 8; ++i) output[1 + i] = (uint8_t)(profit_bits >> (8 * i));
    size_t written = 9; for (size_t i = 0; i < n; ++i) if (slots[i] != 0) output[written++] = slots[i];
    return (int64_t)required;
}
