#include <cstddef>
#include <cstdint>

extern "C" std::int64_t verifying_an_alien_dictionary(const std::int64_t *input, std::size_t length)
{
    constexpr std::size_t max_words = 100;
    constexpr std::size_t max_input_length = 2127;
    constexpr std::int64_t invalid_result = -1;
    if (input == nullptr || length < 27 || length > max_input_length || input[0] < 1 ||
        input[0] > static_cast<std::int64_t>(max_words))
        return invalid_result;
    const std::size_t word_count = static_cast<std::size_t>(input[0]);
    std::int64_t rank[26];
    bool order_seen[26] = {};
    for (std::size_t position = 0; position < 26; ++position) {
        const std::int64_t letter = input[1 + position];
        if (letter < 'a' || letter > 'z') return invalid_result;
        const std::size_t index = static_cast<std::size_t>(letter - 'a');
        if (order_seen[index]) return invalid_result;
        order_seen[index] = true;
        rank[index] = static_cast<std::int64_t>(position);
    }

    std::size_t starts[max_words], word_lengths[max_words];
    std::size_t offset = 27;
    for (std::size_t word = 0; word < word_count; ++word) {
        if (offset >= length || input[offset] < 1 || input[offset] > 20) return invalid_result;
        const std::size_t word_length = static_cast<std::size_t>(input[offset++]);
        if (word_length > length - offset) return invalid_result;
        starts[word] = offset;
        word_lengths[word] = word_length;
        for (std::size_t character = 0; character < word_length; ++character)
            if (input[offset + character] < 'a' || input[offset + character] > 'z')
                return invalid_result;
        offset += word_length;
    }
    if (offset != length) return invalid_result;

    for (std::size_t word = 0; word + 1 < word_count; ++word) {
        const std::size_t left_length = word_lengths[word];
        const std::size_t right_length = word_lengths[word + 1];
        const std::size_t limit = left_length < right_length ? left_length : right_length;
        bool decided = false;
        for (std::size_t character = 0; character < limit; ++character) {
            const std::size_t left_letter = static_cast<std::size_t>(input[starts[word] + character] - 'a');
            const std::size_t right_letter = static_cast<std::size_t>(input[starts[word + 1] + character] - 'a');
            if (rank[left_letter] < rank[right_letter]) {
                decided = true;
                break;
            }
            if (rank[left_letter] > rank[right_letter]) return 0;
        }
        if (!decided && left_length > right_length) return 0;
    }
    return 1;
}
