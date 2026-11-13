/* Improved shortest augmenting path with reverse labels and the gap rule. */
#include <stddef.h>
#include <stdint.h>

#define NMAX 8
#define MMAX 24
#define INPUT_MAX (4 + 3 * MMAX + 1)
#define FLOW_MAX INT64_C(2400)

typedef struct {
    int n, sink;
    int64_t residual[NMAX * NMAX];
    int64_t distance[NMAX];
    int64_t gap[NMAX + 1];
    size_t current[NMAX];
    int stopped;
} IsapState;

static int64_t isap_dfs(IsapState *s, int u, int64_t amount) {
    if (u == s->sink) return amount;
    while (s->current[u] < (size_t)s->n) {
        const int v = (int)s->current[u];
        const size_t edge = (size_t)u * NMAX + (size_t)v;
        if (s->residual[edge] > 0 && s->distance[u] == s->distance[v] + 1) {
            const int64_t limit = amount < s->residual[edge] ? amount : s->residual[edge];
            const int64_t sent = isap_dfs(s, v, limit);
            if (sent > 0) {
                s->residual[edge] -= sent;
                s->residual[(size_t)v * NMAX + (size_t)u] += sent;
                return sent;
            }
            if (s->stopped) return 0;
        }
        ++s->current[u];
    }
    const int64_t old = s->distance[u];
    int64_t best = s->n;
    for (int v = 0; v < s->n; ++v)
        if (s->residual[(size_t)u * NMAX + (size_t)v] > 0 && s->distance[v] < best)
            best = s->distance[v];
    const int64_t replacement = best + 1 < s->n ? best + 1 : s->n;
    --s->gap[old];
    s->distance[u] = replacement;
    ++s->gap[replacement];
    s->current[u] = 0;
    if (old < s->n && s->gap[old] == 0) s->stopped = 1;
    return 0;
}

int64_t isap_maxflow(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > INPUT_MAX) return -1;
    const int64_t nv = input[0], mv = input[1], sv = input[2], tv = input[3];
    if (nv < 2 || nv > NMAX || mv < 0 || mv > MMAX || sv < 0 || sv >= nv ||
        tv < 0 || tv >= nv || sv == tv || length != (size_t)(4 + 3 * mv)) return -1;
    IsapState s = {0};
    s.n = (int)nv;
    s.sink = (int)tv;
    for (int e = 0; e < (int)mv; ++e) {
        const int64_t u = input[4 + 3 * e], v = input[5 + 3 * e], c = input[6 + 3 * e];
        if (u < 0 || u >= nv || v < 0 || v >= nv || u == v || c < 0 || c > 100) return -1;
        s.residual[(size_t)u * NMAX + (size_t)v] += c;
    }
    int queue[NMAX], head = 0, tail = 0;
    for (int v = 0; v < s.n; ++v) s.distance[v] = s.n;
    s.distance[s.sink] = 0;
    queue[tail++] = s.sink;
    while (head < tail) {
        const int v = queue[head++];
        for (int p = 0; p < s.n; ++p)
            if (s.distance[p] == s.n && s.residual[(size_t)p * NMAX + (size_t)v] > 0) {
                s.distance[p] = s.distance[v] + 1;
                queue[tail++] = p;
            }
    }
    if (s.distance[(int)sv] >= s.n) return 0;
    for (int v = 0; v < s.n; ++v) ++s.gap[s.distance[v]];
    int64_t flow = 0;
    while (s.distance[(int)sv] < s.n && !s.stopped) {
        const int64_t sent = isap_dfs(&s, (int)sv, FLOW_MAX);
        flow += sent;
    }
    return flow;
}
