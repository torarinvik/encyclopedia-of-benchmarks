#include <cstdint>

static bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t factor = 2; factor <= value / factor; ++factor) {
        if (value % factor == 0) return false;
    }
    return true;
}

extern "C" std::int64_t number_of_primes_by_powers_of10_sequence(std::int64_t index) {
    if (index < 0 || index > 3) return -1;
    if (index == 0) return 0;
    std::int64_t upper = 10;
    for (std::int64_t i = 1; i < index; ++i) upper *= 10;
    std::int64_t count = 0;
    for (std::int64_t value = 2; value < upper; ++value) count += is_prime(value);
    return count;
}
