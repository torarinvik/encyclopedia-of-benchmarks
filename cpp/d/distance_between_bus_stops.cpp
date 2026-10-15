#include <cstddef>
#include <cstdint>

extern "C" int64_t distance_between_bus_stops(const int64_t *input, size_t length) {
    if (length < 3 || length > 66) {
        return -1;
    }

    const size_t stop_count = length - 2;
    const int64_t start = input[0];
    const int64_t destination = input[1];
    if (start < 0 || destination < 0
            || start >= static_cast<int64_t>(stop_count)
            || destination >= static_cast<int64_t>(stop_count)) {
        return -1;
    }

    const size_t low = static_cast<size_t>(start < destination ? start : destination);
    const size_t high = static_cast<size_t>(start < destination ? destination : start);
    int64_t total = 0;
    int64_t direct = 0;
    for (size_t index = 0; index < stop_count; ++index) {
        const int64_t distance = input[index + 2];
        if (distance < 0 || distance > 1000000) {
            return -1;
        }
        total += distance;
        if (index >= low && index < high) {
            direct += distance;
        }
    }
    const int64_t other = total - direct;
    return direct < other ? direct : other;
}
