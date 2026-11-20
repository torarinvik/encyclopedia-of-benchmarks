/* Uncompiled suffix-automaton minimum-rotation draft. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    int next[256];
    int link;
    int length;
} sam_state;

int64_t suffix_automaton_minimum_rotation(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 258) return -1;
    int64_t raw_n = input[0];
    if (raw_n < 1 || raw_n > 256 || length != (size_t)raw_n + 1) return -1;
    size_t n = (size_t)raw_n;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (!output || capacity < n) return -2;

    sam_state states[1024];
    for (size_t i = 0; i < 1024; ++i) {
        for (size_t c = 0; c < 256; ++c) states[i].next[c] = -1;
        states[i].link = -1;
        states[i].length = 0;
    }
    int count = 1, last = 0;
    for (size_t i = 0; i < 2*n; ++i) {
        int symbol = (int)input[1 + i%n];
        int current = count++;
        states[current].length = states[last].length + 1;
        int p = last;
        while (p >= 0 && states[p].next[symbol] == -1) {
            states[p].next[symbol] = current;
            p = states[p].link;
        }
        if (p < 0) {
            states[current].link = 0;
        } else {
            int q = states[p].next[symbol];
            if (states[p].length + 1 == states[q].length) {
                states[current].link = q;
            } else {
                int clone = count++;
                memcpy(&states[clone], &states[q], sizeof(sam_state));
                states[clone].length = states[p].length + 1;
                while (p >= 0 && states[p].next[symbol] == q) {
                    states[p].next[symbol] = clone;
                    p = states[p].link;
                }
                states[q].link = clone;
                states[current].link = clone;
            }
        }
        last = current;
    }
    int state = 0;
    for (size_t i = 0; i < n; ++i) {
        int symbol = 0;
        while (states[state].next[symbol] < 0) ++symbol;
        output[i] = (uint8_t)symbol;
        state = states[state].next[symbol];
    }
    return (int64_t)n;
}
