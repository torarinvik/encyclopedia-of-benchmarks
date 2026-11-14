#include <stddef.h>
#include <stdint.h>

typedef struct { int next[4], link, len; } sam_state;

int64_t shortest_absent_substring_sam(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 66 || input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 64) return -1;
    int alphabet = (int)input[0], n = (int)input[1];
    if (length != (size_t)(2+n)) return -1;
    for (int i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] >= alphabet) return -1;
    sam_state states[129];
    for (int i = 0; i < 129; ++i) { states[i].link = -1; states[i].len = 0; for (int a = 0; a < 4; ++a) states[i].next[a] = -1; }
    int size = 1, last = 0;
    for (int i = 0; i < n; ++i) {
        int symbol = (int)input[2+i], current = size++, p = last;
        states[current].len = states[last].len+1;
        while (p >= 0 && states[p].next[symbol] < 0) { states[p].next[symbol] = current; p = states[p].link; }
        if (p < 0) states[current].link = 0;
        else {
            int q = states[p].next[symbol];
            if (states[p].len+1 == states[q].len) states[current].link = q;
            else {
                int clone = size++;
                states[clone] = states[q]; states[clone].len = states[p].len+1;
                while (p >= 0 && states[p].next[symbol] == q) { states[p].next[symbol] = clone; p = states[p].link; }
                states[q].link = states[current].link = clone;
            }
        }
        last = current;
    }
    int counts[65] = {0}, order[129], dp[129] = {0};
    for (int s = 0; s < size; ++s) ++counts[states[s].len];
    for (int i = 1; i <= n; ++i) counts[i] += counts[i-1];
    for (int s = size-1; s >= 0; --s) order[--counts[states[s].len]] = s;
    for (int i = size-1; i >= 0; --i) {
        int s = order[i], best = 100;
        for (int a = 0; a < alphabet; ++a) {
            int child = states[s].next[a], candidate = child < 0 ? 1 : 1+dp[child];
            if (candidate < best) best = candidate;
        }
        dp[s] = best;
    }
    uint8_t staged[6]; int count = 0, state = 0;
    while (state >= 0) {
        for (int a = 0; a < alphabet; ++a) {
            int child = states[state].next[a];
            if ((child < 0 && dp[state] == 1) || (child >= 0 && dp[state] == 1+dp[child])) {
                staged[count++] = (uint8_t)a; state = child; break;
            }
        }
    }
    if (!output || capacity < (size_t)count) return -2;
    for (int i = 0; i < count; ++i) output[i] = staged[i];
    return count;
}
