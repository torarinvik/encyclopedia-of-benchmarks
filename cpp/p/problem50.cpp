#include <cstdint>
#include <cstring>

extern "C" std::int64_t problem50(std::int64_t ceiling) noexcept
{
    if (ceiling < 3 || ceiling > 1000000) return -1;
    bool is_prime[1000000];
    for (std::int64_t index = 0; index < ceiling; ++index) is_prime[index] = true;
    is_prime[0] = false;
    is_prime[1] = false;
    for (std::int64_t value = 2; value <= (ceiling - 1) / value; ++value) {
        if (!is_prime[value]) continue;
        for (std::int64_t multiple = value * value; multiple < ceiling; multiple += value) {
            is_prime[multiple] = false;
        }
    }
    int primes[100000];
    int prime_count = 0;
    for (int value = 2; value < ceiling; ++value) if (is_prime[value]) primes[prime_count++] = value;
    int longest = 0;
    std::int64_t largest = 0;
    for (int start = 0; start < prime_count; ++start) {
        const int end_start = start + longest;
        int end = start;
        std::int64_t sum = 0;
        for (int finish = end_start; finish < prime_count; ++finish) {
            while (end < finish) sum += primes[end++];
            if (sum >= ceiling) break;
            if (is_prime[sum]) {
                longest = finish - start;
                largest = sum;
            }
        }
    }
    return largest;
}
