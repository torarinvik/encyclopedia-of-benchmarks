/* Count cover arcs using non-reflexive transitive closure. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_m = 28;
constexpr std::size_t max_length = 58;
}

extern "C" std::int64_t dag_transitive_reduction(const std::int64_t *input,
                                                  std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length + 1) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::uint16_t outgoing[max_n]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto tail_value = input[2 + 2 * edge];
        const auto head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 ||
            static_cast<std::uint64_t>(tail_value) >= n ||
            static_cast<std::uint64_t>(head_value) >= n || tail_value == head_value) return -1;
        const auto tail = static_cast<std::size_t>(tail_value);
        const auto head = static_cast<std::size_t>(head_value);
        const auto bit = static_cast<std::uint16_t>(1u << head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    std::uint16_t reach[max_n]{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) reach[vertex] = outgoing[vertex];
    for (std::size_t middle = 0; middle < n; ++middle) {
        const auto middle_bit = static_cast<std::uint16_t>(1u << middle);
        for (std::size_t source = 0; source < n; ++source)
            if ((reach[source] & middle_bit) != 0) reach[source] |= reach[middle];
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        if ((reach[vertex] & static_cast<std::uint16_t>(1u << vertex)) != 0) return -1;

    std::int64_t retained = 0;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto tail = static_cast<std::size_t>(input[2 + 2 * edge]);
        const auto head = static_cast<std::size_t>(input[3 + 2 * edge]);
        bool redundant = false;
        for (std::size_t middle = 0; middle < n; ++middle) {
            if (middle != tail && middle != head &&
                (outgoing[tail] & static_cast<std::uint16_t>(1u << middle)) != 0 &&
                (reach[middle] & static_cast<std::uint16_t>(1u << head)) != 0) {
                redundant = true;
                break;
            }
        }
        if (!redundant) ++retained;
    }
    return retained;
}
