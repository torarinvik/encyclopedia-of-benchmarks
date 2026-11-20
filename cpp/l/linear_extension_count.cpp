#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 12;
constexpr std::size_t max_length = 14;
constexpr std::size_t max_states = 1U << max_n;
}

extern "C" std::int64_t linear_extension_count(const std::int64_t *input,
                                                std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != n + 1) return -1;
    const auto full = (std::uint32_t{1} << n) - 1;
    std::uint32_t predecessor[max_n]{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        if (input[1 + vertex] < 0 || static_cast<std::uint64_t>(input[1 + vertex]) > full) return -1;
        predecessor[vertex] = static_cast<std::uint32_t>(input[1 + vertex]);
    }

    std::int64_t ways[max_states]{};
    ways[0] = 1;
    for (std::uint32_t prefix = 0; prefix <= full; ++prefix) {
        const auto count = ways[prefix];
        if (count == 0) continue;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            const auto bit = std::uint32_t{1} << vertex;
            if ((prefix & bit) == 0 && (predecessor[vertex] & prefix) == predecessor[vertex])
                ways[prefix | bit] += count;
        }
    }
    return ways[full];
}
