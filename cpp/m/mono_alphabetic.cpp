#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 256;
constexpr std::size_t max_parseable_input_length = 28 + max_text_length + 1;
constexpr std::uint64_t fnv_offset_basis = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);
constexpr std::uint64_t mask_63 = UINT64_C(0x7fffffffffffffff);
}

extern "C" std::int64_t mono_alphabetic(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const std::int64_t operation = input[0];
    const std::int64_t raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 1
        || raw_text_length > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto text_length = static_cast<std::size_t>(raw_text_length);
    if (length != 28 + text_length) return -1;

    bool seen[26]{};
    std::uint8_t inverse[26]{};
    for (std::size_t i = 0; i < 26; ++i) {
        const auto value = input[2 + i];
        if (value < 'A' || value > 'Z') return -1;
        const auto index = static_cast<std::size_t>(value - 'A');
        if (seen[index]) return -1;
        seen[index] = true;
        inverse[index] = static_cast<std::uint8_t>(i);
    }
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[28 + i] < 'A' || input[28 + i] > 'Z') return -1;

    std::uint64_t hash = fnv_offset_basis;
    const std::uint64_t length_word = static_cast<std::uint64_t>(text_length);
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ static_cast<std::uint8_t>(length_word >> (8 * byte))) * fnv_prime;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto index = static_cast<std::size_t>(input[28 + i] - 'A');
        const auto mapped = operation == 0
            ? static_cast<std::uint8_t>(input[2 + index])
            : static_cast<std::uint8_t>('A' + inverse[index]);
        hash = (hash ^ mapped) * fnv_prime;
    }
    return static_cast<std::int64_t>(hash & mask_63);
}
