// Recursive Sylvester recurrence on the signed 64-bit benchmark domain.
#include <cstdint>

static std::int64_t sylvester_term(std::int64_t n)
{
    if (n == 1) return 2;
    const auto previous = sylvester_term(n - 1);
    return previous * (previous - 1) + 1;
}

extern "C" std::int64_t sylvester_sequence(std::int64_t n) noexcept
{
    if (n < 1 || n > 7) return -1;
    return sylvester_term(n);
}
