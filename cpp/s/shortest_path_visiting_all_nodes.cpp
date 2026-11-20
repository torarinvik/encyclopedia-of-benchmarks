// Minimum walk length covering all vertices via multi-source product BFS.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 10;
constexpr std::size_t max_states = 10240;
constexpr std::size_t max_parseable_length = 93;
}

extern "C" std::int64_t shortest_path_visiting_all_nodes(
    const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 2 || length > max_parseable_length) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || m_value < 0 || m_value > 45) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (m > n * (n - 1) / 2 || length != 2 + 2 * m) return -1;

    std::uint16_t adjacency[max_n]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 2 * edge];
        const auto v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        const auto u_bit = static_cast<std::uint16_t>(1u << v);
        const auto v_bit = static_cast<std::uint16_t>(1u << u);
        if ((adjacency[u] & u_bit) != 0) return -1;
        adjacency[u] |= u_bit;
        adjacency[v] |= v_bit;
    }

    std::uint16_t reached = 1u;
    for (;;) {
        const auto previous = reached;
        for (std::size_t v = 0; v < n; ++v)
            if ((reached & static_cast<std::uint16_t>(1u << v)) != 0) reached |= adjacency[v];
        if (reached == previous) break;
    }
    const auto full = static_cast<std::uint16_t>((1u << n) - 1u);
    if (reached != full) return -1;

    std::int16_t distance[max_states];
    std::uint16_t queue[max_states];
    const auto state_count = (std::size_t{1} << n) * n;
    for (std::size_t i = 0; i < state_count; ++i) distance[i] = -1;
    std::size_t head = 0, tail = 0;
    for (std::size_t start = 0; start < n; ++start) {
        const auto mask = std::size_t{1} << start;
        const auto state = mask * n + start;
        distance[state] = 0;
        queue[tail++] = static_cast<std::uint16_t>(state);
    }
    while (head < tail) {
        const auto state = static_cast<std::size_t>(queue[head++]);
        const auto mask = state / n;
        const auto vertex = state % n;
        if (mask == full) return distance[state];
        for (std::size_t next = 0; next < n; ++next) {
            if ((adjacency[vertex] & static_cast<std::uint16_t>(1u << next)) == 0) continue;
            const auto next_mask = mask | (std::size_t{1} << next);
            const auto next_state = next_mask * n + next;
            if (distance[next_state] >= 0) continue;
            distance[next_state] = static_cast<std::int16_t>(distance[state] + 1);
            queue[tail++] = static_cast<std::uint16_t>(next_state);
        }
    }
    return -1;
}
