#include <cstddef>
#include <cstdint>

extern "C" void reversort(std::int64_t *values, std::size_t length) {
    for (std::size_t index = 0; index + 1 < length; ++index) {
        std::size_t minimum = index;
        for (std::size_t probe = index + 1; probe < length; ++probe)
            if (values[probe] < values[minimum]) minimum = probe;
        for (std::size_t left = index, right = minimum; left < right; ++left, --right) {
            const std::int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
        }
    }
}
