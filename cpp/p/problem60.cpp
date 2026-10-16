/* Source-ordered concatenatable-prime search for Project Euler 60. */
#include <cstdint>

namespace {
constexpr int MAX_PRIMES = 1000;
constexpr int TARGET_SIZE = 5;

bool is_prime(std::int64_t value)
{
    if (value < 2) return false;
    if (value == 2 || value == 3) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (std::int64_t divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}

std::int64_t concatenate(std::int64_t left, std::int64_t right)
{
    std::int64_t scale = 10;
    while (scale <= right) scale *= 10;
    return left * scale + right;
}

bool pair_works(int left_index, int right_index, const int* primes, std::uint8_t* cache)
{
    const int key = left_index * MAX_PRIMES + right_index;
    if (cache[key] != 0) return cache[key] == 2;
    const int reverse_key = right_index * MAX_PRIMES + left_index;
    if (cache[reverse_key] != 0) return cache[reverse_key] == 2;
    const std::int64_t left = primes[left_index];
    const std::int64_t right = primes[right_index];
    const bool result = is_prime(concatenate(left, right))
                     && is_prime(concatenate(right, left));
    cache[key] = cache[reverse_key] = result ? 2 : 1;
    return result;
}

std::int64_t search_set(const int* primes, int prime_count, std::uint8_t* cache,
                        int* chain, int depth, int start, std::int64_t sum)
{
    if (depth == TARGET_SIZE) return sum;
    for (int index = start; index < prime_count; ++index) {
        bool compatible = true;
        for (int member = 0; member < depth; ++member) {
            if (!pair_works(index, chain[member], primes, cache)) {
                compatible = false;
                break;
            }
        }
        if (!compatible) continue;
        chain[depth] = index;
        const std::int64_t result = search_set(primes, prime_count, cache, chain,
                                               depth + 1, index + 1,
                                               sum + primes[index]);
        if (result != 0) return result;
    }
    return 0;
}
} // namespace

extern "C" std::int64_t problem60(std::int64_t placeholder) noexcept
{
    if (placeholder != 0) return -1;
    int primes[MAX_PRIMES] = {3, 7, 13, 19};
    std::uint8_t cache[MAX_PRIMES * MAX_PRIMES] = {};
    int chain[TARGET_SIZE] = {};
    int prime_count = 4;
    while (prime_count < MAX_PRIMES) {
        std::int64_t candidate = primes[prime_count - 1] + 3;
        while (!is_prime(candidate)) candidate += 3;
        primes[prime_count++] = static_cast<int>(candidate);
    }
    for (int start = 0; start < prime_count; ++start) {
        chain[0] = start;
        const std::int64_t result = search_set(primes, prime_count, cache, chain,
                                               1, start + 1, primes[start]);
        if (result != 0) return result;
    }
    return -1;
}
