#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 32
#define MAX_INPUT_LENGTH (2 + 2 * MAX_STRING_LENGTH)
#define SCALE INT64_C(1000000000)

int64_t jaro_winkler_distance(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t first_length_value = input[0];
    if (first_length_value < 0 || first_length_value > MAX_STRING_LENGTH) return -1;
    const size_t first_length = (size_t)first_length_value;
    const size_t second_length_index = 1 + first_length;
    if (second_length_index >= length) return -1;

    const int64_t second_length_value = input[second_length_index];
    if (second_length_value < 0 || second_length_value > MAX_STRING_LENGTH ||
        first_length_value < second_length_value ||
        length != second_length_index + 1 + (size_t)second_length_value) return -1;
    const size_t second_length = (size_t)second_length_value;
    const int64_t *first = input + 1;
    const int64_t *second = input + second_length_index + 1;

    for (size_t i = 0; i < first_length; ++i)
        if (first[i] < 0 || first[i] > 127) return -1;
    for (size_t i = 0; i < second_length; ++i)
        if (second[i] < 0 || second[i] > 127) return -1;

    int equal = first_length == second_length;
    for (size_t i = 0; equal && i < first_length; ++i)
        if (first[i] != second[i]) { equal = 0; break; }
    if (equal) return 0;
    if (second_length == 0) return SCALE;

    const size_t half = first_length / 2;
    const size_t radius = half > 0 ? half - 1 : 0;
    uint8_t first_matched[MAX_STRING_LENGTH] = {0};
    uint8_t second_matched[MAX_STRING_LENGTH] = {0};
    size_t match_count = 0;

    for (size_t i = 0; i < first_length; ++i) {
        const size_t start = i > radius ? i - radius : 0;
        size_t end = i + radius;
        if (end >= second_length) end = second_length - 1;
        if (start > end) continue;
        for (size_t j = start; j <= end; ++j) {
            if (first[i] == second[j] && !second_matched[j]) {
                first_matched[i] = 1;
                second_matched[j] = 1;
                ++match_count;
                break;
            }
        }
    }
    if (match_count == 0) return SCALE;

    size_t second_index = 0;
    size_t mismatched_pairs = 0;
    for (size_t i = 0; i < first_length; ++i) {
        if (!first_matched[i]) continue;
        while (second_index < second_length && !second_matched[second_index]) ++second_index;
        if (second_index == second_length) return -1;
        if (first[i] != second[second_index]) ++mismatched_pairs;
        ++second_index;
    }
    const int64_t transpositions = (int64_t)(mismatched_pairs / 2);
    const int64_t matches = (int64_t)match_count;
    const int64_t first_size = (int64_t)first_length;
    const int64_t second_size = (int64_t)second_length;
    const int64_t jaro_numerator = matches * matches * second_size +
        matches * matches * first_size + (matches - transpositions) * first_size * second_size;
    const int64_t jaro_denominator = 3 * first_size * second_size * matches;

    size_t prefix_length = 0;
    const size_t prefix_limit = second_length < 4 ? second_length : 4;
    while (prefix_length < prefix_limit && first[prefix_length] == second[prefix_length])
        ++prefix_length;

    const int64_t denominator = 10 * jaro_denominator;
    const int64_t numerator = (int64_t)(10 - prefix_length) *
        (jaro_denominator - jaro_numerator);
    return (numerator * SCALE + denominator / 2) / denominator;
}
