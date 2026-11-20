#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227,
       MAX_STATES = 2 * MAX_PATTERN + 1 };

int64_t reverse_factor_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;
    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (int q = 0; q < n; ++q) {
        const int64_t value = input[2 + q];
        if (value < 0 || value > 3) return -1;
        text[q] = (uint8_t)value;
    }
    for (int q = 0; q < m; ++q) {
        const int64_t value = input[2 + n + q];
        if (value < 0 || value > 3) return -1;
        pattern[q] = (uint8_t)value;
    }
    if (n < m) return 0;

    int transitions[MAX_STATES][4];
    int suffix_link[MAX_STATES];
    int max_length[MAX_STATES];
    uint8_t terminal[MAX_STATES] = {0};
    for (int state = 0; state < MAX_STATES; ++state) {
        suffix_link[state] = -1;
        max_length[state] = 0;
        for (int symbol = 0; symbol < 4; ++symbol) transitions[state][symbol] = -1;
    }
    int state_count = 1;
    int last = 0;
    for (int pos = 0; pos < m; ++pos) {
        const int symbol = pattern[m - 1 - pos];
        const int current = state_count++;
        max_length[current] = max_length[last] + 1;
        int predecessor = last;
        while (predecessor >= 0 && transitions[predecessor][symbol] < 0) {
            transitions[predecessor][symbol] = current;
            predecessor = suffix_link[predecessor];
        }
        if (predecessor < 0) {
            suffix_link[current] = 0;
        } else {
            const int target = transitions[predecessor][symbol];
            if (max_length[predecessor] + 1 == max_length[target]) {
                suffix_link[current] = target;
            } else {
                const int clone = state_count++;
                memcpy(transitions[clone], transitions[target], sizeof(transitions[clone]));
                max_length[clone] = max_length[predecessor] + 1;
                suffix_link[clone] = suffix_link[target];
                while (predecessor >= 0 && transitions[predecessor][symbol] == target) {
                    transitions[predecessor][symbol] = clone;
                    predecessor = suffix_link[predecessor];
                }
                suffix_link[target] = clone;
                suffix_link[current] = clone;
            }
        }
        last = current;
    }
    for (int state = last; state >= 0; state = suffix_link[state]) terminal[state] = 1;

    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int period = m;
    int start = 0;
    while (start <= n - m) {
        int index = m - 1;
        int state = 0;
        int shift = m;
        while (start + index >= 0) {
            const int target = transitions[state][text[start + index]];
            if (target < 0) break;
            state = target;
            if (terminal[state]) {
                period = shift;
                shift = index;
            }
            --index;
        }
        if (index < 0) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            shift = period;
        }
        start += shift;
    }
    return (int64_t)(((uint64_t)count << 36) |
                     ((uint64_t)offset_sum << 12) | (uint64_t)offset_xor);
}
