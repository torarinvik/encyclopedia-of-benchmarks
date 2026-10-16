// Interquartile range using the source lower/upper-half median rule.
#include <cstddef>
#include <cstdint>

static double median_i64(const std::int64_t *values, std::size_t count) {
    if (count % 2 != 0) return static_cast<double>(values[count / 2]);
    return (static_cast<double>(values[count / 2 - 1]) + static_cast<double>(values[count / 2])) / 2.0;
}
extern "C" double interquartile_range(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > 64) return -1.0e300;
    std::int64_t sorted[64];
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < -1000000 || values[i] > 1000000) return -1.0e300;
        sorted[i] = values[i];
    }
    for (std::size_t i = 1; i < length; ++i) {
        const auto key = sorted[i];
        std::size_t j = i;
        while (j > 0 && sorted[j - 1] > key) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = key;
    }
    const auto half = length / 2;
    const auto upper_start = half + length % 2;
    return median_i64(sorted + upper_start, half) - median_i64(sorted, half);
}
