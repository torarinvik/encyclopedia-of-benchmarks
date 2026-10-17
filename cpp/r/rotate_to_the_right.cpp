#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_parseable_input_length = max_n + 4;
constexpr std::size_t max_output_bytes = 8 * max_n;
constexpr std::int64_t max_places = 1'000'000;
}

extern "C" std::int64_t rotate_to_the_right(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 3 || length > max_parseable_input_length) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t places = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        places < -max_places || places > max_places) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != n + 2) return -1;
    for (std::size_t index = 0; index < n; ++index)
        if (input[2 + index] < INT32_MIN || input[2 + index] > INT32_MAX) return -1;

    const std::int64_t remainder = places % n_value;
    const std::size_t shift = static_cast<std::size_t>(remainder < 0 ? remainder + n_value : remainder);
    const std::size_t output_bytes = n * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::uint8_t encoded[max_output_bytes];
    for (std::size_t index = 0; index < n; ++index) {
        const std::size_t source = (index + n - shift) % n;
        std::uint64_t bits = static_cast<std::uint64_t>(input[2 + source]);
        for (std::size_t byte = 0; byte < 8; ++byte) {
            encoded[index * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = encoded[index];
    return static_cast<std::int64_t>(output_bytes);
}
