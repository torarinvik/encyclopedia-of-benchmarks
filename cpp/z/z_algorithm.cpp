/* Emit the Rust z_array convention: z[0] is zero and later entries are prefix lengths. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t z_algorithm(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output,
                                     std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > 2048) return -1;
    if (input[0] < 0 || input[0] > 2047) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    const auto output_bytes = count * 4;
    if (output_capacity < output_bytes || (count != 0 && output == nullptr)) return -2;

    std::size_t z[2047]{};
    std::size_t left = 0, right = 0;
    for (std::size_t index = 1; index < count; ++index) {
        if (index < right) {
            const auto reused = z[index - left];
            const auto remaining = right - index;
            z[index] = reused < remaining ? reused : remaining;
        }
        while (index + z[index] < count && input[1 + z[index]] == input[1 + index + z[index]]) ++z[index];
        if (index + z[index] > right) {
            left = index;
            right = index + z[index];
        }
    }
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = static_cast<std::uint32_t>(z[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
    }
    return static_cast<std::int64_t>(count);
}
