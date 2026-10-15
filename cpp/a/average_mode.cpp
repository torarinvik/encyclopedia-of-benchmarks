// Return the unique mode of a bounded integer sequence.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t average_mode(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > 64) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 0 || values[i] > 1000) return -1;

    std::int64_t mode = -1;
    std::size_t maximum_count = 0;
    bool tied = false;
    for (std::size_t i = 0; i < length; ++i) {
        bool seen = false;
        for (std::size_t before = 0; before < i; ++before)
            if (values[before] == values[i]) { seen = true; break; }
        if (seen) continue;

        std::size_t count = 0;
        for (std::size_t j = 0; j < length; ++j)
            if (values[j] == values[i]) ++count;
        if (count > maximum_count) {
            maximum_count = count;
            mode = values[i];
            tied = false;
        } else if (count == maximum_count) {
            tied = true;
        }
    }
    return tied ? -1 : mode;
}
