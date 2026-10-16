#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_bytes = 512;
constexpr std::size_t max_mask_bytes = 16;
constexpr std::size_t max_parseable_input_length = 531;
constexpr std::size_t max_output_bytes = 1447;

bool is_word(std::uint8_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9') || value == '_';
}

bool is_normalized_target(const std::uint8_t *text, std::size_t start, std::size_t end) {
    const auto length = end - start;
    if (length == 5) {
        return (text[start] == 'b' && text[start + 1] == 'i' && text[start + 2] == 'r' &&
                text[start + 3] == 'd' && text[start + 4] == 's') ||
               (text[start] == 'B' && text[start + 1] == 'I' && text[start + 2] == 'R' &&
                text[start + 3] == 'D' && text[start + 4] == 'S') ||
               (text[start] == 'B' && text[start + 1] == 'i' && text[start + 2] == 'r' &&
                text[start + 3] == 'd' && text[start + 4] == 's');
    }
    if (length == 6) {
        return (text[start] == 'm' && text[start + 1] == 'a' && text[start + 2] == 'r' &&
                text[start + 3] == 'k' && text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 'M' && text[start + 1] == 'A' && text[start + 2] == 'R' &&
                text[start + 3] == 'K' && text[start + 4] == 'E' && text[start + 5] == 'T') ||
               (text[start] == 'M' && text[start + 1] == 'a' && text[start + 2] == 'r' &&
                text[start + 3] == 'k' && text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 's' && text[start + 1] == 't' && text[start + 2] == 'r' &&
                text[start + 3] == 'e' && text[start + 4] == 'e' && text[start + 5] == 't') ||
               (text[start] == 'S' && text[start + 1] == 'T' && text[start + 2] == 'R' &&
                text[start + 3] == 'E' && text[start + 4] == 'E' && text[start + 5] == 'T') ||
               (text[start] == 'S' && text[start + 1] == 't' && text[start + 2] == 'r' &&
                text[start + 3] == 'e' && text[start + 4] == 'e' && text[start + 5] == 't');
    }
    return false;
}

std::size_t match_length(const std::uint8_t *text, std::size_t start,
                         std::size_t end, std::size_t position) {
    std::size_t length = 0;
    if (position + 5 <= end && text[position] == 'b' && text[position + 1] == 'i' &&
        text[position + 2] == 'r' && text[position + 3] == 'd' && text[position + 4] == 's') {
        length = 5;
    } else if (position + 6 <= end && text[position] == 'm' && text[position + 1] == 'a' &&
               text[position + 2] == 'r' && text[position + 3] == 'k' &&
               text[position + 4] == 'e' && text[position + 5] == 't') {
        length = 6;
    } else if (position + 6 <= end && text[position] == 's' && text[position + 1] == 't' &&
               text[position + 2] == 'r' && text[position + 3] == 'e' &&
               text[position + 4] == 'e' && text[position + 5] == 't') {
        length = 6;
    }
    if (length == 0 || (position > start && is_word(text[position - 1])) ||
        (position + length < end && is_word(text[position + length]))) return 0;
    return length;
}

std::size_t append_token(const std::uint8_t *text, std::size_t start, std::size_t end,
                         const std::uint8_t *mask, std::size_t mask_length,
                         std::uint8_t *output, std::size_t output_length) {
    if (is_normalized_target(text, start, end)) {
        for (std::size_t i = 0; i < mask_length; ++i) output[output_length++] = mask[i];
        return output_length;
    }
    std::size_t position = start;
    while (position < end) {
        const auto match = match_length(text, start, end, position);
        if (match != 0) {
            for (std::size_t i = 0; i < mask_length; ++i) output[output_length++] = mask[i];
            position += match;
        } else {
            if (text[position] != '\n') output[output_length++] = text[position];
            ++position;
        }
    }
    return output_length;
}
} // namespace

extern "C" std::int64_t maskwords(const std::int64_t *values, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (!values || length < 2 || length > max_parseable_input_length) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_text_bytes)) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto mask_length_index = 1 + text_length;
    if (mask_length_index >= length || values[mask_length_index] < 0 ||
        values[mask_length_index] > static_cast<std::int64_t>(max_mask_bytes)) return -1;
    const auto mask_length = static_cast<std::size_t>(values[mask_length_index]);
    if (length != mask_length_index + 1 + mask_length) return -1;

    std::array<std::uint8_t, max_text_bytes> text{};
    std::array<std::uint8_t, max_mask_bytes> mask{};
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = values[1 + i];
        if (value < 1 || value > 127) return -1;
        text[i] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t i = 0; i < mask_length; ++i) {
        const auto value = values[mask_length_index + 1 + i];
        if (value < 32 || value > 126 || value == '\\') return -1;
        mask[i] = static_cast<std::uint8_t>(value);
    }

    std::array<std::uint8_t, max_output_bytes> scratch{};
    std::size_t written = 0, start = 0;
    bool have_token = false;
    for (std::size_t i = 0; i < text_length; ++i) {
        if (text[i] == ' ') {
            if (have_token) scratch[written++] = ' ';
            written = append_token(text.data(), start, i, mask.data(), mask_length,
                                   scratch.data(), written);
            have_token = true;
            start = i + 1;
        }
    }
    if (start < text_length) {
        if (have_token) scratch[written++] = ' ';
        written = append_token(text.data(), start, text_length, mask.data(), mask_length,
                               scratch.data(), written);
    }
    if (written > max_output_bytes) return -1;
    if (output_capacity < written || (written != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < written; ++i) output[i] = scratch[i];
    return static_cast<std::int64_t>(written);
}
