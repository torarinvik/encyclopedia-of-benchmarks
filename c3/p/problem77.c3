module problem77;

fn long problem77(long threshold) @export("problem77") {
    if (threshold < 0 || threshold > 100000) return -1;
    long[100] partitions = {0};
    partitions[0] = 1;
    for (long prime = 2; prime < 100; prime++) {
        bool is_prime = true;
        for (long divisor = 2; divisor * divisor <= prime; divisor++) {
            if (prime % divisor == 0) { is_prime = false; break; }
        }
        if (is_prime) {
            for (long total = prime; total < 100; total++)
                partitions[total] += partitions[total - prime];
        }
    }
    for (long value = 1; value < 100; value++)
        if (partitions[value] > threshold) return value;
    return -1;
}
