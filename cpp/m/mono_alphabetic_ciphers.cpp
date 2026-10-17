#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 128;
constexpr std::size_t max_parseable_input_length = 157;
constexpr std::uint64_t fnv_offset_basis = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);
constexpr std::uint64_t mask_63 = UINT64_C(0x7fffffffffffffff);
}

extern "C" std::int64_t mono_alphabetic_ciphers(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const auto operation = input[0], raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > static_cast<std::int64_t>(max_text_length)) return -1;
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
        if (input[28 + i] < 32 || input[28 + i] > 126) return -1;

    std::uint64_t hash = fnv_offset_basis;
    const auto length_word = static_cast<std::uint64_t>(text_length);
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ static_cast<std::uint8_t>(length_word >> (8 * byte))) * fnv_prime;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[28 + i];
        std::uint8_t mapped = static_cast<std::uint8_t>(value);
        if ((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) {
            const bool lower = value >= 'a' && value <= 'z';
            const auto letter = static_cast<std::size_t>(lower ? value - 'a' : value - 'A');
            const auto position = operation == 0 ? inverse[letter] : letter;
            const auto target = operation == 0 ? 'A' + position : input[2 + position];
            mapped = static_cast<std::uint8_t>(lower ? target + ('a' - 'A') : target);
        }
        hash = (hash ^ mapped) * fnv_prime;
    }
    return static_cast<std::int64_t>(hash & mask_63);
}
