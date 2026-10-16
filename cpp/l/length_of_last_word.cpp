#include <cstddef>
#include <cstdint>

extern "C" std::int64_t length_of_last_word(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 129) return -1;
    if (input[0] < 0 || input[0] > 128 || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    std::size_t index = static_cast<std::size_t>(input[0]);
    while (index > 0 && input[index] == 32) --index;
    std::int64_t word_length = 0;
    while (index > 0 && input[index] != 32) {
        if (input[index] < 0 || input[index] > 255) return -1;
        ++word_length;
        --index;
    }
    for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    return word_length;
}
