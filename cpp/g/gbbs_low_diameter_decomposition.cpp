// Clean-room bounded GBBS MPX low-diameter decomposition profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 12, M = 24, INPUT = 2 + 2 * M, ROUNDS = 13;
constexpr std::array<std::size_t, ROUNDS> BATCH{1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11};
}

extern "C" std::int64_t gbbs_low_diameter_decomposition(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(N) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(M) || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, N>, N> adjacent{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }
    if (output == nullptr || capacity < n) return -2;

    std::array<int, N> label{};
    label.fill(-1);
    std::array<std::size_t, N> frontier{};
    std::size_t frontier_count = 0, cursor = 0, assigned = 0, round = 0;
    while (assigned < n) {
        const auto end = (cursor + BATCH[round] < n) ? cursor + BATCH[round] : n;
        for (auto candidate = cursor; candidate < end; ++candidate) {
            if (label[candidate] < 0) {
                label[candidate] = static_cast<int>(candidate);
                frontier[frontier_count++] = candidate;
                ++assigned;
            }
        }
        cursor = end;
        if (assigned == n) break;

        std::array<int, N> reached{};
        reached.fill(-1);
        for (std::size_t i = 0; i < frontier_count; ++i) {
            const auto vertex = frontier[i];
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[vertex][neighbor] && label[neighbor] < 0 &&
                    (reached[neighbor] < 0 || label[vertex] < reached[neighbor]))
                    reached[neighbor] = label[vertex];
            }
        }
        frontier_count = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (reached[vertex] >= 0) {
                label[vertex] = reached[vertex];
                frontier[frontier_count++] = vertex;
                ++assigned;
            }
        }
        ++round;
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        output[vertex] = static_cast<std::uint8_t>(label[vertex]);
    return static_cast<std::int64_t>(n);
}
