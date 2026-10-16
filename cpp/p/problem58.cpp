#include <cmath>

namespace {
bool is_prime(long long value) noexcept
{
    if (value < 2) return false;
    if (value < 4) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (long long divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}
}

extern "C" double problem58(double ratio) noexcept
{
    if (!(ratio >= 0.1 && ratio <= 0.6)) return -1.0;
    long long side = 3;
    long long prime_count = 3;
    while (static_cast<double>(prime_count) / static_cast<double>(2 * side - 1) >= ratio) {
        const long long square = side * side;
        const long long step = side + 1;
        if (is_prime(square + step)) ++prime_count;
        if (is_prime(square + 2 * step)) ++prime_count;
        if (is_prime(square + 3 * step)) ++prime_count;
        side += 2;
    }
    return static_cast<double>(side);
}
