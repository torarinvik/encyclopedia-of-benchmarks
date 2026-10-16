#include <cstddef>
#include <cstdint>

extern "C" std::int64_t is_monotonic(const std::int64_t *values, std::size_t length) noexcept {
    if (length > 256 || (values == nullptr && length != 0)) {
        return -1;
    }
    for (std::size_t i = 1; i < length; ++i) {
        if (values[i - 1] > values[i]) {
            for (std::size_t j = 1; j < length; ++j) {
                if (values[j - 1] < values[j]) {
                    return 0;
                }
            }
            return 1;
        }
    }
    return 1;
}
