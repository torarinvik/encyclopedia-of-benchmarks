// Min_25 sieve for f(p^e) = a*e + b*p modulo 469762049.
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace {
constexpr std::int64_t modulus = 469'762'049;
constexpr std::int64_t max_n = 100'000'000;

std::int64_t floor_sqrt(std::int64_t value)
{
    std::int64_t low = 1, high = 31'623;
    while (low < high) {
        const auto middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

std::int64_t normalize(std::int64_t value)
{
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::int64_t triangular_mod(std::int64_t value)
{
    auto left = value;
    auto right = value + 1;
    if ((left & 1) == 0) left /= 2;
    else right /= 2;
    return ((left % modulus) * (right % modulus)) % modulus;
}

std::size_t value_index(std::int64_t value, std::int64_t n,
                        std::int64_t root, std::size_t size)
{
    return value <= root ? size - static_cast<std::size_t>(value)
                         : static_cast<std::size_t>(n / value);
}
} // namespace

extern "C" std::int64_t sum_of_multiplicative_function_large(const std::int64_t* input,
                                                               std::size_t length)
{
    if (input == nullptr || length != 3) return -1;
    const auto n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > max_n || a < 0 || a >= modulus || b < 0 || b >= modulus) return -1;

    const auto root = floor_sqrt(n);
    auto high_count = static_cast<std::size_t>(n / root);
    while (high_count > 1 && n / static_cast<std::int64_t>(high_count - 1) == root) --high_count;
    const auto size = high_count + static_cast<std::size_t>(root);
    std::vector<std::int64_t> quotients(size, 0);
    std::vector<std::int64_t> prime_count(size, 0);
    std::vector<std::int64_t> prime_sum(size, 0);
    std::vector<std::uint8_t> composite(static_cast<std::size_t>(root) + 1, 0);
    std::vector<std::int64_t> primes;
    for (std::int64_t value = 2; value <= root; ++value) {
        if (composite[static_cast<std::size_t>(value)] != 0) continue;
        primes.push_back(value);
        if (value <= root / value) {
            for (auto multiple = value * value; multiple <= root; multiple += value)
                composite[static_cast<std::size_t>(multiple)] = 1;
        }
    }

    for (std::size_t i = 1; i < high_count; ++i) quotients[i] = n / static_cast<std::int64_t>(i);
    for (std::int64_t value = 1; value <= root; ++value)
        quotients[size - static_cast<std::size_t>(value)] = value;

    for (std::size_t i = 1; i < size; ++i) {
        prime_count[i] = quotients[i] - 1;
        prime_sum[i] = normalize(triangular_mod(quotients[i]) - 1);
    }
    std::int64_t preceding_count = 0, preceding_sum = 0;
    for (const auto prime : primes) {
        const auto square = prime * prime;
        for (std::size_t i = 1; i < size && quotients[i] >= square; ++i) {
            const auto quotient_index = value_index(quotients[i] / prime, n, root, size);
            prime_count[i] -= prime_count[quotient_index] - preceding_count;
            const auto sum_delta = normalize(prime_sum[quotient_index] - preceding_sum);
            prime_sum[i] = normalize(prime_sum[i] - (prime % modulus) * sum_delta);
        }
        ++preceding_count;
        preceding_sum = normalize(preceding_sum + prime);
    }

    std::vector<std::int64_t> prime_f(size, 0);
    for (std::size_t i = 1; i < size; ++i)
        prime_f[i] = (a * (prime_count[i] % modulus) + b * prime_sum[i]) % modulus;
    auto values = prime_f;
    auto next_values = prime_f;

    for (std::size_t position = primes.size(); position-- > 0;) {
        const auto prime = primes[position];
        auto power = prime;
        std::int64_t exponent = 1;
        const auto prime_prefix = prime_f[value_index(prime, n, root, size)];
        while (n / prime >= power) {
            const auto local = (a * exponent + b * prime) % modulus;
            const auto next_local = (a * (exponent + 1) + b * prime) % modulus;
            const auto next_power = power * prime;
            for (std::size_t i = 1; i < size && next_power <= quotients[i]; ++i) {
                const auto quotient_index = value_index(quotients[i] / power, n, root, size);
                const auto non_prime_sum = normalize(values[quotient_index] - prime_prefix);
                next_values[i] = normalize(next_values[i] + local * non_prime_sum + next_local);
            }
            power = next_power;
            ++exponent;
        }
        auto copied = value_index(prime * prime, n, root, size) + 1;
        if (copied > size) copied = size;
        for (std::size_t i = 0; i < copied; ++i) values[i] = next_values[i];
    }

    const auto answer_index = value_index(n, n, root, size);
    return normalize(values[answer_index] + 1);
}
