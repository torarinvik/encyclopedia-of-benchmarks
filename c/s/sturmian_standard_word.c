#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 4
#define MAX_REPEAT 2
#define MAX_WORD 41

static int sturmian_directives_valid(const int64_t *input, size_t length,
                                     int64_t directives[MAX_STEPS],
                                     size_t *steps_out) {
    if (input == NULL || length < 1 || length > 6) return 0;
    const int64_t steps_word = input[0];
    if (steps_word < 0 || steps_word > MAX_STEPS) return 0;
    const size_t steps = (size_t)steps_word;
    if (length != steps + 1) return 0;
    for (size_t i = 0; i < steps; ++i) {
        const int64_t repeat = input[i + 1];
        if (i == 0) {
            if (repeat < 0 || repeat > MAX_REPEAT) return 0;
        } else if (repeat < 1 || repeat > MAX_REPEAT) {
            return 0;
        }
        directives[i] = repeat;
    }
    *steps_out = steps;
    return 1;
}

int64_t sturmian_standard_word(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    int64_t directives[MAX_STEPS] = {0, 0, 0, 0};
    size_t steps = 0;
    if (!sturmian_directives_valid(input, length, directives, &steps)) return -1;

    uint8_t first[MAX_WORD] = {0};
    uint8_t second[MAX_WORD] = {0};
    uint8_t third[MAX_WORD] = {0};
    uint8_t *previous = first;
    uint8_t *current = second;
    uint8_t *following = third;
    size_t previous_length = 1;
    size_t current_length = 1;
    previous[0] = (uint8_t)'b';
    current[0] = (uint8_t)'a';

    for (size_t step = 0; step < steps; ++step) {
        const size_t repeat = (size_t)directives[step];
        const size_t following_length = current_length * repeat + previous_length;
        size_t position = 0;
        for (size_t copy = 0; copy < repeat; ++copy) {
            for (size_t i = 0; i < current_length; ++i) following[position++] = current[i];
        }
        for (size_t i = 0; i < previous_length; ++i) following[position++] = previous[i];

        for (size_t i = 0; i < current_length; ++i) previous[i] = current[i];
        for (size_t i = 0; i < following_length; ++i) current[i] = following[i];
        previous_length = current_length;
        current_length = following_length;
    }

    if (output == NULL || capacity < current_length) return -2;
    for (size_t i = 0; i < current_length; ++i) output[i] = current[i];
    return (int64_t)current_length;
}
