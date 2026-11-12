#include <stddef.h>
#include <stdint.h>

enum { MAX_SOURCE_LENGTH = 6, MAX_INPUT_LENGTH = 16, MAX_OUTPUT_LENGTH = 12 };

static size_t maximum_subsequence(const int64_t *source, size_t length,
                                 size_t requested, uint8_t output[MAX_SOURCE_LENGTH])
{
    uint8_t stack[MAX_SOURCE_LENGTH];
    size_t stack_length = 0;
    size_t deletions = length - requested;
    for (size_t i = 0; i < length; ++i) {
        const uint8_t digit = (uint8_t)source[i];
        while (deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit) {
            --stack_length;
            --deletions;
        }
        stack[stack_length++] = digit;
    }
    stack_length -= deletions;
    for (size_t i = 0; i < stack_length; ++i) output[i] = stack[i];
    return stack_length;
}

static int compare_suffix(const uint8_t *first, size_t first_length, size_t first_at,
                          const uint8_t *second, size_t second_length, size_t second_at)
{
    while (first_at < first_length && second_at < second_length) {
        if (first[first_at] != second[second_at])
            return first[first_at] > second[second_at] ? 1 : -1;
        ++first_at;
        ++second_at;
    }
    if (first_at == first_length && second_at == second_length) return 0;
    return first_at == first_length ? -1 : 1;
}

static size_t merge_sequences(const uint8_t *first, size_t first_length,
                              const uint8_t *second, size_t second_length,
                              uint8_t output[MAX_OUTPUT_LENGTH])
{
    size_t i = 0;
    size_t j = 0;
    size_t written = 0;
    while (i < first_length || j < second_length) {
        const int order = compare_suffix(first, first_length, i, second, second_length, j);
        if (j == second_length || (i < first_length && order >= 0))
            output[written++] = first[i++];
        else
            output[written++] = second[j++];
    }
    return written;
}

static int lexicographically_greater(const uint8_t *left, const uint8_t *right, size_t length)
{
    for (size_t i = 0; i < length; ++i) {
        if (left[i] != right[i]) return left[i] > right[i];
    }
    return 0;
}

int64_t create_maximum_number(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_SOURCE_LENGTH
        || input[1] < 0 || input[1] > MAX_SOURCE_LENGTH) return -1;
    const size_t first_length = (size_t)input[0];
    const size_t second_length = (size_t)input[1];
    if (input[2] < 0 || input[2] > (int64_t)(first_length + second_length)) return -1;
    const size_t requested = (size_t)input[2];
    if (length != 3 + first_length + second_length) return -1;
    for (size_t i = 0; i < first_length + second_length; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 9) return -1;
    if (output == NULL || capacity < requested) return -2;

    const int64_t *first_source = input + 3;
    const int64_t *second_source = first_source + first_length;
    const size_t minimum_first = requested > second_length ? requested - second_length : 0;
    const size_t maximum_first = requested < first_length ? requested : first_length;
    uint8_t best[MAX_OUTPUT_LENGTH] = {0};
    uint8_t candidate[MAX_OUTPUT_LENGTH] = {0};
    int have_best = 0;

    for (size_t take_first = minimum_first; take_first <= maximum_first; ++take_first) {
        uint8_t selected_first[MAX_SOURCE_LENGTH] = {0};
        uint8_t selected_second[MAX_SOURCE_LENGTH] = {0};
        const size_t selected_first_length = maximum_subsequence(
            first_source, first_length, take_first, selected_first);
        const size_t selected_second_length = maximum_subsequence(
            second_source, second_length, requested - take_first, selected_second);
        const size_t candidate_length = merge_sequences(
            selected_first, selected_first_length,
            selected_second, selected_second_length, candidate);
        if (!have_best || lexicographically_greater(candidate, best, candidate_length)) {
            for (size_t i = 0; i < candidate_length; ++i) best[i] = candidate[i];
            have_best = 1;
        }
    }

    for (size_t i = 0; i < requested; ++i) output[i] = best[i];
    return (int64_t)requested;
}
