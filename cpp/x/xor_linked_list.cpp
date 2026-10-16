#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}

extern "C" std::int64_t xor_linked_list(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > 64) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < std::numeric_limits<std::int32_t>::min() ||
            input[i + 1] > std::numeric_limits<std::int32_t>::max()) return -1;
    }
    const std::size_t needed = 8 + 8 * count;
    if (output == nullptr || capacity < needed) return -2;

    std::int64_t node_values[65]{};
    std::size_t both[65]{};
    std::size_t tail = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto node_id = i + 1;
        node_values[node_id] = input[i + 1];
        both[node_id] = tail;
        if (tail != 0) both[tail] ^= node_id;
        tail = node_id;
    }
    write_i64_le(output, 0, count_value);
    std::size_t out = 8, previous = 0, current = count == 0 ? 0 : 1;
    while (current != 0) {
        write_i64_le(output, out, node_values[current]);
        out += 8;
        const auto next = previous ^ both[current];
        previous = current;
        current = next;
    }
    return static_cast<std::int64_t>(needed);
}
