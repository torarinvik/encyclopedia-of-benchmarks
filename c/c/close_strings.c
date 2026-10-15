#include <stddef.h>
#include <stdint.h>

int64_t close_strings(const int64_t *input, size_t length) {
    if (length < 2 || length > 514 || input == NULL) return -1;
    int64_t first_length_value = input[0];
    int64_t second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 256
            || second_length_value < 0 || second_length_value > 256
            || length != (size_t)(2 + first_length_value + second_length_value)) return -1;
    size_t first_length = (size_t)first_length_value;
    size_t second_length = (size_t)second_length_value;
    int64_t first[26] = {0};
    int64_t second[26] = {0};
    for (size_t index = 0; index < first_length; ++index) {
        int64_t value = input[2 + index];
        if (value < 'a' || value > 'z') return -1;
        ++first[(size_t)(value - 'a')];
    }
    size_t second_start = 2 + first_length;
    for (size_t index = 0; index < second_length; ++index) {
        int64_t value = input[second_start + index];
        if (value < 'a' || value > 'z') return -1;
        ++second[(size_t)(value - 'a')];
    }
    if (first_length != second_length) return 0;
    int64_t first_frequency_counts[257] = {0};
    int64_t second_frequency_counts[257] = {0};
    for (size_t letter = 0; letter < 26; ++letter) {
        if ((first[letter] == 0) != (second[letter] == 0)) return 0;
        ++first_frequency_counts[(size_t)first[letter]];
        ++second_frequency_counts[(size_t)second[letter]];
    }
    for (size_t frequency = 0; frequency <= 256; ++frequency) {
        if (first_frequency_counts[frequency] != second_frequency_counts[frequency]) return 0;
    }
    return 1;
}
