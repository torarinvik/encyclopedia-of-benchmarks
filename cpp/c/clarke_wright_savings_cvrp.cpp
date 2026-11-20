#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Saving { int64_t value; int i, j; };
using Route = std::array<int, 7>;
void reverse_route(Route &route, int length) {
    for (int l = 0, r = length - 1; l < r; ++l, --r) std::swap(route[l], route[r]);
}
bool before(const Saving &a, const Saving &b) {
    if (a.value != b.value) return a.value > b.value;
    if (a.i != b.i) return a.i < b.i;
    return a.j < b.j;
}
int compare_routes(const Route &a, int an, const Route &b, int bn) {
    int common = std::min(an, bn);
    for (int i = 0; i < common; ++i) {
        if (a[i] != b[i]) return a[i] < b[i] ? -1 : 1;
    }
    return an < bn ? -1 : an > bn ? 1 : 0;
}
void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits = static_cast<uint64_t>(value);
    for (int i = 0; i < 8; ++i) out[i] = static_cast<uint8_t>(bits >> (8 * i));
}
}

extern "C" int64_t clarke_wright_savings_cvrp(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 74) return -1;
    int64_t n64 = input[0], cap64 = input[1];
    if (n64 < 0 || n64 > 7 || cap64 < 1 || cap64 > 100) return -1;
    int n = static_cast<int>(n64), cap = static_cast<int>(cap64), width = n + 1;
    if (length != static_cast<size_t>(2 + n + width * width)) return -1;
    std::array<int64_t, 8> demand{};
    std::array<std::array<int64_t, 8>, 8> distance{};
    for (int c = 1; c <= n; ++c) {
        demand[c] = input[1 + c];
        if (demand[c] < 1 || demand[c] > cap) return -1;
    }
    size_t offset = static_cast<size_t>(2 + n);
    for (int i = 0; i < width; ++i) for (int j = 0; j < width; ++j) {
        int64_t d = input[offset + static_cast<size_t>(i) * width + j];
        if (d < 0 || d > 1000 || (i == j && d != 0)) return -1;
        distance[i][j] = d;
    }
    for (int i = 0; i < width; ++i) for (int j = i + 1; j < width; ++j)
        if (distance[i][j] != distance[j][i]) return -1;

    std::array<Route, 7> routes{};
    std::array<int, 7> route_length{};
    std::array<int64_t, 7> load{};
    std::array<bool, 7> active{};
    for (int r = 0; r < n; ++r) {
        routes[r][0] = r + 1; route_length[r] = 1; load[r] = demand[r + 1]; active[r] = true;
    }
    std::array<Saving, 21> pairs{}; int pair_count = 0;
    for (int i = 1; i <= n; ++i) for (int j = i + 1; j <= n; ++j)
        pairs[pair_count++] = {distance[0][i] + distance[0][j] - distance[i][j], i, j};
    std::sort(pairs.begin(), pairs.begin() + pair_count, before);
    for (int p = 0; p < pair_count && pairs[p].value > 0; ++p) {
        int ri = -1, rj = -1, pi = -1, pj = -1;
        for (int r = 0; r < n; ++r) if (active[r]) for (int at = 0; at < route_length[r]; ++at) {
            if (routes[r][at] == pairs[p].i) { ri = r; pi = at; }
            if (routes[r][at] == pairs[p].j) { rj = r; pj = at; }
        }
        if (ri == rj || ri < 0 || rj < 0) continue;
        if ((pi != 0 && pi != route_length[ri] - 1)
                || (pj != 0 && pj != route_length[rj] - 1)
                || load[ri] + load[rj] > cap) continue;
        if (pi == 0) reverse_route(routes[ri], route_length[ri]);
        if (pj == route_length[rj] - 1) reverse_route(routes[rj], route_length[rj]);
        for (int at = 0; at < route_length[rj]; ++at)
            routes[ri][route_length[ri] + at] = routes[rj][at];
        route_length[ri] += route_length[rj]; load[ri] += load[rj];
        active[rj] = false; route_length[rj] = 0; load[rj] = 0;
    }

    std::array<Route, 7> final_routes{}; std::array<int, 7> final_length{}; int count = 0;
    for (int r = 0; r < n; ++r) if (active[r]) {
        bool reverse_first = false;
        for (int at = 0; at < route_length[r]; ++at) {
            int a = routes[r][at], b = routes[r][route_length[r] - 1 - at];
            if (a != b) { reverse_first = a > b; break; }
        }
        if (reverse_first) reverse_route(routes[r], route_length[r]);
        final_routes[count] = routes[r]; final_length[count++] = route_length[r];
    }
    for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j)
        if (compare_routes(final_routes[i], final_length[i], final_routes[j], final_length[j]) > 0) {
            std::swap(final_routes[i], final_routes[j]); std::swap(final_length[i], final_length[j]);
        }
    std::array<int64_t, 15> words{}; int word_count = 0;
    words[word_count++] = count;
    for (int r = 0; r < count; ++r) {
        words[word_count++] = final_length[r];
        for (int at = 0; at < final_length[r]; ++at) words[word_count++] = final_routes[r][at];
    }
    size_t bytes = static_cast<size_t>(word_count) * 8;
    if (!output || capacity < bytes) return -2;
    for (int i = 0; i < word_count; ++i) put_i64(output + static_cast<size_t>(i) * 8, words[i]);
    return static_cast<int64_t>(bytes);
}
