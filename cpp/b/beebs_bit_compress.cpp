#include <cstddef>
#include <cstdint>

extern "C" std::int64_t beebs_bit_compress(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 2 ||
        values[0] < 0 || values[0] > INT64_C(4294967295) ||
        values[1] < 0 || values[1] > INT64_C(4294967295)) {
        return -1;
    }
    auto data = static_cast<std::uint32_t>(values[0]);
    auto mask = static_cast<std::uint32_t>(values[1]);
    std::uint32_t packed = 0;
    std::uint32_t output_bit = 1;
    while (mask != 0) {
        if (mask & 1u) {
            if (data & 1u) packed |= output_bit;
            output_bit <<= 1;
        }
        data >>= 1;
        mask >>= 1;
    }
    return static_cast<std::int64_t>(packed);
}
