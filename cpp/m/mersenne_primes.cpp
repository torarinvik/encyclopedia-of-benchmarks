#include <cstdint>

extern "C" std::int64_t mersenne_primes(std::int64_t n) {
    if (n < 2 || n > 31) return -1;
    if (n == 2) return 1;
    const std::int64_t modulus = (std::int64_t{1} << n) - 1;
    std::int64_t residue = 4;
    for (std::int64_t round = 0; round < n - 2; ++round) {
        residue = (residue * residue - 2) % modulus;
    }
    return residue == 0 ? 1 : 0;
}
