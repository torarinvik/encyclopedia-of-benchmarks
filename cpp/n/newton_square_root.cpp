#include <cmath>
#include <cstdint>

extern "C" std::int64_t newton_square_root(std::int64_t value) noexcept
{
    if (value < 0 || value > INT64_C(4611686018427387903)) return -1;
    if (value == 0) return 0;

    const int bit_length = static_cast<int>(std::ceil(std::log2(static_cast<double>(value))));
    std::int64_t root = std::int64_t{1} << (bit_length / 2);
    while (!(value >= root * root && value <= root * root + root + root)) {
        root += value / root;
        root /= 2;
    }
    return root;
}
