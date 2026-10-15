// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t digit_separation(const std::int64_t *input,
                                          std::size_t input_length,
                                          std::uint8_t *output,
                                          std::size_t output_capacity)
{
    if (input == nullptr || input_length != 2 || (input[1] != 0 && input[1] != 1)) return -1;
    auto remaining = input[0];
    std::uint8_t digits[20];
    std::size_t count = 0;
    if (remaining == 0) digits[count++] = 0;
    while (remaining != 0) {
        const auto remainder = remaining % 10;
        digits[count++] = static_cast<std::uint8_t>(remainder < 0 ? -remainder : remainder);
        remaining /= 10;
    }
    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto source = input[1] == 0 ? index : count - index - 1;
        output[index] = digits[source];
    }
    return static_cast<std::int64_t>(count);
}
