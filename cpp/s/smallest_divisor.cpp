#include <cstddef>
#include <cstdint>

extern "C" int64_t smallest_divisor(const int64_t *input, size_t length) {
    if (length < 2 || length > 257 || input == nullptr) return -1;
    const uint64_t count = static_cast<uint64_t>((length - 1));
    const uint64_t threshold = static_cast<uint64_t>(input[0]);
    if (threshold < count || threshold > 1000000) return -1;
    uint64_t maximum = 0;
    uint64_t total = 0;
    for (size_t index = 1; index < length; ++index) {
        const uint64_t value = static_cast<uint64_t>(input[index]);
        if (value == 0 || value > 1000000) return -1;
        maximum = value > maximum ? value : maximum;
        total += value;
    }
    if (threshold == count) return static_cast<int64_t>(maximum);

    uint64_t low = (total - 1) / threshold + 1;
    const uint64_t upper_bound = (total - count) / (threshold - count + 1) + 1;
    uint64_t high = upper_bound < maximum ? upper_bound : maximum;
    while (low < high) {
        const uint64_t middle = low + ((high - low) >> 1);
        uint64_t rounded_sum = count;
        if (count <= 4) {
            for (size_t index = 1; index < length; ++index) {
                rounded_sum += (static_cast<uint32_t>(input[index]) - 1) / static_cast<uint32_t>(middle);
            }
        } else {
            const uint64_t reciprocal = (1099511627775 / middle) + 1;
            for (size_t index = 1; index < length; ++index) {
                rounded_sum += ((static_cast<uint64_t>(input[index]) - 1) * reciprocal) >> 40;
            }
        }
        if (rounded_sum <= threshold) high = middle;
        else low = middle + 1;
    }
    return static_cast<int64_t>(low);
}
