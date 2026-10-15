#include <stddef.h>
#include <stdint.h>

int64_t max_number_of_balloons(const int64_t *text, size_t length) {
    if (length > 256) {
        return -1;
    }
    int64_t counts[5] = {0, 0, 0, 0, 0};
    for (size_t index = 0; index < length; ++index) {
        int64_t value = text[index];
        if (value < 97 || value > 122) {
            return -1;
        }
        if (value == 98) ++counts[0];
        else if (value == 97) ++counts[1];
        else if (value == 108) ++counts[2];
        else if (value == 111) ++counts[3];
        else if (value == 110) ++counts[4];
    }
    counts[2] /= 2;
    counts[3] /= 2;
    int64_t minimum = counts[0];
    for (size_t index = 1; index < 5; ++index) {
        if (counts[index] < minimum) minimum = counts[index];
    }
    return minimum;
}
