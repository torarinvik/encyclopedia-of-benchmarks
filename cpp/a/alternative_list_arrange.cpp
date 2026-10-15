#include <cstddef>
#include <cstdint>

extern "C" int64_t alternative_list_arrange(const int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 64) return -1;
    const std::size_t a = static_cast<std::size_t>(input[0]);
    if (1 + a >= length || input[1 + a] < 0 || input[1 + a] > 64) return -1;
    const std::size_t b = static_cast<std::size_t>(input[1 + a]);
    if (length != 2 + a + b) return -1;
    const std::size_t count = a + b;
    if (capacity < count * 8 || (count != 0 && output == nullptr)) return -2;
    std::size_t out = 0;
    for (std::size_t i = 0; i < a || i < b; ++i) {
        for (std::size_t side = 0; side < 2; ++side) {
            if ((side == 0 && i < a) || (side == 1 && i < b)) {
                const std::uint64_t v = static_cast<std::uint64_t>(input[side == 0 ? 1 + i : 2 + a + i]);
                for (std::size_t j = 0; j < 8; ++j) output[out++] = static_cast<std::uint8_t>(v >> (8 * j));
            }
        }
    }
    return static_cast<std::int64_t>(count);
}
