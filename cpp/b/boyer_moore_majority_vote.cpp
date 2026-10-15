#include <cstddef>
#include <cstdint>

extern "C" std::int64_t boyer_moore_majority_vote(const std::int64_t *values, std::size_t length) {
    if (length == 0 || length > 256 || values == nullptr) return -1;
    std::int64_t candidate = 0;
    std::size_t balance = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (balance == 0) candidate = values[index];
        if (values[index] == candidate) ++balance;
        else --balance;
    }
    std::size_t occurrences = 0;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] == candidate) ++occurrences;
    return occurrences > length / 2 ? candidate : -1;
}
