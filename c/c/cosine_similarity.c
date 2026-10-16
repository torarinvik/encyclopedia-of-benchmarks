#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 64
#define MAX_INPUT_LENGTH 132
#define MIN_PRINTABLE_ASCII 32
#define MAX_PRINTABLE_ASCII 126
#define ALPHABET_SIZE 95
#define INVALID_RESULT (-1.0e300)

double cosine_similarity(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > MAX_STRING_LENGTH
            || input[1] < 0 || input[1] > MAX_STRING_LENGTH) return INVALID_RESULT;
    const size_t left_length = (size_t)input[0];
    const size_t right_length = (size_t)input[1];
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    uint64_t left_counts[ALPHABET_SIZE] = {0};
    uint64_t right_counts[ALPHABET_SIZE] = {0};
    for (size_t i = 0; i < left_length; ++i) {
        int64_t value = input[2 + i];
        if (value < MIN_PRINTABLE_ASCII || value > MAX_PRINTABLE_ASCII) return INVALID_RESULT;
        if (value >= 65 && value <= 90) value += 32;
        ++left_counts[(size_t)(value - MIN_PRINTABLE_ASCII)];
    }
    for (size_t i = 0; i < right_length; ++i) {
        int64_t value = input[2 + left_length + i];
        if (value < MIN_PRINTABLE_ASCII || value > MAX_PRINTABLE_ASCII) return INVALID_RESULT;
        if (value >= 65 && value <= 90) value += 32;
        ++right_counts[(size_t)(value - MIN_PRINTABLE_ASCII)];
    }

    double dot_product = 0.0, left_magnitude_squared = 0.0, right_magnitude_squared = 0.0;
    for (size_t i = 0; i < ALPHABET_SIZE; ++i) {
        const double left = (double)left_counts[i];
        const double right = (double)right_counts[i];
        dot_product += left * right;
        left_magnitude_squared += left * left;
        right_magnitude_squared += right * right;
    }
    if (left_magnitude_squared <= 0.0 || right_magnitude_squared <= 0.0) return 0.0;
    return dot_product / (sqrt(left_magnitude_squared) * sqrt(right_magnitude_squared));
}
