/* Clear low set bits from the upper endpoint until it meets the lower endpoint. */
#include <cstdint>

extern "C" std::int64_t range_bitwise_and(std::uint64_t left, std::uint64_t right) noexcept {
    if (left > right || right > UINT64_C(2147483647)) return -1;
    while (left < right) right &= right - UINT64_C(1);
    return static_cast<std::int64_t>(right);
}
