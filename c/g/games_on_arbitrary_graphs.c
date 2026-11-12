/* Reverse-edge retrograde classification for a bounded directed game graph. */
#include <stddef.h>
#include <stdint.h>

#define GG_MAX_V 16
#define GG_MAX_E 32
#define GG_MAX_INPUT 66
#define GG_MAX_OUTPUT 17

int64_t games_on_arbitrary_graphs(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > GG_MAX_INPUT) return -1;
    int64_t nv = input[0], me = input[1];
    if (nv < 0 || nv > GG_MAX_V || me < 0 || me > GG_MAX_E) return -1;
    size_t n = (size_t)nv, m = (size_t)me;
    if (length != 2 + 2 * m) return -1;

    uint16_t outmask[GG_MAX_V] = {0};
    int head[GG_MAX_V], edge_source[GG_MAX_E], edge_next[GG_MAX_E];
    int remaining[GG_MAX_V] = {0}, status[GG_MAX_V] = {0};
    int queue[GG_MAX_V];
    uint8_t staged[GG_MAX_OUTPUT] = {0};
    for (size_t v = 0; v < n; ++v) head[v] = -1;

    size_t unique_edges = 0;
    for (size_t i = 0; i < m; ++i) {
        int64_t sv = input[2 + 2 * i], tv = input[3 + 2 * i];
        if (sv < 0 || sv >= nv || tv < 0 || tv >= nv) return -1;
        size_t s = (size_t)sv, t = (size_t)tv;
        uint16_t bit = (uint16_t)(1u << t);
        if ((outmask[s] & bit) == 0) {
            outmask[s] = (uint16_t)(outmask[s] | bit);
            edge_source[unique_edges] = (int)s;
            edge_next[unique_edges] = head[t];
            head[t] = (int)unique_edges;
            ++unique_edges;
            ++remaining[s];
        }
    }

    size_t first = 0, count = 0;
    for (size_t v = 0; v < n; ++v) {
        if (remaining[v] == 0) {
            status[v] = 2;
            queue[count++] = (int)v;
        }
    }
    while (first < count) {
        int resolved = queue[first++];
        for (int edge = head[resolved]; edge != -1; edge = edge_next[edge]) {
            int predecessor = edge_source[edge];
            if (status[predecessor] != 0) continue;
            if (status[resolved] == 2) {
                status[predecessor] = 1;
                queue[count++] = predecessor;
            } else {
                --remaining[predecessor];
                if (remaining[predecessor] == 0) {
                    status[predecessor] = 2;
                    queue[count++] = predecessor;
                }
            }
        }
    }

    staged[0] = (uint8_t)n;
    for (size_t v = 0; v < n; ++v) staged[v + 1] = (uint8_t)status[v];
    size_t needed = n + 1;
    if (output == NULL || capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return (int64_t)needed;
}
