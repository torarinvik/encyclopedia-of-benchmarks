#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { MAX_N = 12344, MAX_PARSEABLE_INPUT_LENGTH = 12348 };

int64_t sparse_table(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 3) return -1;
    if (input[n + 1] < 0 || input[n + 2] < input[n + 1] || input[n + 2] >= (int64_t)n) return -1;
    const size_t left = (size_t)input[n + 1];
    const size_t right = (size_t)input[n + 2];

    size_t levels = 1;
    while (((uint64_t)1 << levels) <= n) ++levels;
    int64_t *table = calloc(levels * n, sizeof(int64_t));
    if (table == NULL) return -1;
    int64_t *logs = calloc(n + 1, sizeof(int64_t));
    if (logs == NULL) {
        free(table);
        return -1;
    }

    const int64_t *values = input + 1;
    logs[0] = -1;
    for (size_t i = 0; i < n; ++i) {
        table[i] = (int64_t)i;
        logs[i + 1] = logs[i] + (((i & (i + 1)) == 0) ? 1 : 0);
    }
    size_t span = 2;
    for (size_t level = 1; level < levels; ++level, span *= 2) {
        const size_t half = span / 2;
        for (size_t i = 0; i + span <= n; ++i) {
            const size_t x = (size_t)table[(level - 1) * n + i];
            const size_t y = (size_t)table[(level - 1) * n + i + half];
            table[level * n + i] = values[x] <= values[y] ? (int64_t)x : (int64_t)y;
        }
    }

    const size_t query_length = right - left + 1;
    const size_t level = (size_t)logs[query_length];
    const size_t block = (size_t)1 << level;
    const size_t x = (size_t)table[level * n + left];
    const size_t y = (size_t)table[level * n + right - block + 1];
    const size_t answer = values[x] <= values[y] ? x : y;
    free(logs);
    free(table);
    return (int64_t)answer;
}
