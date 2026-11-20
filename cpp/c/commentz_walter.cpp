#include <cstddef>
#include <cstdint>

enum { CW_P = 6, CW_L = 8, CW_T = 64, CW_NODES = 33, CW_INPUT = 105 };

static int cw_is_suffix(int v, int u, const int depth[CW_NODES],
                        const int path[CW_NODES][CW_L]) {
    if (depth[v] >= depth[u]) return 0;
    const int offset = depth[u] - depth[v];
    for (int i = 0; i < depth[v]; ++i)
        if (path[v][i] != path[u][offset + i]) return 0;
    return 1;
}

extern "C" std::int64_t commentz_walter(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > CW_INPUT) return -1;
    const std::int64_t pv = values[0], nv = values[1];
    if (pv < 1 || pv > CW_P || nv < 0 || nv > CW_T) return -1;
    const int p = static_cast<int>(pv), n = static_cast<int>(nv);
    int lens[CW_P], total = 0, shortest = CW_L + 1;
    if (length < static_cast<std::size_t>(2 + p)) return -1;
    for (int i = 0; i < p; ++i) {
        const std::int64_t raw = values[2 + i];
        if (raw < 1 || raw > CW_L) return -1;
        lens[i] = static_cast<int>(raw);
        total += lens[i];
        if (lens[i] < shortest) shortest = lens[i];
    }
    if (total > 32 || length != static_cast<std::size_t>(2 + p + total + n)) return -1;
    std::int64_t patterns[CW_P][CW_L] = {}, text[CW_T] = {};
    std::size_t at = static_cast<std::size_t>(2 + p);
    for (int i = 0; i < p; ++i) {
        for (int j = 0; j < lens[i]; ++j) {
            const std::int64_t symbol = values[at++];
            if (symbol < 1 || symbol > 4) return -1;
            patterns[i][j] = symbol;
        }
        for (int prior = 0; prior < i; ++prior) {
            if (lens[prior] != lens[i]) continue;
            bool same = true;
            for (int j = 0; j < lens[i]; ++j)
                if (patterns[prior][j] != patterns[i][j]) same = false;
            if (same) return -1;
        }
    }
    for (int i = 0; i < n; ++i) {
        const std::int64_t symbol = values[at++];
        if (symbol < 1 || symbol > 4) return -1;
        text[i] = symbol;
    }

    int child[CW_NODES][5] = {}, parent[CW_NODES] = {};
    int label[CW_NODES] = {}, depth[CW_NODES] = {};
    int path[CW_NODES][CW_L] = {}, terminal[CW_NODES] = {};
    int nodes = 1;
    for (int i = 0; i < p; ++i) {
        int v = 0;
        for (int j = lens[i] - 1; j >= 0; --j) {
            const int symbol = static_cast<int>(patterns[i][j]);
            int encoded = child[v][symbol];
            if (encoded == 0) {
                const int u = nodes++;
                child[v][symbol] = u + 1;
                parent[u] = v;
                label[u] = symbol;
                depth[u] = depth[v] + 1;
                for (int k = 0; k < depth[v]; ++k) path[u][k] = path[v][k];
                path[u][depth[v]] = symbol;
                encoded = u + 1;
            }
            v = encoded - 1;
        }
        terminal[v] = 1;
    }

    int shift1[CW_NODES], shift2[CW_NODES], bad[5];
    for (int v = 0; v < nodes; ++v) shift1[v] = shift2[v] = shortest;
    shift1[0] = 1;
    for (int a = 0; a <= 4; ++a) bad[a] = shortest + 1;
    for (int v = 1; v < nodes; ++v) {
        if (depth[v] < bad[label[v]]) bad[label[v]] = depth[v];
        shift2[v] = shift2[parent[v]];
        for (int u = 1; u < nodes; ++u) {
            if (cw_is_suffix(v, u, depth, path)) {
                const int delta = depth[u] - depth[v];
                if (delta < shift1[v]) shift1[v] = delta;
                if (terminal[u] && delta < shift2[v]) shift2[v] = delta;
            }
        }
    }

    std::int64_t matches = 0;
    int position = shortest - 1;
    while (position < n) {
        int v = 0, i = position;
        while (i >= 0) {
            const int encoded = child[v][static_cast<int>(text[i])];
            if (encoded == 0) break;
            v = encoded - 1;
            --i;
            if (terminal[v]) ++matches;
        }
        const int symbol = i >= 0 ? static_cast<int>(text[i]) : 0;
        const int char_shift = symbol == 0 ? shortest + 1 : bad[symbol];
        int delta = char_shift - depth[v] - 1;
        if (delta < shift1[v]) delta = shift1[v];
        if (delta > shift2[v]) delta = shift2[v];
        position += delta;
    }
    return matches;
}
