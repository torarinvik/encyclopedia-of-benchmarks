/* Exact subset DP for minimum directed feedback arc set. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 8;
constexpr std::size_t max_edges = 56;
constexpr std::size_t max_length = 114;
constexpr std::size_t max_states = 256;
constexpr std::int64_t infinity = INT64_MAX / 4;
}

extern "C" std::int64_t minimum_directed_feedback_arc_set(const std::int64_t *input,
                                                           std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length + 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edges = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edges) return -1;

    std::uint16_t outgoing[max_vertices]{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto tail_value = input[2 + 2 * edge];
        const auto head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 ||
            static_cast<std::uint64_t>(tail_value) >= vertices ||
            static_cast<std::uint64_t>(head_value) >= vertices || tail_value == head_value) return -1;
        const auto tail = static_cast<std::size_t>(tail_value);
        const auto head = static_cast<std::size_t>(head_value);
        const auto bit = static_cast<std::uint16_t>(1u << head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    const auto full = (std::size_t{1} << vertices) - 1;
    std::int64_t dp[max_states];
    for (auto &value : dp) value = infinity;
    dp[0] = 0;
    for (std::size_t prefix = 0; prefix <= full; ++prefix) {
        if (dp[prefix] == infinity) continue;
        for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
            const auto bit = std::size_t{1} << vertex;
            if ((prefix & bit) != 0) continue;
            std::int64_t backward = 0;
            for (std::size_t prior = 0; prior < vertices; ++prior)
                if ((prefix & (std::size_t{1} << prior)) != 0 &&
                    (outgoing[vertex] & (std::uint16_t{1} << prior)) != 0) ++backward;
            const auto target = prefix | bit;
            const auto candidate = dp[prefix] + backward;
            if (candidate < dp[target]) dp[target] = candidate;
        }
    }
    return dp[full];
}
