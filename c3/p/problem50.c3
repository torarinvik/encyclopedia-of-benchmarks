module problem50;

fn long problem50(long ceiling) @export("problem50") {
    if (ceiling < 3 || ceiling > 1000000) return -1;
    bool[1000000] is_prime;
    for (usz index = 0; index < (usz)ceiling; index++) is_prime[index] = true;
    is_prime[0] = false;
    is_prime[1] = false;
    for (long value = 2; value <= (ceiling - 1) / value; value++) {
        if (!is_prime[(usz)value]) continue;
        for (long multiple = value * value; multiple < ceiling; multiple += value) is_prime[(usz)multiple] = false;
    }
    int[100000] primes;
    int prime_count = 0;
    for (int candidate = 2; candidate < (int)ceiling; candidate++) {
        if (is_prime[(usz)candidate]) primes[prime_count++] = candidate;
    }
    int longest = 0;
    long largest = 0;
    for (int start = 0; start < prime_count; start++) {
        int end_start = start + longest;
        int end = start;
        long sum = 0;
        for (int finish = end_start; finish < prime_count; finish++) {
            while (end < finish) sum += primes[end++];
            if (sum >= ceiling) break;
            if (is_prime[(usz)sum]) {
                longest = finish - start;
                largest = sum;
            }
        }
    }
    return largest;
}
