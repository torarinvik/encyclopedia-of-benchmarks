#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cyclic_sort(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    constexpr std::size_t max_length = 1024;
    if (length > max_length || (length > 0 && values == nullptr)) return -1;
    std::array<bool, max_length + 1> seen{};
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 1 || value > static_cast<std::int64_t>(length) || seen[static_cast<std::size_t>(value)])
            return -1;
        seen[static_cast<std::size_t>(value)] = true;
    }

    std::array<std::int64_t, max_length> sorted{};
    for (std::size_t index = 0; index < length; ++index) sorted[index] = values[index];
    std::size_t index = 0;
    while (index < length) {
        const std::size_t destination = static_cast<std::size_t>(sorted[index] - 1);
        if (destination == index) {
            ++index;
        } else {
            const std::int64_t temporary = sorted[index];
            sorted[index] = sorted[destination];
            sorted[destination] = temporary;
        }
    }

    const std::size_t output_length = length * 8;
    if (output_length > output_capacity || (output_length > 0 && output == nullptr)) return -2;
    for (std::size_t item = 0; item < length; ++item) {
        const std::uint64_t bits = static_cast<std::uint64_t>(sorted[item]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[item * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(length);
}
