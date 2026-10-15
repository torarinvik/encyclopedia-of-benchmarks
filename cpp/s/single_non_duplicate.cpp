// Binary search the pair alignment around the unique value.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1025;
constexpr std::int64_t invalid_result = -2'147'483'649;
}

extern "C" std::int64_t single_non_duplicate(const std::int64_t *values,
                                              std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_values || length % 2 == 0)
        return invalid_result;
    std::size_t left = 0;
    std::size_t right = length - 1;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (middle % 2 == 0) {
            if (values[middle] == values[middle + 1]) left = middle + 2;
            else right = middle;
        } else {
            if (values[middle] == values[middle - 1]) left = middle + 1;
            else right = middle - 1;
        }
    }
    return values[left];
}
