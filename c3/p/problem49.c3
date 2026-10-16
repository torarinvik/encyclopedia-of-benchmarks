module problem49;

const usz LIMIT = 10000;

fn long digit_signature(long value) {
    long[4] digits = {value / 1000, value / 100 % 10, value / 10 % 10, value % 10};
    for (usz first = 0; first < 4; first++) {
        for (usz second = first + 1; second < 4; second++) {
            if (digits[first] > digits[second]) {
                long temporary = digits[first];
                digits[first] = digits[second];
                digits[second] = temporary;
            }
        }
    }
    return digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3];
}

fn long problem49(long ignored) @export("problem49") {
    if (ignored != 0) return -1;
    bool[10000] prime_flags = {0};
    for (usz value = 2; value < LIMIT; value++) prime_flags[value] = true;
    for (usz prime = 2; prime * prime < LIMIT; prime++) {
        if (!prime_flags[prime]) continue;
        for (usz multiple = prime * prime; multiple < LIMIT; multiple += prime)
            prime_flags[multiple] = false;
    }
    long[1100] primes = {0};
    long[10000] signatures = {0};
    usz prime_count = 0;
    for (usz value = 1001; value < LIMIT; value += 2) {
        if (prime_flags[value]) {
            primes[prime_count] = (long)value;
            prime_count++;
            signatures[value] = digit_signature((long)value);
        }
    }
    bool[10000] seen_signatures = {0};
    long best = 0;
    for (usz seed = 0; seed < prime_count; seed++) {
        long signature = signatures[(usz)primes[seed]];
        if (seen_signatures[(usz)signature]) continue;
        seen_signatures[(usz)signature] = true;
        long[24] group = {0};
        usz group_count = 0;
        for (usz candidate = 0; candidate < prime_count; candidate++) {
            long value = primes[candidate];
            if (signatures[(usz)value] == signature) {
                group[group_count] = value;
                group_count++;
            }
        }
        bool found = false;
        for (usz first = 0; first < group_count && !found; first++) {
            for (usz second = first + 1; second < group_count && !found; second++) {
                for (usz third = second + 1; third < group_count; third++) {
                    if (group[second] - group[first] == group[third] - group[second]) {
                        long sequence = group[first] * 100000000 + group[second] * 10000 + group[third];
                        if (sequence > best) best = sequence;
                        found = true;
                        break;
                    }
                }
            }
        }
    }
    return best;
}
