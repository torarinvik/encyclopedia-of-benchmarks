#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 128;
constexpr std::size_t max_parseable_input_length = 183;
constexpr std::uint64_t fnv_offset_basis = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);
constexpr std::uint64_t mask_63 = UINT64_C(0x7fffffffffffffff);
}

extern "C" std::int64_t mono_alphabetic_cipher(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const std::int64_t operation = input[0], raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto text_length = static_cast<std::size_t>(raw_text_length);
    if (length != 54 + text_length) return -1;

    bool key_seen[26]{}, alphabet_seen[26]{};
    std::uint8_t key_inverse[26]{}, alphabet_inverse[26]{};
    for (std::size_t i = 0; i < 26; ++i) {
        const auto key_value = input[2 + i], alphabet_value = input[28 + i];
        if (key_value < 'A' || key_value > 'Z' || alphabet_value < 'A' || alphabet_value > 'Z') return -1;
        const auto key_index = static_cast<std::size_t>(key_value - 'A');
        const auto alphabet_index = static_cast<std::size_t>(alphabet_value - 'A');
        if (key_seen[key_index] || alphabet_seen[alphabet_index]) return -1;
        key_seen[key_index] = true; alphabet_seen[alphabet_index] = true;
        key_inverse[key_index] = static_cast<std::uint8_t>(i);
        alphabet_inverse[alphabet_index] = static_cast<std::uint8_t>(i);
    }
    std::size_t output_length = 0;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[54 + i];
        if (value == ' ' || (value >= '0' && value <= '9') ||
            (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) {
            if (value < '0' || value > '9') ++output_length;
        } else return -1;
    }

    std::uint64_t hash = fnv_offset_basis;
    const auto length_word = static_cast<std::uint64_t>(output_length);
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ static_cast<std::uint8_t>(length_word >> (8 * byte))) * fnv_prime;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[54 + i];
        if (value >= '0' && value <= '9') continue;
        std::uint8_t mapped;
        if (value == ' ') mapped = static_cast<std::uint8_t>(value);
        else {
            const bool lower = value >= 'a' && value <= 'z';
            const auto letter = static_cast<std::size_t>(lower ? value - 'a' : value - 'A');
            const auto index = operation == 0 ? alphabet_inverse[letter] : key_inverse[letter];
            const auto target = operation == 0 ? input[2 + index] : input[28 + index];
            mapped = static_cast<std::uint8_t>(lower ? target + ('a' - 'A') : target);
        }
        hash = (hash ^ mapped) * fnv_prime;
    }
    return static_cast<std::int64_t>(hash & mask_63);
}
