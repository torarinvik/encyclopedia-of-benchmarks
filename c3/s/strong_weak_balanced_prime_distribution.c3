module strong_weak_balanced_prime_distribution;

const long MAX_LIMIT = 100000;
const usz SIEVE_LENGTH = 200001;

fn long strong_weak_balanced_prime_distribution(long* input, usz length) @export("strong_weak_balanced_prime_distribution") {
    if (input == null || length < 1 || length > 2) return -1;
    long limit = input[0];
    if (length != 1 || limit < 3 || limit > MAX_LIMIT) return -1;

    long ceiling = 2 * limit;
    bool[SIEVE_LENGTH] prime = {};
    for (usz index = 0; index < SIEVE_LENGTH; index += 1) prime[index] = true;
    prime[0] = false;
    prime[1] = false;
    for (long divisor = 2; divisor * divisor <= ceiling; divisor += 1) {
        if (!prime[divisor]) continue;
        for (long multiple = divisor * divisor; multiple <= ceiling; multiple += divisor)
            prime[multiple] = false;
    }

    long strong = 0, weak = 0, balanced = 0;
    long previous = 0, current = 0;
    for (long candidate = 2; candidate <= ceiling; candidate += 1) {
        if (!prime[candidate]) continue;
        if (previous != 0 && current >= 3 && current <= limit) {
            long twice = 2 * current;
            long neighbors = previous + candidate;
            if (twice > neighbors) strong += 1;
            else if (twice < neighbors) weak += 1;
            else balanced += 1;
        }
        previous = current;
        current = candidate;
    }
    return strong * 10000000000 + weak * 100000 + balanced;
}
