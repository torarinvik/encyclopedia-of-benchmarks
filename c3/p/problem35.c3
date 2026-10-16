module problem35;

const long MAX_LIMIT = 1000000;
const usz ODD_SLOTS = 500001;

fn long problem35(long ignored) @export("problem35") {
    if (ignored != 0) return -1;
    bool[ODD_SLOTS] odd_prime;
    for (usz index = 1; index < ODD_SLOTS; index++) odd_prime[index] = true;

    for (long candidate = 3; candidate <= MAX_LIMIT / candidate; candidate += 2) {
        if (odd_prime[(usz)(candidate / 2)]) {
            for (long composite = candidate * candidate; composite <= MAX_LIMIT;
                 composite += 2 * candidate) {
                odd_prime[(usz)(composite / 2)] = false;
            }
        }
    }

    long count = 1;
    for (long number = 3; number <= MAX_LIMIT; number += 2) {
        if (!odd_prime[(usz)(number / 2)]) continue;
        long remaining = number;
        bool has_even_digit = false;
        while (remaining > 0) {
            if ((remaining % 10) % 2 == 0) {
                has_even_digit = true;
                break;
            }
            remaining /= 10;
        }
        if (has_even_digit) continue;

        long power10 = 1;
        long digits = 1;
        remaining = number;
        while (remaining >= 10) {
            power10 *= 10;
            remaining /= 10;
            digits++;
        }
        long rotation = number;
        bool circular = true;
        for (long turn = 0; turn < digits; turn++) {
            if (!odd_prime[(usz)(rotation / 2)]) {
                circular = false;
                break;
            }
            rotation = (rotation % 10) * power10 + rotation / 10;
        }
        if (circular) count++;
    }
    return count;
}
