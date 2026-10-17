#include <stddef.h>
#include <stdint.h>

#define MATCHDIMENSIONS_COUNT 4
#define MATCHDIMENSIONS_MAX_DIMENSION 65535

int64_t matchdimensions(const int64_t *values, size_t length) {
    if (values == NULL || length != MATCHDIMENSIONS_COUNT) return -1;
    for (size_t index = 0; index < MATCHDIMENSIONS_COUNT; ++index) {
        if (values[index] < 0 || values[index] > MATCHDIMENSIONS_MAX_DIMENSION) return -1;
    }
    return values[0] == values[2] && values[1] == values[3] ? 1 : 0;
}
