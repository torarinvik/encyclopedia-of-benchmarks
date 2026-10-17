#include <stddef.h>
#include <stdint.h>

#define MAX_DRAWS INT64_C(256)
#define MAX_INPUT_LENGTH ((size_t)260)

int64_t rescale(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t max_value = input[0];
    const int64_t new_max = input[1];
    const int64_t draw_count = input[2];
    if (max_value < 2 || max_value > 64 || new_max < 1 || new_max > 256
        || draw_count < 1 || draw_count > MAX_DRAWS) return -1;
    if (length != (size_t)(3 + draw_count)) return -1;
    for (int64_t i = 0; i < draw_count; ++i) {
        const int64_t draw = input[3 + (size_t)i];
        if (draw < 0 || draw >= max_value) return -1;
    }

    size_t cursor = 0;
    if (new_max == max_value) return input[3];

    if (new_max < max_value) {
        const int64_t threshold = max_value - max_value % new_max;
        while (cursor < (size_t)draw_count) {
            const int64_t draw = input[3 + cursor++];
            if (draw < threshold) return draw % new_max;
        }
        return -1;
    }

    int64_t result = 0;
    int64_t power = 1;
    while (power < new_max) {
        if (cursor >= (size_t)draw_count) return -1;
        result += power * input[3 + cursor++];
        power *= max_value;
    }
    if (power == new_max) return result;

    const int64_t threshold = power - power % new_max;
    while (result >= threshold) {
        result = 0;
        power = 1;
        while (power < new_max) {
            if (cursor >= (size_t)draw_count) return -1;
            result += power * input[3 + cursor++];
            power *= max_value;
        }
    }
    return result % new_max;
}
