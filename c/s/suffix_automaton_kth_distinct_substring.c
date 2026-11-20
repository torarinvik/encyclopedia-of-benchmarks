/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    int next[256];
    int link;
    int length;
    int64_t paths;
} substring_state;

int64_t suffix_automaton_kth_distinct_substring(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 259) return -1;
    int64_t raw_n = input[0], k = input[1];
    if (raw_n < 1 || raw_n > 256 || length != (size_t)raw_n + 2 || k < 1)
        return -1;
    int n = (int)raw_n;
    for (int i = 0; i < n; ++i)
        if (input[i + 2] < 0 || input[i + 2] > 255) return -1;

    substring_state states[512];
    for (int i = 0; i < 512; ++i) {
        for (int c = 0; c < 256; ++c) states[i].next[c] = -1;
        states[i].link = -1;
        states[i].length = 0;
        states[i].paths = 0;
    }
    int count = 1, last = 0;
    for (int i = 0; i < n; ++i) {
        int symbol = (int)input[i + 2];
        int current = count++;
        states[current].length = states[last].length + 1;
        int p = last;
        while (p >= 0 && states[p].next[symbol] == -1) {
            states[p].next[symbol] = current;
            p = states[p].link;
        }
        if (p < 0) states[current].link = 0;
        else {
            int q = states[p].next[symbol];
            if (states[p].length + 1 == states[q].length)
                states[current].link = q;
            else {
                int clone = count++;
                memcpy(&states[clone], &states[q], sizeof(states[clone]));
                states[clone].length = states[p].length + 1;
                while (p >= 0 && states[p].next[symbol] == q) {
                    states[p].next[symbol] = clone;
                    p = states[p].link;
                }
                states[q].link = states[current].link = clone;
            }
        }
        last = current;
    }

    int buckets[257] = {0}, order[512];
    for (int i = 0; i < count; ++i) ++buckets[states[i].length];
    for (int i = 1; i <= n; ++i) buckets[i] += buckets[i - 1];
    for (int i = count - 1; i >= 0; --i)
        order[--buckets[states[i].length]] = i;
    for (int i = count - 1; i >= 0; --i) {
        int state = order[i];
        for (int c = 0; c < 256; ++c) {
            int next = states[state].next[c];
            if (next >= 0) states[state].paths += 1 + states[next].paths;
        }
    }
    if (k > states[0].paths) return -1;

    uint8_t result[256];
    size_t result_length = 0;
    int state = 0;
    for (;;) {
        for (int c = 0; c < 256; ++c) {
            int next = states[state].next[c];
            if (next < 0) continue;
            int64_t group = 1 + states[next].paths;
            if (k > group) { k -= group; continue; }
            result[result_length++] = (uint8_t)c;
            state = next;
            goto selected_edge;
        }
        return -1; /* Unreachable for a valid rank. */
selected_edge:
        if (k == 1) break;
        --k;
    }
    if (!output || capacity < result_length) return -2;
    memcpy(output, result, result_length);
    return (int64_t)result_length;
}
