/* Add the minimum prefix needed to make a printable ASCII string a palindrome. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t shortest_palindrome(const std::int64_t *input,
                                              std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t output_capacity) noexcept
{
    if (length > 64 || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] < 32 || input[i] > 126) return -1;
    if (length == 0) return 0;

    std::size_t suffix[64]{};
    for (std::size_t i = 1; i < length; ++i) {
        std::size_t matched = suffix[i - 1];
        while (matched > 0 && input[matched] != input[i]) matched = suffix[matched - 1];
        if (input[matched] == input[i]) ++matched;
        suffix[i] = matched;
    }

    std::size_t prefix_match = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t reversed_value = input[length - 1 - i];
        while (prefix_match > 0 && reversed_value != input[prefix_match])
            prefix_match = suffix[prefix_match - 1];
        if (reversed_value == input[prefix_match]) ++prefix_match;
    }

    const std::size_t output_length = 2 * length - prefix_match;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < length; ++i)
        output[i] = static_cast<std::uint8_t>(input[length - 1 - i]);
    for (std::size_t i = prefix_match; i < length; ++i)
        output[length + i - prefix_match] = static_cast<std::uint8_t>(input[i]);
    return static_cast<std::int64_t>(output_length);
}
