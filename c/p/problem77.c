#include <stdint.h>

int64_t problem77(int64_t threshold)
{
    if (threshold < 0 || threshold > 100000) return -1;
    int64_t partitions[100] = {0};
    partitions[0] = 1;
    for (int64_t prime = 2; prime < 100; ++prime) {
        int is_prime = 1;
        for (int64_t divisor = 2; divisor * divisor <= prime; ++divisor)
            if (prime % divisor == 0) { is_prime = 0; break; }
        if (is_prime)
            for (int64_t total = prime; total < 100; ++total)
                partitions[total] += partitions[total - prime];
    }
    for (int64_t value = 1; value < 100; ++value)
        if (partitions[value] > threshold) return value;
    return -1;
}
