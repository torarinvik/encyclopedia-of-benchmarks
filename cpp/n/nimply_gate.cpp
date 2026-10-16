#include <cstddef>
#include <cstdint>

extern "C" std::int64_t nimply_gate(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 2) return -1;
    const auto a = values[0], b = values[1];
    if ((a != 0 && a != 1) || (b != 0 && b != 1)) return -1;
    return a == 1 && b == 0 ? 1 : 0;
}
