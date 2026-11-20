#include <cstddef>
#include <cstdint>

static constexpr std::size_t MAX_PARSEABLE_LENGTH = 2;
static constexpr std::int64_t MAX_N = 10;
static constexpr std::int64_t SEARCH_MAX = 64;

static bool is_prime_trial(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

extern "C" std::int64_t fortunate_numbers(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;

    const std::int64_t n = input[0];
    std::int64_t primorial = 1;
    std::int64_t primes_found = 0;
    for (std::int64_t candidate = 2; primes_found < n; ++candidate) {
        if (is_prime_trial(candidate)) {
            primorial *= candidate;
            ++primes_found;
        }
    }
    for (std::int64_t offset = 2; offset <= SEARCH_MAX; ++offset) {
        if (is_prime_trial(primorial + offset)) return offset;
    }
    return -2;
}
