#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 8
#define MAX_PARSEABLE_INPUT_LENGTH (2 * MAX_LENGTH + 3)
#define MEMO_SIZE (9 * 9 * 9)

static int scramble_rec(const int64_t *values, size_t base1, size_t base2,
                        size_t start1, size_t start2, size_t span, int8_t *memo)
{
    const size_t slot = (start1 * 9 + start2) * 9 + span;
    if (memo[slot] >= 0) return memo[slot];

    int same = 1;
    for (size_t offset = 0; offset < span; ++offset)
        if (values[base1 + start1 + offset] != values[base2 + start2 + offset]) {
            same = 0;
            break;
        }
    if (same) {
        memo[slot] = 1;
        return 1;
    }

    int counts[26] = {0};
    for (size_t offset = 0; offset < span; ++offset) {
        counts[values[base1 + start1 + offset] - 'a']++;
        counts[values[base2 + start2 + offset] - 'a']--;
    }
    for (size_t index = 0; index < 26; ++index)
        if (counts[index] != 0) {
            memo[slot] = 0;
            return 0;
        }

    for (size_t split = 1; split < span; ++split) {
        if (scramble_rec(values, base1, base2, start1, start2, split, memo) &&
            scramble_rec(values, base1, base2, start1 + split, start2 + split, span - split, memo)) {
            memo[slot] = 1;
            return 1;
        }
        if (scramble_rec(values, base1, base2, start1, start2 + span - split, split, memo) &&
            scramble_rec(values, base1, base2, start1 + split, start2, span - split, memo)) {
            memo[slot] = 1;
            return 1;
        }
    }
    memo[slot] = 0;
    return 0;
}

int64_t scramble_strings(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    if (n_value < 0 || n_value > MAX_LENGTH) return -1;
    const size_t n = (size_t)n_value;
    if (length != 2 * n + 1) return -1;
    for (size_t index = 1; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -1;

    int8_t memo[MEMO_SIZE];
    for (size_t index = 0; index < MEMO_SIZE; ++index) memo[index] = -1;
    return scramble_rec(values, 1, 1 + n, 0, 0, n, memo);
}
