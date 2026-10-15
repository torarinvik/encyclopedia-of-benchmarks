#include <cstddef>
#include <cstdint>

extern "C" int64_t find_the_highest_altitude(const int64_t *input, size_t length) {
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 1024 || length != static_cast<size_t>(input[0]) + 1) return -1;
    const size_t n = static_cast<size_t>(input[0]);
    int64_t altitude = 0, maximum = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t gain = input[i + 1];
        if (gain < INT32_MIN || gain > INT32_MAX) return -1;
        altitude += gain;
        if (altitude > maximum) maximum = altitude;
    }
    return maximum;
}
