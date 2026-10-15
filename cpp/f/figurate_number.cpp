// Pack triangular, tetrahedral, and pentatope membership bits.
#include <cstdint>

namespace {
bool is_triangular(std::int64_t n) {
    for (std::int64_t i = 0; i <= n; ++i) {
        const std::int64_t term = i * (i + 1) / 2;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

bool is_tetrahedral(std::int64_t n) {
    for (std::int64_t i = 1; i <= n; ++i) {
        const std::int64_t term = i * (i + 1) * (i + 2) / 6;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}

bool is_pentatope(std::int64_t n) {
    for (std::int64_t i = 1; i <= n; ++i) {
        const std::int64_t term = i * (i + 1) * (i + 2) * (i + 3) / 24;
        if (term == n) return true;
        if (term > n) return false;
    }
    return false;
}
}

extern "C" std::int64_t figurate_number(std::int64_t n) noexcept {
    if (n < 0 || n > 1000000) return -1;
    return (is_triangular(n) ? 1 : 0)
        + (is_tetrahedral(n) ? 2 : 0)
        + (is_pentatope(n) ? 4 : 0);
}
