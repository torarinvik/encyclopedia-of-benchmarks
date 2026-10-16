#include <array>
#include <cstdint>

extern "C" std::int64_t problem77(std::int64_t threshold) noexcept
{
    if (threshold < 0 || threshold > 100'000) return -1;
    std::array<std::int64_t, 100> partitions{};
    partitions[0] = 1;
    for (std::int64_t prime = 2; prime < 100; ++prime) {
        bool is_prime = true;
        for (std::int64_t divisor = 2; divisor * divisor <= prime; ++divisor) {
            if (prime % divisor == 0) { is_prime = false; break; }
        }
        if (is_prime)
            for (std::int64_t total = prime; total < 100; ++total)
                partitions[static_cast<std::size_t>(total)] += partitions[static_cast<std::size_t>(total - prime)];
    }
    for (std::int64_t value = 1; value < 100; ++value)
        if (partitions[static_cast<std::size_t>(value)] > threshold) return value;
    return -1;
}
