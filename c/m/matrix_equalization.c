/* Minimum updates needed to equalize a vector with a fixed step size. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VECTOR_LENGTH 64
#define MAX_INPUT_LENGTH 66

int64_t matrix_equalization(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const size_t vector_length = length - 1;
    if (vector_length > MAX_VECTOR_LENGTH || input[0] < 1 ||
        input[0] > (int64_t)vector_length) return -1;
    const size_t step_size = (size_t)input[0];
    size_t minimum_updates = vector_length;

    for (size_t target_index = 0; target_index < vector_length; ++target_index) {
        bool seen = false;
        for (size_t previous = 0; previous < target_index; ++previous) {
            if (input[previous + 1] == input[target_index + 1]) {
                seen = true;
                break;
            }
        }
        if (seen) continue;

        size_t updates = 0;
        size_t index = 0;
        while (index < vector_length) {
            if (input[index + 1] == input[target_index + 1]) {
                ++index;
            } else {
                ++updates;
                index += step_size;
            }
        }
        if (updates < minimum_updates) minimum_updates = updates;
    }
    return (int64_t)minimum_updates;
}
