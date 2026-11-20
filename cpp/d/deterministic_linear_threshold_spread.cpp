#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 24;
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t deterministic_linear_threshold_spread(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 92) return -1;
    const auto n_raw = input[0], m_raw = input[1], s_raw = input[2];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(MaxN) || m_raw < 0 || m_raw > static_cast<std::int64_t>(MaxM) ||
        s_raw < 0 || s_raw > n_raw) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    const auto m = static_cast<std::size_t>(m_raw);
    const auto seed_count = static_cast<std::size_t>(s_raw);
    const auto seed_offset = std::size_t{3};
    const auto edge_offset = seed_offset + seed_count;
    const auto threshold_offset = edge_offset + 3 * m;
    if (length != threshold_offset + n) return -1;

    std::array<bool, MaxN> seeded{};
    std::array<std::array<bool, MaxN>, MaxN> seen{};
    std::array<std::array<std::int64_t, MaxN>, MaxN> weight{};
    std::array<std::int64_t, MaxN> incoming{}, accumulated{}, threshold{}, round{};
    std::array<std::size_t, MaxN> current{}, next{};
    for (std::size_t i = 0; i < seed_count; ++i) {
        const auto id = input[seed_offset + i];
        if (id < 0 || static_cast<std::uint64_t>(id) >= n || seeded[static_cast<std::size_t>(id)]) return -1;
        seeded[static_cast<std::size_t>(id)] = true;
    }
    for (std::size_t i = 0; i < m; ++i) {
        const auto u = input[edge_offset + 3 * i], v = input[edge_offset + 3 * i + 1], w = input[edge_offset + 3 * i + 2];
        if (u < 0 || static_cast<std::uint64_t>(u) >= n || v < 0 || static_cast<std::uint64_t>(v) >= n ||
            u == v || w < 0 || w > 16 || seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]) return -1;
        seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = true;
        weight[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = w;
        incoming[static_cast<std::size_t>(v)] += w;
        if (incoming[static_cast<std::size_t>(v)] > 16) return -1;
    }
    for (std::size_t v = 0; v < n; ++v) {
        threshold[v] = input[threshold_offset + v];
        if (threshold[v] < 1 || threshold[v] > 16) return -1;
        round[v] = seeded[v] ? 0 : -1;
    }
    const auto bytes = 8 * (n + 2);
    if (output == nullptr || capacity < bytes) return -2;

    std::size_t current_count = 0;
    for (std::size_t v = 0; v < n; ++v) if (seeded[v]) current[current_count++] = v;
    std::int64_t wave = 0;
    while (current_count != 0) {
        std::size_t next_count = 0;
        for (std::size_t i = 0; i < current_count; ++i) {
            const auto source = current[i];
            for (std::size_t target = 0; target < n; ++target) {
                if (round[target] >= 0 || weight[source][target] == 0) continue;
                accumulated[target] += weight[source][target];
                if (accumulated[target] >= threshold[target]) {
                    round[target] = wave + 1;
                    next[next_count++] = target;
                }
            }
        }
        current_count = next_count;
        current = next;
        if (next_count != 0) ++wave;
    }
    store_i64_le(output, 0, n_raw);
    store_i64_le(output, 8, wave);
    for (std::size_t v = 0; v < n; ++v) store_i64_le(output, 8 * (v + 2), round[v]);
    return static_cast<std::int64_t>(bytes);
}
