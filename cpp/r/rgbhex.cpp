#include <cstddef>
#include <cstdint>

extern "C" int64_t rgbhex(const int64_t *input, std::size_t length) {
    if (input == nullptr || length != 4) return -1;
    const int64_t op = input[0], x = input[1], y = input[2], z = input[3];
    if (op == 0) {
        if (x < 0 || x > INT64_C(4294967295) || y != 0 || z != 0) return -1;
        return x & INT64_C(0x00ffffff);
    }
    if (op == 1) {
        if (x < 0 || x > 255 || y < 0 || y > 255 || z < 0 || z > 255) return -1;
        return (x << 16) | (y << 8) | z;
    }
    return -1;
}
