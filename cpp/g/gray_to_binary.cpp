#include <cstdint>

extern "C" std::int64_t gray_to_binary(std::int64_t gray) noexcept
{
    if (gray < 0) return -1;
    std::int64_t binary = gray;
    gray >>= 1;
    while (gray != 0) {
        binary ^= gray;
        gray >>= 1;
    }
    return binary;
}
