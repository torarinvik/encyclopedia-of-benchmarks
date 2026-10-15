// Polygon existence from side lengths (the strict polygon inequality).
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t check_polygon(const std::int64_t *values,
                                      std::size_t length,
                                      std::uint8_t *output,
                                      std::size_t output_capacity) noexcept {
    (void)output;
    (void)output_capacity;
    if (values == nullptr || length < 3 || length > 256) return -1;

    std::int64_t total = 0;
    std::int64_t largest = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t side = values[index];
        if (side < 1 || side > 1000000000) return -1;
        total += side;
        if (side > largest) largest = side;
    }
    return largest < total - largest ? 1 : 0;
}
