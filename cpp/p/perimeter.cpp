#include <cstddef>
#include <cstdint>

extern "C" std::int64_t perimeter(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t sides = values[0];
    const std::int64_t side_length = values[1];
    if (sides < 3 || sides > 256 || side_length < 1 || side_length > 255) return -1;
    return sides * side_length;
}
