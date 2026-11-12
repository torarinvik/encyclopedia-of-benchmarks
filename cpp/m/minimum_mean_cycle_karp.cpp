#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 16;
constexpr std::size_t kMaxInputLength = 51;
constexpr std::size_t kOutputBytes = 16;

struct Edge { std::size_t from; std::size_t to; std::int64_t weight; };

bool all_reachable(std::size_t n,
    const std::array<std::array<bool, kMaxVertices>, kMaxVertices> &adjacent,
    bool reverse)
{
    std::array<bool, kMaxVertices> seen{};
    std::array<std::size_t, kMaxVertices> queue{};
    std::size_t head = 0;
    std::size_t tail = 0;
    seen[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const auto u = queue[head++];
        for (std::size_t v = 0; v < n; ++v) {
            const bool has_edge = reverse ? adjacent[v][u] : adjacent[u][v];
            if (has_edge && !seen[v]) {
                seen[v] = true;
                queue[tail++] = v;
            }
        }
    }
    for (std::size_t v = 0; v < n; ++v) if (!seen[v]) return false;
    return true;
}

bool ratio_less(std::int64_t a_num, std::int64_t a_den,
                std::int64_t b_num, std::int64_t b_den) noexcept
{
    return a_num * b_den < b_num * a_den;
}

std::int64_t gcd_positive(std::int64_t a, std::int64_t b) noexcept
{
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t minimum_mean_cycle_karp(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxVertices)
        || input[1] < 1 || input[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (edge_count > n * n || length != 2 + 3 * edge_count) return -1;

    std::array<Edge, kMaxEdges> edges{};
    std::array<std::array<bool, kMaxVertices>, kMaxVertices> adjacent{};
    for (std::size_t i = 0; i < edge_count; ++i) {
        const auto from_value = input[2 + 3 * i];
        const auto to_value = input[3 + 3 * i];
        const auto weight = input[4 + 3 * i];
        if (from_value < 0 || from_value >= static_cast<std::int64_t>(n)
            || to_value < 0 || to_value >= static_cast<std::int64_t>(n)
            || weight < -1000 || weight > 1000) return -1;
        const auto from = static_cast<std::size_t>(from_value);
        const auto to = static_cast<std::size_t>(to_value);
        if (adjacent[from][to]) return -1;
        adjacent[from][to] = true;
        edges[i] = {from, to, weight};
    }
    if (!all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true)) return -1;
    if (output == nullptr || capacity < kOutputBytes) return -2;

    std::array<std::array<std::int64_t, kMaxVertices>, kMaxVertices + 1> cost{};
    std::array<std::array<bool, kMaxVertices>, kMaxVertices + 1> reachable{};
    reachable[0][0] = true;
    for (std::size_t path_length = 1; path_length <= n; ++path_length) {
        for (std::size_t e = 0; e < edge_count; ++e) {
            const auto edge = edges[e];
            if (!reachable[path_length - 1][edge.from]) continue;
            const auto candidate = cost[path_length - 1][edge.from] + edge.weight;
            if (!reachable[path_length][edge.to] || candidate < cost[path_length][edge.to]) {
                reachable[path_length][edge.to] = true;
                cost[path_length][edge.to] = candidate;
            }
        }
    }

    bool have_answer = false;
    std::int64_t answer_num = 0;
    std::int64_t answer_den = 1;
    for (std::size_t v = 0; v < n; ++v) {
        if (!reachable[n][v]) continue;
        bool have_local = false;
        std::int64_t local_num = 0;
        std::int64_t local_den = 1;
        for (std::size_t k = 0; k < n; ++k) {
            if (!reachable[k][v]) continue;
            const auto numerator = cost[n][v] - cost[k][v];
            const auto denominator = static_cast<std::int64_t>(n - k);
            if (!have_local || ratio_less(local_num, local_den, numerator, denominator)) {
                local_num = numerator;
                local_den = denominator;
                have_local = true;
            }
        }
        if (have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den))) {
            answer_num = local_num;
            answer_den = local_den;
            have_answer = true;
        }
    }
    if (!have_answer) return -1;
    const auto divisor = gcd_positive(answer_num < 0 ? -answer_num : answer_num, answer_den);
    answer_num /= divisor;
    answer_den /= divisor;
    std::array<std::uint8_t, kOutputBytes> staged{};
    store_i64_le(staged.data(), 0, answer_num);
    store_i64_le(staged.data(), 8, answer_den);
    for (std::size_t i = 0; i < kOutputBytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(kOutputBytes);
}
