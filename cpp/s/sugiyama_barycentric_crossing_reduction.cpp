#include <cstddef>
#include <cstdint>

namespace {
constexpr int L = 8, N = 32, E = 128;
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
void positions_for_layer(int order[L][N], const int size[L], int layer, int pos[N]) {
    for (int i = 0; i < size[layer]; ++i) pos[order[layer][i]] = i;
}
void reorder(int order[L][N], const int size[L], const int owner[N],
             const int eu[E], const int ev[E], int edges, int target, int fixed,
             bool down, int pos[N]) {
    positions_for_layer(order, size, fixed, pos);
    int rank[N] = {}, num[N] = {}, den[N] = {};
    int *row = order[target];
    for (int i = 0; i < size[target]; ++i) rank[row[i]] = i;
    for (int e = 0; e < edges; ++e) {
        int u = eu[e], v = ev[e];
        if (down && owner[u] == fixed && owner[v] == target) { num[v] += pos[u]; ++den[v]; }
        else if (!down && owner[u] == target && owner[v] == fixed) { num[u] += pos[v]; ++den[u]; }
    }
    for (int i = 0; i < size[target]; ++i) if (den[row[i]] == 0) { num[row[i]] = rank[row[i]]; den[row[i]] = 1; }
    for (int i = 1; i < size[target]; ++i) {
        int x = row[i], j = i;
        while (j > 0) {
            int y = row[j - 1];
            auto left = static_cast<std::int64_t>(num[x]) * den[y];
            auto right = static_cast<std::int64_t>(num[y]) * den[x];
            if (left > right || (left == right && rank[x] > rank[y])) break;
            row[j] = y; --j;
        }
        row[j] = x;
    }
    positions_for_layer(order, size, target, pos);
}
}

extern "C" std::int64_t sugiyama_barycentric_crossing_reduction(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 299) return -1;
    int layers = static_cast<int>(input[0]), limit = static_cast<int>(input[1]);
    if (layers < 2 || layers > L || limit < 0 || limit > 16) return -1;
    int order[L][N] = {}, sizes[L] = {}, owner[N], pos[N] = {}, eu[E] = {}, ev[E] = {};
    for (int &x : owner) x = -1;
    std::size_t at = 2; int total = 0;
    for (int l = 0; l < layers; ++l) {
        if (at >= length) return -1;
        auto count = input[at++];
        if (count < 1 || count > N || at + static_cast<std::size_t>(count) > length) return -1;
        sizes[l] = static_cast<int>(count); total += sizes[l]; if (total > N) return -1;
        for (int i = 0; i < sizes[l]; ++i) {
            auto id0 = input[at++];
            if (id0 < 0 || id0 >= N || owner[id0] != -1) return -1;
            int id = static_cast<int>(id0); order[l][i] = id; owner[id] = l;
        }
    }
    if (total < 2 || at >= length) return -1;
    auto ec0 = input[at++];
    if (ec0 < 0 || ec0 > E || at + 2 * static_cast<std::size_t>(ec0) != length) return -1;
    int edges = static_cast<int>(ec0);
    for (int e = 0; e < edges; ++e) {
        auto u0 = input[at + 2 * e], v0 = input[at + 2 * e + 1];
        if (u0 < 0 || u0 >= N || v0 < 0 || v0 >= N) return -1;
        int u = static_cast<int>(u0), v = static_cast<int>(v0);
        if (owner[u] < 0 || owner[v] != owner[u] + 1) return -1;
        for (int j = 0; j < e; ++j) if (eu[j] == u && ev[j] == v) return -1;
        eu[e] = u; ev[e] = v;
    }
    int sweeps = 0;
    for (int pass = 0; pass < limit; ++pass) {
        int before[L][N] = {};
        for (int l = 0; l < layers; ++l) for (int i = 0; i < sizes[l]; ++i) before[l][i] = order[l][i];
        for (int l = 0; l + 1 < layers; ++l) reorder(order, sizes, owner, eu, ev, edges, l + 1, l, true, pos);
        for (int l = layers - 2; l >= 0; --l) reorder(order, sizes, owner, eu, ev, edges, l, l + 1, false, pos);
        ++sweeps; bool changed = false;
        for (int l = 0; l < layers; ++l) for (int i = 0; i < sizes[l]; ++i) if (before[l][i] != order[l][i]) changed = true;
        if (!changed) break;
    }
    for (int l = 0; l < layers; ++l) positions_for_layer(order, sizes, l, pos);
    std::int64_t crossings = 0;
    for (int i = 0; i < edges; ++i) for (int j = i + 1; j < edges; ++j)
        if (owner[eu[i]] == owner[eu[j]] &&
            (pos[eu[i]] - pos[eu[j]]) * (pos[ev[i]] - pos[ev[j]]) < 0) ++crossings;
    std::size_t bytes = 8 * (static_cast<std::size_t>(total) + 2);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, sweeps); put_i64(output, 1, crossings);
    std::size_t w = 2;
    for (int l = 0; l < layers; ++l) for (int i = 0; i < sizes[l]; ++i) put_i64(output, w++, order[l][i]);
    return static_cast<std::int64_t>(bytes);
}
