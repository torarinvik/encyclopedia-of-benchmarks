#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_m = max_n * (max_n - 1) / 2;
constexpr std::size_t max_input_values = 2 + 2 * max_m;
constexpr std::size_t max_output_values = 1 + 2 * max_n;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t connected_components_of_complement_graph(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) || m_value < 0 ||
        m_value > n_value * (n_value - 1) / 2) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + 2 * m) return -1;

    std::array<std::uint64_t, max_n> graph{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto left_value = input[2 + 2 * edge];
        const auto right_value = input[3 + 2 * edge];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const auto left = static_cast<std::size_t>(left_value);
        const auto right = static_cast<std::size_t>(right_value);
        const auto left_bit = std::uint64_t{1} << right;
        if ((graph[left] & left_bit) != 0) return -1;
        graph[left] |= left_bit;
        graph[right] |= std::uint64_t{1} << left;
    }

    std::array<std::size_t, max_n> remaining{}, queue{};
    std::array<std::int64_t, max_n> label{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        remaining[vertex] = vertex;
        label[vertex] = -1;
    }
    auto remaining_count = n;
    std::size_t component_count = 0;
    while (remaining_count > 0) {
        const auto root = remaining[--remaining_count];
        label[root] = static_cast<std::int64_t>(component_count);
        std::size_t head = 0, tail = 0;
        queue[tail++] = root;
        while (head < tail) {
            const auto vertex = queue[head++];
            std::size_t position = 0;
            while (position < remaining_count) {
                const auto candidate = remaining[position];
                if (((graph[vertex] >> candidate) & 1u) != 0) {
                    ++position;
                } else {
                    remaining[position] = remaining[--remaining_count];
                    label[candidate] = static_cast<std::int64_t>(component_count);
                    queue[tail++] = candidate;
                }
            }
        }
        ++component_count;
    }

    std::array<std::int64_t, max_output_values> staged{};
    std::size_t used = 0;
    staged[used++] = static_cast<std::int64_t>(component_count);
    std::array<bool, max_n> emitted{};
    for (std::size_t first = 0; first < n; ++first) {
        const auto component = static_cast<std::size_t>(label[first]);
        if (emitted[component]) continue;
        emitted[component] = true;
        std::size_t component_size = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (static_cast<std::size_t>(label[vertex]) == component) ++component_size;
        staged[used++] = static_cast<std::int64_t>(component_size);
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (static_cast<std::size_t>(label[vertex]) == component)
                staged[used++] = static_cast<std::int64_t>(vertex);
    }

    const auto required = 8 * used;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < used; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return static_cast<std::int64_t>(required);
}
