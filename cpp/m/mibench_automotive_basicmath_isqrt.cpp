#include <cstddef>
#include <cstdint>

extern "C" std::int64_t mibench_automotive_basicmath_isqrt(const std::int64_t *input,
                                                            std::size_t length) {
    if (input == nullptr || length != 1 || input[0] < 0 || input[0] > 65535) return -1;
    std::uint32_t x = static_cast<std::uint32_t>(input[0]);
    std::uint32_t root = 0, remainder = 0;
    for (unsigned int step = 0; step < 32; ++step) {
        remainder = (remainder << 2) + (x >> 30);
        x <<= 2;
        root <<= 1;
        const std::uint32_t trial = (root << 1) + 1;
        if (remainder >= trial) {
            remainder -= trial;
            ++root;
        }
    }
    return static_cast<std::int64_t>(root);
}
