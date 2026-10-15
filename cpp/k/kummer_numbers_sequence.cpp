#include <cstdint>

static bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t factor = 2; factor <= value / factor; ++factor) {
        if (value % factor == 0) return false;
    }
    return true;
}

extern "C" std::int64_t kummer_numbers_sequence(std::int64_t index) {
    if (index < 0 || index > 14) return -1;
    std::int64_t product = 1;
    std::int64_t prime_count = 0;
    for (std::int64_t candidate = 2; prime_count < index + 1; ++candidate) {
        if (is_prime(candidate)) {
            product *= candidate;
            ++prime_count;
        }
    }
    return product - 1;
}
