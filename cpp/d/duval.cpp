// Least cyclic shift index using Duval's linear-time scan.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t duval(const std::int64_t *values, std::size_t length) {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    if (values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }

    std::size_t i = 0, answer = 0;
    while (i < length) {
        answer = i;
        std::size_t j = i + 1, k = i;
        while (j < 2 * length && values[j % length] >= values[k % length]) {
            if (values[k % length] < values[j % length]) k = i;
            else ++k;
            ++j;
        }
        while (i <= k) i += j - k;
    }
    return static_cast<std::int64_t>(answer);
}
