/* Build a height-balanced BST from a sorted linked-list value sequence and serialize it. */
#include <cstddef>
#include <cstdint>
#include <limits>

static std::size_t emit_tree(const std::int64_t *values, std::size_t start,
                             std::size_t end, std::uint8_t *output,
                             std::size_t position)
{
    if (start == end) { output[position] = 0; return position + 1; }
    auto middle = start;
    auto fast = start;
    while (fast < end && fast + 1 < end) { fast += 2; ++middle; }
    output[position++] = 1;
    const auto encoded = static_cast<std::uint32_t>(static_cast<std::int32_t>(values[middle]));
    output[position++] = static_cast<std::uint8_t>(encoded);
    output[position++] = static_cast<std::uint8_t>(encoded >> 8);
    output[position++] = static_cast<std::uint8_t>(encoded >> 16);
    output[position++] = static_cast<std::uint8_t>(encoded >> 24);
    position = emit_tree(values, start, middle, output, position);
    return emit_tree(values, middle + 1, end, output, position);
}

extern "C" std::int64_t sorted_list_to_bst(const std::int64_t *values,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept
{
    if (length > 64) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < std::numeric_limits<std::int32_t>::min() ||
            values[index] > std::numeric_limits<std::int32_t>::max() ||
            (index > 0 && values[index - 1] > values[index])) return -1;
    }
    const auto required = 6 * length + 1;
    if (output_capacity < required || output == nullptr) return -2;
    (void)emit_tree(values, 0, length, output, 0);
    return static_cast<std::int64_t>(length);
}
