#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 256, MAX_PATTERN = 16, ALPHABET = 16, MAX_INPUT = 274 };

int64_t simon_string_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT) return -2;
    if (values[0] < 0 || values[0] > MAX_TEXT || values[1] < 1 || values[1] > MAX_PATTERN) return -2;
    const size_t n = (size_t)values[0], m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    for (size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= ALPHABET) return -2;
    const size_t pattern = 2 + n;
    int head[MAX_PATTERN], edge_target[MAX_PATTERN], edge_next[MAX_PATTERN];
    for (size_t i = 0; i < MAX_PATTERN; ++i) head[i] = -1;
    int edge_count = 0, ell = -1;
    for (size_t i = 1; i < m; ++i) {
        const int k = ell;
        int cell = k < 0 ? -1 : head[k];
        ell = -1;
        if (values[pattern + i] == values[pattern + (size_t)(k + 1)]) ell = k + 1;
        else {
            edge_target[edge_count] = k + 1;
            edge_next[edge_count] = head[i - 1];
            head[i - 1] = edge_count++;
        }
        while (cell >= 0) {
            const int target = edge_target[cell];
            if (values[pattern + i] == values[pattern + (size_t)target]) ell = target;
            else {
                edge_target[edge_count] = target;
                edge_next[edge_count] = head[i - 1];
                head[i - 1] = edge_count++;
            }
            cell = edge_next[cell];
        }
    }

    int state = -1;
    int64_t matches = 0;
    for (size_t j = 0; j < n; ++j) {
        const int64_t symbol = values[2 + j];
        if (state < (int)m - 1 && values[pattern + (size_t)(state + 1)] == symbol) {
            ++state;
        } else if (state >= 0) {
            int edge = head[state];
            state = -1;
            while (edge >= 0) {
                const int target = edge_target[edge];
                if (values[pattern + (size_t)target] == symbol) { state = target; break; }
                edge = edge_next[edge];
            }
        } else {
            state = -1;
        }
        if (state >= (int)m - 1) {
            ++matches;
            state = ell;
        }
    }
    return matches;
}
