#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hamming_distance_strings(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::int64_t max_string_length = 128;
    constexpr std::size_t max_input_length = 260;
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t left_length = input[0];
    const std::int64_t right_length = input[1];
    if (left_length < 0 || left_length > max_string_length || right_length < 0 || right_length > max_string_length) return -1;
    if (length != static_cast<std::size_t>(2 + left_length + right_length)) return -1;
    for (std::size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (left_length != right_length) return -1;
    std::int64_t distance = 0;
    for (std::int64_t i = 0; i < left_length; ++i) {
        if (input[2 + static_cast<std::size_t>(i)] != input[2 + static_cast<std::size_t>(left_length) + static_cast<std::size_t>(i)]) ++distance;
    }
    return distance;
}
