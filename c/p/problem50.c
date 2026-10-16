#include <stdint.h>
#include <string.h>

int64_t problem50(int64_t ceiling)
{
    if (ceiling < 3 || ceiling > 1000000) return -1;
    uint8_t is_prime[1000000];
    memset(is_prime, 1, (size_t)ceiling);
    is_prime[0] = 0;
    is_prime[1] = 0;
    for (int64_t value = 2; value <= (ceiling - 1) / value; ++value) {
        if (!is_prime[value]) continue;
        for (int64_t multiple = value * value; multiple < ceiling; multiple += value) {
            is_prime[multiple] = 0;
        }
    }
    int primes[100000];
    int prime_count = 0;
    for (int value = 2; value < ceiling; ++value) {
        if (is_prime[value]) primes[prime_count++] = value;
    }
    int longest = 0;
    int64_t largest = 0;
    for (int start = 0; start < prime_count; ++start) {
        int end_start = start + longest;
        int end = start;
        int64_t sum = 0;
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
