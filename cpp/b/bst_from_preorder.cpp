/* Validate and serialize a strict BST reconstructed from preorder values. */
#include <cstddef>
#include <cstdint>

static bool valid_preorder(const std::int64_t *values, std::size_t start, std::size_t end,
                          std::int64_t lower, std::int64_t upper)
{
    if (start == end) return true;
    const auto root = values[start];
    if (root <= lower || root >= upper) return false;
    auto split = start + 1;
    while (split < end && values[split] < root) ++split;
    return valid_preorder(values, start + 1, split, lower, root) &&
           valid_preorder(values, split, end, root, upper);
}

static std::size_t emit_preorder_tree(const std::int64_t *values, std::size_t start,
                                      std::size_t end, std::uint8_t *output,
                                      std::size_t position)
{
    if (start == end) { output[position] = 0; return position + 1; }
    const auto root = values[start];
    auto split = start + 1;
    while (split < end && values[split] < root) ++split;
    output[position++] = 1;
    const auto encoded = static_cast<std::uint32_t>(static_cast<std::int32_t>(root));
    output[position++] = static_cast<std::uint8_t>(encoded & 255u);
    output[position++] = static_cast<std::uint8_t>((encoded >> 8) & 255u);
    output[position++] = static_cast<std::uint8_t>((encoded >> 16) & 255u);
    output[position++] = static_cast<std::uint8_t>(encoded >> 24);
    position = emit_preorder_tree(values, start + 1, split, output, position);
    return emit_preorder_tree(values, split, end, output, position);
}

extern "C" std::int64_t bst_from_preorder(const std::int64_t *values,
                                           std::size_t length,
                                           std::uint8_t *output,
                                           std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 15) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    if (!valid_preorder(values, 0, length, static_cast<std::int64_t>(INT32_MIN) - 1,
                        static_cast<std::int64_t>(INT32_MAX) + 1)) return -1;
    const auto required = 6 * length + 1;
    if (output_capacity < required || output == nullptr) return -2;
    (void)emit_preorder_tree(values, 0, length, output, 0);
    return static_cast<std::int64_t>(length);
}
