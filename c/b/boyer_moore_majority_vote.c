#include <stddef.h>
#include <stdint.h>

int64_t boyer_moore_majority_vote(const int64_t *values, size_t length) {
    if (length == 0 || length > 256 || values == NULL) return -1;
    int64_t candidate = 0;
    size_t balance = 0;
    for (size_t index = 0; index < length; ++index) {
        if (balance == 0) candidate = values[index];
        if (values[index] == candidate) ++balance;
        else --balance;
    }
    size_t occurrences = 0;
    for (size_t index = 0; index < length; ++index)
        if (values[index] == candidate) ++occurrences;
    return occurrences > length / 2 ? candidate : -1;
}
