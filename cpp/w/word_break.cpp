/* Bottom-up word segmentation over packed lowercase ASCII letter codes. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t word_break(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 1122) return -1;
    const std::int64_t text_length_value = values[0];
    const std::int64_t word_count_value = values[1];
    if (text_length_value < 0 || text_length_value > 64 ||
        word_count_value < 0 || word_count_value > 32) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto word_count = static_cast<std::size_t>(word_count_value);
    const std::size_t dictionary_start = 2 + text_length;
    if (length != dictionary_start + word_count * 33) return -1;

    for (std::size_t index = 0; index < text_length; ++index) {
        if (values[2 + index] < 1 || values[2 + index] > 26) return -1;
    }
    for (std::size_t word = 0; word < word_count; ++word) {
        const std::size_t slot = dictionary_start + word * 33;
        const std::int64_t word_length = values[slot];
        if (word_length < 1 || word_length > 32) return -1;
        for (std::size_t index = 0; index < 32; ++index) {
            const std::int64_t code = values[slot + 1 + index];
            if (index < static_cast<std::size_t>(word_length)) {
                if (code < 1 || code > 26) return -1;
            } else if (code != 0) {
                return -1;
            }
        }
    }

    std::array<bool, 65> reachable{};
    reachable[0] = true;
    for (std::size_t start = 0; start < text_length; ++start) {
        if (!reachable[start]) continue;
        for (std::size_t word = 0; word < word_count; ++word) {
            const std::size_t slot = dictionary_start + word * 33;
            const auto word_length = static_cast<std::size_t>(values[slot]);
            if (word_length > text_length - start) continue;
            std::size_t index = 0;
            while (index < word_length &&
                   values[2 + start + index] == values[slot + 1 + index]) {
                ++index;
            }
            if (index == word_length) reachable[start + word_length] = true;
        }
    }
    return reachable[text_length] ? 1 : 0;
}
