#include <cstddef>
#include <cstdint>

extern "C" std::int64_t matchdimensions(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return -1;
    for (std::size_t index = 0; index < 4; ++index) {
        if (values[index] < 0 || values[index] > 65535) return -1;
    }
    return values[0] == values[2] && values[1] == values[3] ? 1 : 0;
}
