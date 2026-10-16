#include <cstdint>
extern "C" std::int64_t problem53(std::int64_t unused) noexcept {
    if (unused != 0) return -1;
    std::int64_t total = 0;
    for (int n = 1; n <= 100; ++n) {
        std::int64_t coefficient = 1;
        for (int r = 1; r <= n / 2; ++r) {
            coefficient = coefficient * (n - r + 1) / r;
            if (coefficient > 1'000'000) { total += n - 2 * r + 1; break; }
        }
    }
    return total;
}
