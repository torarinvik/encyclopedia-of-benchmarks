/* Uncompiled and unexecuted next-occurrence automaton draft. */
#include <stddef.h>
#include <stdint.h>

int64_t subsequence_automaton(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 354) return -1;
    if (input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    size_t n = (size_t)input[0], queries = (size_t)input[1];
    if (length < 2+n) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 3) return -1;
    size_t next[65][4];
    for (size_t c = 0; c < 4; ++c) next[n][c] = n;
    for (size_t i = n; i-- > 0;) {
        for (size_t c = 0; c < 4; ++c) next[i][c] = next[i+1][c];
        next[i][(size_t)input[2+i]] = i;
    }
    size_t position = 2+n, total = 0;
    int64_t answer = 0;
    for (size_t query = 0; query < queries; ++query) {
        if (position == length || input[position] < 0 || input[position] > 256) return -1;
        size_t count = (size_t)input[position++];
        if (count > 256-total || count > length-position) return -1;
        size_t cursor = 0;
        int match = 1;
        for (size_t i = 0; i < count; ++i) {
            int64_t symbol = input[position+i];
            if (symbol < 0 || symbol > 3) return -1;
            if (match) {
                size_t found = next[cursor][(size_t)symbol];
                if (found == n) match = 0;
                else cursor = found+1;
            }
        }
        if (match) answer += (int64_t)(query+1);
        position += count; total += count;
    }
    return position == length ? answer : -1;
}
