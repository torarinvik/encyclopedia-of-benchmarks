// Exact-cycle sociable-number check adapted from the pinned Java source.
#include <cstdint>

static std::uint64_t sum_proper_divisors(std::uint64_t number)
{
    if (number <= 1) return 0;
    std::uint64_t sum = 1;
    for (std::uint64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) {
            const auto other = number / divisor;
            sum += divisor;
            if (other != divisor) sum += other;
        }
    }
    return sum;
}

extern "C" std::int64_t sociable_number(std::uint64_t number, std::uint64_t cycle_length) noexcept
{
    if (number == 0 || number > 100000 || cycle_length < 2 || cycle_length > 3) return -1;
    auto current = number;
    for (std::uint64_t step = 0; step < cycle_length; ++step) {
        current = sum_proper_divisors(current);
        if (current == number) return step == cycle_length - 1 ? 1 : 0;
    }
    return 0;
}
