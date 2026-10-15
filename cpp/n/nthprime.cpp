// Expanding sieve strategy from the pinned Rust nth-prime routine.
#include <array>
#include <cstdint>

extern "C" std::int64_t nthprime(std::int64_t nth) noexcept
{
    if (nth < 1 || nth > 100) return -1;
    std::array<std::uint64_t, 1600> primes{};
    std::uint64_t total_prime = 0;
    std::uint64_t size_factor = 2;
    std::uint64_t size = static_cast<std::uint64_t>(nth) * size_factor;

    while (total_prime < static_cast<std::uint64_t>(nth)) {
        if (size > primes.size()) return -1;
        for (std::uint64_t index = 0; index < size; ++index) primes[index] = 1;
        for (std::uint64_t index = 2; index < size; ++index) {
            if (primes[index] == 1) {
                for (std::uint64_t multiple = index; multiple < size; ++multiple) {
                    const auto product = index * multiple;
                    if (product < size) primes[product] = 0;
                    else break;
                }
            }
        }
        total_prime = 0;
        for (std::uint64_t index = 2; index < size; ++index) total_prime += primes[index];
        ++size_factor;
        size = static_cast<std::uint64_t>(nth) * size_factor;
    }

    const auto used_size = size - static_cast<std::uint64_t>(nth);
    std::uint64_t count = 0;
    for (std::uint64_t index = 2; index < used_size; ++index) {
        count += primes[index];
        if (count == static_cast<std::uint64_t>(nth)) return static_cast<std::int64_t>(index);
    }
    return -1;
}
