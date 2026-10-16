#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_ARRAY_LENGTH 256
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 3)
#define INT32_MIN_VALUE (-2147483647LL - 1)
#define INT32_MAX_VALUE 2147483647LL

int64_t second_min_max(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = input[0], raw_count = input[1];
    if ((operation != 0 && operation != 1) || raw_count < 2 || raw_count > MAX_ARRAY_LENGTH) return INVALID_RESULT;
    const size_t count = (size_t)raw_count;
    if (length != count + 2) return INVALID_RESULT;

    const int64_t initial = operation == 0 ? INT32_MAX_VALUE : INT32_MIN_VALUE;
    int64_t best = initial, second = initial;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2];
        if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE) return INVALID_RESULT;
        const int better = operation == 0 ? value < best : value > best;
        if (better) {
            second = best;
            best = value;
        } else {
            const int improves_second = operation == 0 ? value < second : value > second;
            if (improves_second && value != best) second = value;
        }
    }
    return second == initial ? INVALID_RESULT : second;
}
