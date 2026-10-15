#include <cstddef>
#include <cstdint>

extern "C" std::int64_t is_sorted(const std::int64_t *values, std::size_t length) {
    if (length > 4096 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -2147483648LL || values[index] > 2147483647LL) return -1;
    }
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] < values[index - 1]) return 0;
    }
    return 1;
}
