#include <cstddef>
#include <cstdint>

extern "C" std::int64_t reversort_cost(const std::int64_t *values, std::size_t length) {
    if (length > 256) return -1;
    std::int64_t working[256];
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        working[index] = values[index];
    }
    std::int64_t cost = 0;
    for (std::size_t index = 0; index + 1 < length; ++index) {
        std::size_t minimum = index;
        for (std::size_t probe = index + 1; probe < length; ++probe)
            if (working[probe] < working[minimum]) minimum = probe;
        for (std::size_t left = index, right = minimum; left < right; ++left, --right) {
            const std::int64_t temporary = working[left];
            working[left] = working[right];
            working[right] = temporary;
        }
        cost += static_cast<std::int64_t>(minimum - index + 1);
    }
    return cost;
}
