// Zhouge sieve for f(p^e) = a*e + b*p modulo 469762049.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t modulus = 469'762'049;
constexpr std::int64_t max_n = 10'000'000;

std::int64_t floor_sqrt(std::int64_t value)
{
    std::int64_t low = 1, high = 3162;
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

std::int64_t quotient_at(std::size_t index, std::int64_t n,
                         std::size_t high_count, std::size_t size)
{
    return index < high_count ? n / static_cast<std::int64_t>(index)
                              : static_cast<std::int64_t>(size - index);
}

std::size_t value_index(std::int64_t value, std::int64_t n,
                        std::int64_t root, std::size_t size)
{
    return value <= root ? size - static_cast<std::size_t>(value)
                         : static_cast<std::size_t>(n / value);
}

void apply_skipped_prime_range(std::size_t index, std::size_t stage,
                               const std::vector<std::uint32_t>& small_lo,
                               const std::vector<std::uint32_t>& small_hi,
                               std::vector<std::uint32_t>& simple_cursor,
                               const std::vector<std::int64_t>& prefix_g,
                               std::vector<std::int64_t>& smooth_sum)
{
    auto next = static_cast<std::uint32_t>(stage + 1);
    next = std::min(small_hi[index], std::max(small_lo[index], next));
    const auto old = simple_cursor[index];
    if (next < old) {
        smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[old] - prefix_g[next]);
        simple_cursor[index] = next;
    }
}

void apply_skipped_power_sums(std::size_t index, std::size_t stage,
                              const std::vector<std::uint32_t>& small_lo,
                              const std::vector<std::uint32_t>& small_hi,
                              std::vector<std::uint32_t>& g_cursor,
                              const std::vector<std::int64_t>& prefix_sum,
                              std::vector<std::int64_t>& g_zero,
                              std::vector<std::int64_t>& g_one)
{
    auto next = static_cast<std::uint32_t>(stage);
    next = std::min(small_hi[index], std::max(small_lo[index], next));
    const auto old = g_cursor[index];
    if (next > old) {
        g_zero[index] = normalize(g_zero[index] - static_cast<std::int64_t>(next - old));
        g_one[index] = normalize(g_one[index] - (prefix_sum[next] - prefix_sum[old]));
        g_cursor[index] = next;
    }
}

std::int64_t small_value(std::int64_t value, const std::vector<std::uint32_t>& smallest,
                         std::int64_t a, std::int64_t b)
{
    std::int64_t result = 1;
    while (value > 1) {
        const auto prime = static_cast<std::int64_t>(smallest[static_cast<std::size_t>(value)]);
        std::int64_t exponent = 0;
        do {
            value /= prime;
            ++exponent;
        } while (value > 1 && value % prime == 0);
        result = result * ((a * exponent + b * prime) % modulus) % modulus;
    }
    return result;
}
} // namespace

extern "C" std::int64_t zhouge_summatory_multiplicative_function(
    const std::int64_t* input, std::size_t length)
{
    if (input == nullptr || length != 3) return -1;
    const auto n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > max_n || a < 0 || a >= modulus || b < 0 || b >= modulus) return -1;

    const auto root = floor_sqrt(n);
    auto high_count = static_cast<std::size_t>(n / root);
    while (high_count > 1 && n / static_cast<std::int64_t>(high_count - 1) == root) --high_count;
    const auto size = high_count + static_cast<std::size_t>(root);

    std::vector<std::uint32_t> smallest(static_cast<std::size_t>(root) + 1, 0);
    std::vector<std::int64_t> primes;
    primes.reserve(static_cast<std::size_t>(root) + 1);
    for (std::int64_t value = 2; value <= root; ++value) {
        if (smallest[static_cast<std::size_t>(value)] != 0) continue;
        smallest[static_cast<std::size_t>(value)] = static_cast<std::uint32_t>(value);
        primes.push_back(value);
        if (value <= root / value) {
            for (auto multiple = value * value; multiple <= root; multiple += value) {
                auto& factor = smallest[static_cast<std::size_t>(multiple)];
                if (factor == 0) factor = static_cast<std::uint32_t>(value);
            }
        }
    }

    std::vector<std::int64_t> prefix_sum(primes.size() + 1, 0);
    std::vector<std::int64_t> prefix_g(primes.size() + 1, 0);
    for (std::size_t i = 0; i < primes.size(); ++i) {
        prefix_sum[i + 1] = normalize(prefix_sum[i] + primes[i]);
        prefix_g[i + 1] = normalize(prefix_g[i] + a + b * primes[i]);
    }

    std::vector<std::int64_t> g_zero(size, 0), g_one(size, 0), smooth_sum(size, 1);
    std::vector<std::uint32_t> small_lo(size, 0), small_hi(size, 0), simple_cursor(size, 0);
    std::vector<std::uint32_t> g_cursor(size, 0);
    for (std::size_t index = 1; index < size; ++index) {
        const auto value = quotient_at(index, n, high_count, size);
        const auto lo = std::upper_bound(primes.begin(), primes.end(), floor_sqrt(value));
        const auto hi = std::upper_bound(primes.begin(), primes.end(), value);
        small_lo[index] = static_cast<std::uint32_t>(lo - primes.begin());
        small_hi[index] = static_cast<std::uint32_t>(hi - primes.begin());
        simple_cursor[index] = small_hi[index];
        g_cursor[index] = small_lo[index];
        g_zero[index] = value % modulus;
        auto left = value, right = value + 1;
        if ((left & 1) == 0) left /= 2; else right /= 2;
        g_one[index] = (left % modulus) * (right % modulus) % modulus;
    }

    for (std::size_t stage = 0; stage < primes.size(); ++stage) {
        const auto prime = primes[stage];
        const auto square = prime * prime;
        for (std::size_t index = 1; index < size; ++index) {
            const auto value = quotient_at(index, n, high_count, size);
            if (value < square) break;
            const auto child = value_index(value / prime, n, root, size);
            apply_skipped_power_sums(child, stage, small_lo, small_hi, g_cursor,
                                     prefix_sum, g_zero, g_one);
            g_zero[index] = normalize(g_zero[index] - g_zero[child]);
            g_one[index] = normalize(g_one[index] - prime * g_one[child]);
        }
    }
    for (std::size_t index = 1; index < size; ++index) {
        apply_skipped_power_sums(index, primes.size(), small_lo, small_hi, g_cursor,
                                 prefix_sum, g_zero, g_one);
    }

    for (std::size_t stage = primes.size(); stage-- > 0;) {
        const auto prime = primes[stage];
        const auto square = prime * prime;
        for (std::size_t index = 1; index < size; ++index) {
            const auto value = quotient_at(index, n, high_count, size);
            if (value < square) break;
            apply_skipped_prime_range(index, stage, small_lo, small_hi,
                                      simple_cursor, prefix_g, smooth_sum);
            auto power = prime;
            std::int64_t exponent = 1;
            while (power <= value) {
                const auto child = value_index(value / power, n, root, size);
                apply_skipped_prime_range(child, stage, small_lo, small_hi,
                                          simple_cursor, prefix_g, smooth_sum);
                const auto local = (a * exponent + b * prime) % modulus;
                smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child]);
                power *= prime;
                ++exponent;
            }
        }
    }

    auto answer = smooth_sum[1];
    for (std::int64_t value = 1; value <= root; ++value) {
        const auto prime_sum_index = value_index(n / value, n, root, size);
        const auto large_prime_sum = normalize(
            a * normalize(g_zero[prime_sum_index] - 1) +
            b * normalize(g_one[prime_sum_index] - 1));
        answer = normalize(answer + small_value(value, smallest, a, b) * large_prime_sum);
    }
    return answer;
}
