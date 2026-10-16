#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t minimum_waiting_time(const std::int64_t *values, std::size_t length)
{
    if (length > 64 || (length != 0 && values == nullptr)) return std::numeric_limits<std::int64_t>::min();
    std::int64_t durations[64]{};
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 1000) return std::numeric_limits<std::int64_t>::min();
        durations[i] = values[i];
    }
    for (std::size_t i = 1; i < length; ++i) {
        const std::int64_t key = durations[i];
        std::size_t j = i;
        while (j > 0 && durations[j - 1] > key) {
            durations[j] = durations[j - 1];
            --j;
        }
        durations[j] = key;
    }
    std::int64_t total = 0;
    for (std::size_t i = 0; i < length; ++i)
        total += durations[i] * static_cast<std::int64_t>(length - i - 1);
    return total;
}
