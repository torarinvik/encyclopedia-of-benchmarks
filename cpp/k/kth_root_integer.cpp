#include <cstddef>
#include <cstdint>

namespace {
bool power_at_most(std::int64_t base, std::int64_t exponent,
                   std::int64_t limit) noexcept {
    if (base == 0) return true;
    std::int64_t product = 1;
    while (exponent > 0) {
        if (product > limit / base) return false;
        product *= base;
        --exponent;
    }
    return true;
}
} // namespace

extern "C" std::int64_t kth_root_integer(const std::int64_t* input,
                                          std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t number = input[0];
    const std::int64_t degree = input[1];
    if (number < 0 || degree < 1 || degree > 64) return -1;

    std::int64_t low = 0;
    std::int64_t high = number;
    while (low < high) {
        const std::int64_t difference = high - low;
        const std::int64_t candidate = low + difference / 2 + difference % 2;
        if (power_at_most(candidate, degree, number)) low = candidate;
        else high = candidate - 1;
    }
    return low;
}
