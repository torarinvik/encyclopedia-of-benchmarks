#include <cstdint>

extern "C" std::int64_t multiple_of_3_or_5_term(std::int64_t n) noexcept {
    if (n < 0 || n > 1'000'000'000) return -1;
    return n % 3 == 0 || n % 5 == 0 ? n : 0;
}
