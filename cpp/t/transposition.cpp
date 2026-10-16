#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_key = 32;
constexpr std::size_t max_text = 512;
constexpr std::size_t max_input = 3 + max_key + max_text;
constexpr std::size_t max_padded = max_text + max_key;

bool ascii_letter(std::int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
std::int64_t hash_output(const std::uint8_t *text, std::size_t length) {
    std::uint64_t hash = UINT64_C(14695981039346656037);
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ ((static_cast<std::uint64_t>(length) >> (8 * byte)) & 255U)) * UINT64_C(1099511628211);
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint32_t codepoint = text[index];
        for (unsigned byte = 0; byte < 4; ++byte)
            hash = (hash ^ ((static_cast<std::uint64_t>(codepoint) >> (8 * byte)) & 255U)) * UINT64_C(1099511628211);
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
}

extern "C" std::int64_t transposition(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    const auto mode = input[0], key_length_value = input[1];
    if ((mode != 0 && mode != 1) || key_length_value < 1 || key_length_value > static_cast<std::int64_t>(max_key)) return -1;
    const auto key_length = static_cast<std::size_t>(key_length_value);
    const auto text_length_index = 2 + key_length;
    if (length <= text_length_index) return -1;
    const auto text_length_value = input[text_length_index];
    if (text_length_value < 1 || text_length_value > static_cast<std::int64_t>(max_text)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    if (length != text_length_index + 1 + text_length) return -1;

    std::uint8_t key[max_key]{}, sorted[max_key]{}, text[max_padded]{}, result[max_padded]{};
    for (std::size_t index = 0; index < key_length; ++index) {
        const auto value = input[2 + index];
        if (!ascii_letter(value)) return -1;
        auto ch = static_cast<std::uint8_t>(value);
        if (ch >= 'A' && ch <= 'Z') ch = static_cast<std::uint8_t>(ch + ('a' - 'A'));
        key[index] = sorted[index] = ch;
    }
    for (std::size_t index = 1; index < key_length; ++index) {
        const auto value = sorted[index];
        auto cursor = index;
        while (cursor > 0 && sorted[cursor - 1] > value) { sorted[cursor] = sorted[cursor - 1]; --cursor; }
        sorted[cursor] = value;
    }
    std::size_t ranks[max_key]{};
    for (std::size_t index = 0; index < key_length; ++index) {
        std::size_t first = 0, duplicate = 0;
        while (first < key_length && sorted[first] != key[index]) ++first;
        for (std::size_t prior = 0; prior < index; ++prior) if (key[prior] == key[index]) ++duplicate;
        ranks[index] = first + duplicate + 1;
    }
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto value = input[text_length_index + 1 + index];
        if (value < 32 || value > 126) return -1;
        text[index] = static_cast<std::uint8_t>(value);
    }
    if (mode == 0 && text[text_length - 1] == ' ') return -1;
    const auto padding = key_length - text_length % key_length;
    const auto padded_length = text_length + padding;
    for (auto index = text_length; index < padded_length; ++index) text[index] = ' ';
    std::size_t result_length = 0;
    if (mode == 0) {
        for (std::size_t start = 0; start < padded_length; start += key_length) {
            std::uint8_t block[max_key]{};
            for (std::size_t offset = 0; offset < key_length; ++offset) block[ranks[offset] - 1] = text[start + offset];
            for (std::size_t offset = 0; offset < key_length; ++offset) result[result_length++] = block[offset];
        }
    } else {
        for (std::size_t start = 0; start < text_length; start += key_length)
            for (std::size_t offset = 0; offset < key_length; ++offset) result[result_length++] = text[start + ranks[offset] - 1];
        while (result_length > 0 && result[result_length - 1] == ' ') --result_length;
    }
    return hash_output(result, result_length);
}
