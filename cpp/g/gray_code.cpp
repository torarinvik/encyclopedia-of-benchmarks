// Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gray_code(const std::int64_t *input, std::size_t input_length,
                                   std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length != 1 || input[0] < 0 || input[0] > 13) return -1;
    const auto bits = static_cast<unsigned>(input[0]);
    const std::size_t count = bits == 0 ? 0 : (std::size_t{1} << bits);
    const std::size_t required = count * 4;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = static_cast<std::uint32_t>(index ^ (index >> 1));
        for (unsigned byte = 0; byte < 4; ++byte)
            output[4 * index + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
    }
    return static_cast<std::int64_t>(count);
}
