#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH ((size_t)256)
#define MIN_VALUE (-INT64_C(1000000))
#define MAX_VALUE INT64_C(1000000)
#define CHECKSUM_OFFSET INT64_C(1000001)
#define INVALID_RESULT INT64_C(-1)

int64_t improved_simple_sort(const int64_t *values, size_t length) {
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return INVALID_RESULT;
    int64_t working[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < MIN_VALUE || values[index] > MAX_VALUE) return INVALID_RESULT;
        working[index] = values[index];
    }

    for (size_t i = 1; i < length; ++i) {
        for (size_t j = 0; j + 1 < length; ++j) {
            if (working[i] < working[j]) {
                const int64_t temporary = working[i];
                working[i] = working[j];
                working[j] = temporary;
            }
        }
    }
    int64_t checksum = 0;
    for (size_t index = 0; index < length; ++index) {
        checksum += (int64_t)(index + 1) * (working[index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
