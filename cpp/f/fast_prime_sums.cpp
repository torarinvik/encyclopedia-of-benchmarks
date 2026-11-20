#include <cstdint>
#include <vector>

namespace {
constexpr int SIEVE_LIMIT = 32000;
constexpr int PRIME_CAPACITY = 3500;
constexpr int PHI_ROWS = 12;
constexpr int PHI_COLUMNS = 30000;

struct PrimeSumContext {
    std::vector<bool> composite = std::vector<bool>(SIEVE_LIMIT + 1, false);
    std::vector<int> primes;
    std::vector<int> prime_count = std::vector<int>(SIEVE_LIMIT + 1, 0);
    std::vector<std::int64_t> prime_sum = std::vector<std::int64_t>(SIEVE_LIMIT + 1, 0);
    std::vector<std::int64_t> phi = std::vector<std::int64_t>(PHI_ROWS * PHI_COLUMNS, 0);

    PrimeSumContext() {
        primes.reserve(PRIME_CAPACITY);
        for (int candidate = 2; candidate * candidate <= SIEVE_LIMIT; ++candidate) {
            if (composite[candidate]) continue;
            for (int multiple = candidate * candidate; multiple <= SIEVE_LIMIT; multiple += candidate)
                composite[multiple] = true;
        }
        for (int candidate = 2; candidate <= SIEVE_LIMIT; ++candidate) {
            if (!composite[candidate]) primes.push_back(candidate);
            prime_count[candidate] = prime_count[candidate - 1] + !composite[candidate];
            prime_sum[candidate] = prime_sum[candidate - 1] +
                (composite[candidate] ? 0 : candidate);
        }
        for (int n = 0; n < PHI_COLUMNS; ++n)
            phi[n] = static_cast<std::int64_t>(n) * (n + 1) / 2;
        for (int row = 1; row < PHI_ROWS; ++row) {
            const std::int64_t prime = primes[row - 1];
            const int previous = (row - 1) * PHI_COLUMNS;
            const int current = row * PHI_COLUMNS;
            for (int n = 0; n < PHI_COLUMNS; ++n)
                phi[current + n] = phi[previous + n] - prime * phi[previous + n / prime];
        }
    }

    static std::int64_t sqrt_floor(std::int64_t n) {
        std::int64_t low = 0, high = n + 1;
        while (low + 1 < high) {
            const auto middle = low + (high - low) / 2;
            if (middle <= n / middle) low = middle;
            else high = middle;
        }
        return low;
    }

    static std::int64_t cbrt_floor(std::int64_t n) {
        std::int64_t low = 0, high = 1;
        while (high * high * high <= n) high *= 2;
        while (low + 1 < high) {
            const auto middle = low + (high - low) / 2;
            if (middle * middle * middle <= n) low = middle;
            else high = middle;
        }
        return low;
    }

    std::int64_t partial_sum(std::int64_t n, int count) const {
        if (n <= 0) return 0;
        if (count == 0) return n * (n + 1) / 2;
        const std::int64_t prime = primes[count - 1];
        if (n <= prime) return 1;
        if (count < PHI_ROWS && n < PHI_COLUMNS) return phi[count * PHI_COLUMNS + n];
        if (n < SIEVE_LIMIT && prime * prime >= n) return prime_sum[n] - prime_sum[prime] + 1;
        if (n < SIEVE_LIMIT && prime * prime * prime >= n) {
            std::int64_t result = prime_sum[n] - prime_sum[prime] + 1;
            const int limit = prime_count[sqrt_floor(n)];
            for (int i = count; i < limit; ++i) {
                const std::int64_t other = primes[i];
                result += other * (prime_sum[n / other] - prime_sum[other - 1]);
            }
            return result;
        }
        return partial_sum(n, count - 1) - prime * partial_sum(n / prime, count - 1);
    }

    std::int64_t query(std::int64_t n) const {
        if (n <= SIEVE_LIMIT) return prime_sum[n];
        const int first = prime_count[cbrt_floor(n)];
        const int last = prime_count[sqrt_floor(n)];
        std::int64_t result = partial_sum(n, first) + prime_sum[cbrt_floor(n)] - 1;
        for (int i = first; i < last; ++i) {
            const std::int64_t prime = primes[i];
            const std::int64_t quotient = n / prime;
            result -= (query(quotient) - prime_sum[prime - 1]) * prime;
        }
        return result;
    }
};
}

extern "C" std::int64_t fast_prime_sums(std::int64_t value) noexcept {
    if (value < 0 || value > 1000000000LL) return -1;
    PrimeSumContext context;
    return context.query(value);
}
