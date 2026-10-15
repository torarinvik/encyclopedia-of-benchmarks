#include <stddef.h>
#include <stdint.h>

int64_t max_character(const int64_t *values, size_t length)
{
    if (length == 0 || length > 256 || values == NULL) return -1;
    int64_t counts[26] = {0};
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 97 || values[i] > 122) return -1;
        ++counts[values[i] - 97];
    }
    int64_t best = 0, code = -1;
    int tied = 0;
    for (int i = 0; i < 26; ++i) {
        if (counts[i] > best) { best = counts[i]; code = 97 + i; tied = 0; }
        else if (counts[i] == best && best != 0) tied = 1;
    }
    return tied ? -1 : code;
}
