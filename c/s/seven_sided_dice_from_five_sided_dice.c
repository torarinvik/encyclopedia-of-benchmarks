#include <stddef.h>
#include <stdint.h>

enum { MAX_DRAWS = 256, MAX_INPUT_LENGTH = MAX_DRAWS + 2 };

int64_t seven_sided_dice_from_five_sided_dice(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t draw_count_value = input[0];
    if (draw_count_value < 0 || draw_count_value > MAX_DRAWS ||
        length != (size_t)draw_count_value + 1) return -1;
    const size_t draw_count = (size_t)draw_count_value;
    for (size_t index = 0; index < draw_count; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 4) return -1;

    uint8_t staged[MAX_DRAWS];
    size_t written = 0;
    int64_t value = 0;
    int64_t range = 1;
    for (size_t index = 0; index < draw_count; ++index) {
        value = 5 * value + input[index + 1];
        range *= 5;
        while (range >= 7) {
            const int64_t accepted = range - range % 7;
            if (value < accepted) {
                staged[written++] = (uint8_t)(value % 7 + 1);
                value /= 7;
                range = accepted / 7;
            } else {
                value -= accepted;
                range -= accepted;
            }
        }
    }

    if (output == NULL || capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = staged[index];
    return (int64_t)written;
}
