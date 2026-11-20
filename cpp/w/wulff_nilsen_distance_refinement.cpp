#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_m = 28;
constexpr std::size_t max_input = 93;
constexpr std::int64_t scale = INT64_C(86093442);
constexpr std::int64_t inf = INT64_C(1) << 60;
using Matrix = std::array<std::array<std::int64_t, max_n>, max_n>;
using Samples = std::array<std::array<int, max_n>, 4>;
using Bunches = std::array<std::array<bool, max_n>, max_n>;

int even_index(int vertex, std::int64_t threshold, const Samples& sample, const Matrix& d) {
    return d[vertex][sample[2][vertex]] <= threshold ? 2 : 0;
}

int delta_index(int source, int upper, const Samples& sample, const Matrix& d) {
    int chosen = 0;
    std::int64_t best = -1;
    for (int j = 0; j < upper - 1; j += 2) {
        const auto gap = d[source][sample[j + 2][source]] - d[source][sample[j][source]];
        if (gap > best) {
            best = gap;
            chosen = j;
        }
    }
    return chosen;
}

bool refine_further(int u, int v, int iu, const Samples& sample,
                    const Bunches& bunch, const Matrix& d) {
    if (iu < 2) return false;
    const int j = delta_index(u, iu, sample, d);
    return bunch[v][sample[j][u]] || bunch[u][sample[j + 1][v]] ||
           bunch[v][sample[iu][u]] || bunch[u][sample[iu + 1][v]];
}
}

extern "C" std::int64_t wulff_nilsen_distance_refinement(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 8 || length > max_input) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(max_n) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(max_m)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    if (length != 8 + 3 * static_cast<std::size_t>(m)) return -1;

    const std::int64_t full = (INT64_C(1) << n) - 1;
    std::array<std::int64_t, 3> masks{};
    for (int i = 0; i < 3; ++i) {
        masks[i] = input[2 + i];
        if (masks[i] <= 0 || (masks[i] & ~full) != 0) return -1;
    }
    if ((masks[1] & ~masks[0]) != 0 || (masks[2] & ~masks[1]) != 0) return -1;

    Matrix d{};
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v) d[u][v] = u == v ? 0 : inf;
    int previous_u = -1, previous_v = -1;
    for (int e = 0; e < m; ++e) {
        const auto at = 5 + 3 * static_cast<std::size_t>(e);
        const auto u64 = input[at], v64 = input[at + 1], weight = input[at + 2];
        if (u64 < 0 || u64 >= n || v64 <= u64 || v64 >= n ||
            weight < scale || weight > scale * 100 || weight % scale != 0) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        d[u][v] = d[v][u] = weight;
    }
    const auto query = 5 + 3 * static_cast<std::size_t>(m);
    const auto source64 = input[query], target64 = input[query + 1], estimate = input[query + 2];
    if (source64 < 0 || source64 >= n || target64 < 0 || target64 >= n ||
        source64 == target64 || estimate <= 0 || estimate % scale != 0) return -1;
    const int source = static_cast<int>(source64), target = static_cast<int>(target64);

    for (int middle = 0; middle < n; ++middle)
        for (int u = 0; u < n; ++u) {
            if (d[u][middle] == inf) continue;
            for (int v = 0; v < n; ++v)
                if (d[u][middle] + d[middle][v] < d[u][v])
                    d[u][v] = d[u][middle] + d[middle][v];
        }
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v) if (d[u][v] == inf) return -1;
    if (estimate < d[source][target] || estimate > INT64_C(768) * d[source][target]) return -1;

    Samples sample{};
    for (int x = 0; x < n; ++x) {
        sample[0][x] = x;
        for (int level = 1; level < 4; ++level) {
            int best = -1;
            for (int y = 0; y < n; ++y) if ((masks[level - 1] >> y) & 1) {
                if (best < 0 || d[x][y] < d[x][best] || (d[x][y] == d[x][best] && y < best)) best = y;
            }
            sample[level][x] = best;
        }
    }

    const std::array<std::int64_t, 5> layers{full, masks[0], masks[1], masks[2], 0};
    Bunches bunch{};
    for (int center = 0; center < n; ++center)
        for (int level = 0; level < 4; ++level) {
            std::int64_t boundary = inf;
            for (int y = 0; y < n; ++y)
                if (((layers[level + 1] >> y) & 1) && d[center][y] < boundary) boundary = d[center][y];
            for (int y = 0; y < n; ++y)
                if (((layers[level] >> y) & 1) && !((layers[level + 1] >> y) & 1) &&
                    d[center][y] < boundary) bunch[center][y] = true;
        }

    std::int64_t value = estimate;
    int iu = even_index(source, value, sample, d);
    if (!refine_further(source, target, iu, sample, bunch, d)) return value;
    for (int iteration = 0; iteration <= 15 && refine_further(source, target, iu, sample, bunch, d); ++iteration) {
        value = (2 * value) / 3;
        iu = even_index(source, value, sample, d);
    }
    const int upper = even_index(source, (3 * value) / 2, sample, d);
    if (upper < 2) return -1;
    const int j = delta_index(source, upper, sample, d);
    int pivot = sample[j][source];
    if (bunch[target][pivot]) return d[source][pivot] + d[target][pivot];
    pivot = sample[j + 1][target];
    if (bunch[source][pivot]) return d[source][pivot] + d[target][pivot];
    pivot = sample[upper][source];
    if (bunch[target][pivot]) return d[source][pivot] + d[target][pivot];
    pivot = sample[upper + 1][target];
    return d[source][pivot] + d[target][pivot];
}
