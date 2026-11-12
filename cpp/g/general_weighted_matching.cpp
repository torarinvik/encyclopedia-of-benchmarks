#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
constexpr std::size_t kMaxStates = std::size_t{1} << kMaxN;
constexpr std::size_t kMaxInputValues = 2 + 3 * (kMaxN * (kMaxN - 1) / 2) + 1;
constexpr std::int64_t kMaxWeight = 1'000'000;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t general_weighted_matching(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > kMaxN || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2) return -1;
    const int n = static_cast<int>(n_value), m = static_cast<int>(m_value);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;

    std::int64_t weight[kMaxN][kMaxN]{};
    bool present[kMaxN][kMaxN]{};
    std::size_t cursor = 2;
    for (int edge = 0; edge < m; ++edge) {
        const auto u_value = input[cursor++];
        const auto v_value = input[cursor++];
        const auto edge_weight = input[cursor++];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n ||
            u_value == v_value || edge_weight < 1 || edge_weight > kMaxWeight) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        if (present[u][v]) return -1;
        present[u][v] = present[v][u] = true;
        weight[u][v] = weight[v][u] = edge_weight;
    }

    std::int64_t dp[kMaxStates]{};
    const std::size_t state_count = std::size_t{1} << n;
    for (std::size_t mask = 1; mask < state_count; ++mask) {
        const std::size_t bit = mask & (~mask + 1);
        int vertex = 0;
        while ((bit >> vertex) != 1) ++vertex;
        const std::size_t remainder = mask ^ bit;
        dp[mask] = dp[remainder];
        for (int partner = vertex + 1; partner < n; ++partner) {
            const std::size_t partner_bit = std::size_t{1} << partner;
            if ((remainder & partner_bit) == 0 || !present[vertex][partner]) continue;
            const auto candidate = weight[vertex][partner] + dp[remainder ^ partner_bit];
            if (candidate > dp[mask]) dp[mask] = candidate;
        }
    }

    std::int64_t output_words[2 + kMaxN];
    int pair_count = 0;
    std::size_t mask = state_count - 1;
    while (mask != 0) {
        const std::size_t bit = mask & (~mask + 1);
        int vertex = 0;
        while ((bit >> vertex) != 1) ++vertex;
        const std::size_t remainder = mask ^ bit;
        if (dp[mask] == dp[remainder]) {
            mask = remainder;
            continue;
        }
        int selected = -1;
        for (int partner = vertex + 1; partner < n; ++partner) {
            const std::size_t partner_bit = std::size_t{1} << partner;
            if ((remainder & partner_bit) != 0 && present[vertex][partner] &&
                weight[vertex][partner] + dp[remainder ^ partner_bit] == dp[mask]) {
                selected = partner;
                break;
            }
        }
        if (selected < 0) return -1;
        output_words[2 + 2 * pair_count] = vertex;
        output_words[3 + 2 * pair_count] = selected;
        ++pair_count;
        mask = remainder ^ (std::size_t{1} << selected);
    }

    output_words[0] = pair_count;
    output_words[1] = dp[state_count - 1];
    const std::size_t output_bytes = static_cast<std::size_t>(2 + 2 * pair_count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < static_cast<std::size_t>(2 + 2 * pair_count); ++word)
        store_i64_le(output, 8 * word, output_words[word]);
    return static_cast<std::int64_t>(output_bytes);
}
