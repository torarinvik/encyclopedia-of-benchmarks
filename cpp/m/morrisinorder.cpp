#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 63;
constexpr std::size_t max_parseable_input_length = 65;

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

// Bounded Morris inorder traversal over a complete level-order tree.
extern "C" std::int64_t morrisinorder(const std::int64_t *values,
                                       std::size_t length,
                                       std::uint8_t *output,
                                       std::size_t capacity) {
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    const auto raw_count = values[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_node_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    if (length != count + 1) return -1;
    for (std::size_t index = 0; index < count; ++index)
        if (values[index + 1] < -2147483648LL || values[index + 1] > 2147483647LL) return -1;

    const auto byte_count = 4 * count;
    if (output == nullptr || capacity < byte_count) return -2;

    int left[max_node_count];
    int right[max_node_count];
    for (std::size_t index = 0; index < count; ++index) {
        const auto left_index = 2 * index + 1;
        const auto right_index = 2 * index + 2;
        left[index] = left_index < count ? static_cast<int>(left_index) : -1;
        right[index] = right_index < count ? static_cast<int>(right_index) : -1;
    }

    int current = count == 0 ? -1 : 0;
    std::size_t written = 0;
    while (current >= 0) {
        if (left[current] < 0) {
            store_i32_le(output, 4 * written, static_cast<std::int32_t>(values[1 + current]));
            ++written;
            current = right[current];
        } else {
            int predecessor = left[current];
            while (right[predecessor] >= 0 && right[predecessor] != current)
                predecessor = right[predecessor];
            if (right[predecessor] < 0) {
                right[predecessor] = current;
                current = left[current];
            } else {
                right[predecessor] = -1;
                store_i32_le(output, 4 * written, static_cast<std::int32_t>(values[1 + current]));
                ++written;
                current = right[current];
            }
        }
    }
    return static_cast<std::int64_t>(byte_count);
}
