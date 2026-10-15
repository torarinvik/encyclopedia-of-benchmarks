#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" int64_t check_if_array_is_sorted_and_rotated(const int64_t *values, size_t length) {
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < std::numeric_limits<int32_t>::min()
                || values[index] > std::numeric_limits<int32_t>::max()) return -1;
    }
    if (length == 0) return 1;
    size_t descents = 0;
    for (size_t index = 0; index < length; ++index) {
        const size_t next = (index + 1) % length;
        if (values[index] > values[next] && ++descents > 1) return 0;
    }
    return 1;
}
