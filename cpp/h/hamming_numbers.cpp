/* Emit the first n positive 5-smooth numbers as little-endian i64 values. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hamming_numbers(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output,
                                         std::size_t output_capacity) noexcept
{
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > 32) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    const auto output_bytes = count * 8;
    if (output_capacity < output_bytes || output == nullptr) return -2;

    std::uint64_t values[32]{};
    values[0] = 1;
    std::size_t i2 = 0, i3 = 0, i5 = 0;
    for (std::size_t index = 1; index < count; ++index) {
        const auto c2 = values[i2] * 2;
        const auto c3 = values[i3] * 3;
        const auto c5 = values[i5] * 5;
        auto next = c2 < c3 ? c2 : c3;
        if (c5 < next) next = c5;
        values[index] = next;
        if (c2 == next) ++i2;
        if (c3 == next) ++i3;
        if (c5 == next) ++i5;
    }
    for (std::size_t index = 0; index < count; ++index) {
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(values[index] >> (byte * 8));
    }
    return static_cast<std::int64_t>(count);
}
