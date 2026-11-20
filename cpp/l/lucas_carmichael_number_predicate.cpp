#include <cstdint>

extern "C" std::int64_t lucas_carmichael_number_predicate(
    const std::int64_t *input, std::uint64_t length) noexcept
{
    if (input == nullptr || length != 1) return -1;
    const std::int64_t value = input[0];
    if (value < 1 || value > 1'000'000) return -1;

    std::int64_t remaining = value;
    std::int64_t divisor = 2;
    bool composite = false;
    while (divisor <= remaining / divisor) {
        if (remaining % divisor == 0) {
            composite = true;
            int exponent = 0;
            do {
                remaining /= divisor;
                ++exponent;
            } while (remaining % divisor == 0);
            if (exponent != 1 || (value + 1) % (divisor + 1) != 0) return 0;
        }
        ++divisor;
    }
    if (remaining > 1) {
        if (!composite || (value + 1) % (remaining + 1) != 0) return 0;
    }
    return composite ? 1 : 0;
}
