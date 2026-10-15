/* Generate the nth count-and-say term as ASCII bytes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TERM_INDEX 19
#define MAX_TERM_LENGTH 256

int64_t count_and_say(int64_t term_index, uint8_t *output, size_t output_capacity)
{
    if (term_index < 1 || term_index > MAX_TERM_INDEX) return -1;
    uint8_t current[MAX_TERM_LENGTH] = {0};
    uint8_t next[MAX_TERM_LENGTH] = {0};
    size_t current_length = 1;
    current[0] = '1';
    for (int64_t term = 1; term < term_index; ++term) {
        size_t next_length = 0;
        for (size_t index = 0; index < current_length;) {
            size_t end = index + 1;
            while (end < current_length && current[end] == current[index]) ++end;
            const size_t run_length = end - index;
            if (next_length + 2 > MAX_TERM_LENGTH) return -1;
            next[next_length++] = (uint8_t)('0' + run_length);
            next[next_length++] = current[index];
            index = end;
        }
        for (size_t index = 0; index < next_length; ++index) current[index] = next[index];
        current_length = next_length;
    }
    if (output_capacity < current_length || output == NULL) return -2;
    for (size_t index = 0; index < current_length; ++index) output[index] = current[index];
    return (int64_t)current_length;
}
