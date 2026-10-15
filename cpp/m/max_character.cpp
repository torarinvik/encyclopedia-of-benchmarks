#include <cstddef>
#include <cstdint>

extern "C" int64_t max_character(const int64_t *values, size_t length)
{
    if (length == 0 || length > 256 || values == nullptr) return -1;
    int64_t counts[26] = {};
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 97 || values[i] > 122) return -1;
        ++counts[values[i] - 97];
    }
    int64_t best = 0, code = -1;
    bool tied = false;
    for (int i = 0; i < 26; ++i) {
        if (counts[i] > best) { best = counts[i]; code = 97 + i; tied = false; }
        else if (counts[i] == best && best != 0) tied = true;
    }
    return tied ? -1 : code;
}
