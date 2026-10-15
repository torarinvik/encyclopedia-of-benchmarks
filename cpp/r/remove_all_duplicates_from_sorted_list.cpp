/* Recursively unlink every node in a repeated-value run. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_nodes = 1024; }

static std::size_t remove_duplicate_runs(const std::int64_t *input, std::size_t *next_node,
                                         std::size_t node, std::size_t none) noexcept {
    if (node == none) return none;
    const auto next = next_node[node];
    if (next != none && input[node] == input[next]) {
        const auto duplicate = input[node];
        auto after_run = next;
        while (after_run != none && input[after_run] == duplicate)
            after_run = next_node[after_run];
        return remove_duplicate_runs(input, next_node, after_run, none);
    }
    next_node[node] = remove_duplicate_runs(input, next_node, next, none);
    return node;
}

extern "C" std::int64_t remove_all_duplicates_from_sorted_list(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_nodes || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = input[index];
        if (value < INT32_MIN || value > INT32_MAX
            || (index != 0 && input[index - 1] > value)) return -1;
    }
    std::size_t next_node[max_nodes + 1];
    for (std::size_t index = 0; index < length; ++index) next_node[index] = index + 1;
    next_node[length] = length;
    const auto head = remove_duplicate_runs(input, next_node, 0, length);
    std::size_t survivor_count = 0;
    for (auto node = head; node != length; node = next_node[node]) ++survivor_count;
    const auto output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (auto node = head; node != length; node = next_node[node]) {
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[node]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? static_cast<std::int64_t>(written) : -1;
}
