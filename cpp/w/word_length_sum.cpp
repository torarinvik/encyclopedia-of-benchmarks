// Go Problem17: sum byte lengths after splitting on ASCII space.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t word_length_sum(const std::int64_t *values, std::size_t length) noexcept {
    if (length > 4096 || (length != 0 && values == nullptr)) return -1;
    std::int64_t total = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 255) return -1;
        if (values[index] != 32) ++total;
    }
    return total;
}
