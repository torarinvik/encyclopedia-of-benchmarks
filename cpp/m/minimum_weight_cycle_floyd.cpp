#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 9;
constexpr std::size_t kMaxInputLength = 111;
constexpr std::int64_t kInf = INT64_C(1) << 60;

void store_i64_le(std::uint8_t* output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t minimum_weight_cycle_floyd(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > static_cast<std::int64_t>(kMaxN)
            || m_value < 0 || m_value > n_value * (n_value - 1) / 2) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + 3 * m) return -1;

    std::array<std::array<std::int64_t, kMaxN>, kMaxN> edge{};
    std::array<std::array<std::int64_t, kMaxN>, kMaxN> dist{};
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j) edge[i][j] = i == j ? 0 : kInf;
    for (std::size_t e = 0; e < m; ++e) {
        const auto offset = 2 + 3 * e;
        const auto u_value = input[offset], v_value = input[offset + 1];
        const auto weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value || weight < 1 || weight > 1000) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        if (edge[u][v] != kInf) return -1;
        edge[u][v] = edge[v][u] = weight;
    }
    if (output == nullptr || capacity < 8) return -2;
    dist = edge;

    auto best = kInf;
    for (std::size_t k = 0; k < n; ++k) {
        for (std::size_t i = 0; i < k; ++i) {
            if (edge[i][k] == kInf) continue;
            for (std::size_t j = i + 1; j < k; ++j) {
                if (edge[k][j] == kInf || dist[i][j] == kInf) continue;
                const auto candidate = edge[i][k] + edge[k][j] + dist[i][j];
                if (candidate < best) best = candidate;
            }
        }
        for (std::size_t i = 0; i < n; ++i) {
            if (dist[i][k] == kInf) continue;
            for (std::size_t j = 0; j < n; ++j) {
                if (dist[k][j] == kInf) continue;
                const auto candidate = dist[i][k] + dist[k][j];
                if (candidate < dist[i][j]) dist[i][j] = candidate;
            }
        }
    }
    store_i64_le(output, best == kInf ? -1 : best);
    return 8;
}
