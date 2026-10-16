/* Check whether two bounded ASCII strings preserve a one-to-one mapping. */
#include <stddef.h>
#include <stdint.h>

#define MAX_CODEPOINTS 8
#define MAX_INPUT_LENGTH (2 + 2 * MAX_CODEPOINTS + 2)

int64_t is_isomorphic(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t source_length = input[0];
    const int64_t target_length = input[1];
    if (source_length < 0 || source_length > MAX_CODEPOINTS ||
        target_length < 0 || target_length > MAX_CODEPOINTS) return -1;
    if (length != 2 + (size_t)source_length + (size_t)target_length) return -1;

    for (size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (source_length != target_length) return 0;

    int64_t source_to_target[128], target_to_source[128];
    for (size_t index = 0; index < 128; ++index) {
        source_to_target[index] = -1;
        target_to_source[index] = -1;
    }
    for (size_t index = 0; index < (size_t)source_length; ++index) {
        const int64_t source = input[2 + index];
        const int64_t target = input[2 + (size_t)source_length + index];
        if ((source_to_target[source] != -1 && source_to_target[source] != target) ||
            (target_to_source[target] != -1 && target_to_source[target] != source)) return 0;
        source_to_target[source] = target;
        target_to_source[target] = source;
    }
    return 1;
}
