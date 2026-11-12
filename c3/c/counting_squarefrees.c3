module counting_squarefrees;

const long MAX_N = 1000000000000;
const usz MAX_ROOT = 1000000;

fn long integer_sqrt(long value) {
    long low = 1, high = MAX_ROOT.long();
    while (low < high) {
        long middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

fn long counting_squarefrees(long n) @export("counting_squarefrees") {
    if (n < 1 || n > MAX_N) return -1;
    long limit = integer_sqrt(n);
    char[MAX_ROOT + 1] mobius = zeroed;
    bool[MAX_ROOT + 1] composite = zeroed;
    for (long value = 1; value <= limit; value++) mobius[value] = 1;

    for (long prime = 2; prime <= limit; prime++) {
        if (composite[prime]) continue;
        if (prime <= limit / prime) {
            for (long multiple = prime * prime; multiple <= limit; multiple += prime)
                composite[multiple] = true;
        }
        for (long multiple = prime; multiple <= limit; multiple += prime) {
            if (mobius[multiple] == 1) mobius[multiple] = 2;
            else if (mobius[multiple] == 2) mobius[multiple] = 1;
        }
        if (prime <= limit / prime) {
            long square = prime * prime;
            for (long multiple = square; multiple <= limit; multiple += square)
                mobius[multiple] = 0;
        }
    }

    long count = 0;
    for (long divisor = 1; divisor <= limit; divisor++) {
        long quotient = n / (divisor * divisor);
        if (mobius[divisor] == 1) count += quotient;
        else if (mobius[divisor] == 2) count -= quotient;
    }
    return count;
}
