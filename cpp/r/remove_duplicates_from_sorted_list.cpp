/* Unlink later nodes with the same value in a sorted indexed list. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_nodes = 1024; }

extern "C" std::int64_t remove_duplicates_from_sorted_list(const std::int64_t *input,
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
    std::size_t current = 0;
    while (current != length && next_node[current] != length) {
        const auto next = next_node[current];
        if (input[current] == input[next]) next_node[current] = next_node[next];
        else current = next;
    }
    std::size_t survivor_count = 0;
    for (auto node = std::size_t(0); node != length; node = next_node[node]) ++survivor_count;
    const auto output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (auto node = std::size_t(0); node != length; node = next_node[node]) {
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[node]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
        ++written;
    }
    return written == survivor_count ? static_cast<std::int64_t>(written) : -1;
}
