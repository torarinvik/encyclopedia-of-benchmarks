#include <cstddef>
#include <cstdint>

extern "C" int64_t cupif_giannini_tree_traversal(const int64_t *input,
                                                  std::size_t length,
                                                  std::uint8_t *output,
                                                  std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 3) return -1;
    if (length != 2) return -1;

    const auto height = input[0];
    const auto key_value = input[1];
    if (height < 0 || height > 6) return -1;
    const std::uint64_t leaf_count = std::uint64_t{1} << height;
    if (key_value < 0 || static_cast<std::uint64_t>(key_value) >= leaf_count) return -1;
    if (output == nullptr || capacity < leaf_count) return -2;

    for (std::uint64_t count = 0; count < leaf_count; ++count) {
        const auto path = count ^ static_cast<std::uint64_t>(key_value);
        std::uint8_t leaf_code = 0;
        for (std::uint64_t depth = 0; depth < static_cast<std::uint64_t>(height); ++depth) {
            if (((path >> depth) & 1U) != 0) {
                leaf_code |= static_cast<std::uint8_t>(1U << depth);
            }
        }
        output[count] = leaf_code;
    }
    return static_cast<std::int64_t>(leaf_count);
}
