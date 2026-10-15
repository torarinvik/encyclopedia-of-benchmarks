// Return the parity of the set-bit count using Kernighan's bit clearing.
#include <cstdint>

extern "C" std::int64_t parity(std::int64_t number) noexcept {
    if (number < 0) return -1;
    std::int64_t result = 0;
    while (number != 0) {
        result ^= 1;
        number &= number - 1;
    }
    return result;
}
