#include <cstddef>
#include <cstdint>

extern "C" int64_t smallest_divisor(const int64_t *input, size_t length) {
    if (length < 2 || length > 257 || input == nullptr) return -1;
    const int64_t threshold = input[0];
    if (threshold < 1 || threshold > 1000000) return -1;
    int64_t maximum = 0;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = input[index];
        if (value < 1 || value > 1000000) return -1;
        if (value > maximum) maximum = value;
    }
    const size_t count = length - 1;
    if (threshold < static_cast<int64_t>(count)) return -1;
    int64_t low = 1;
    int64_t high = maximum;
    while (low < high) {
        const int64_t middle = low + (high - low) / 2;
        int64_t sum = 0;
        for (size_t index = 1; index < length; ++index) {
            sum += (input[index] + middle - 1) / middle;
        }
        if (sum <= threshold) high = middle;
        else low = middle + 1;
    }
    return low;
}
