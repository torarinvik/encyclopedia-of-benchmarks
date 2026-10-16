// Find the first odd prime index whose source remainder exceeds the limit.
module problem123;

const long MAX_LIMIT = 10000000000;
const long PRIME_LIMIT = 300000;

fn long problem123(long limit) @export("problem123") {
    if (limit > MAX_LIMIT) return -1;
    bool[PRIME_LIMIT + 1] composite = {false};
    for (long factor = 2; factor * factor <= PRIME_LIMIT; factor++) {
        if (!composite[factor])
            for (long multiple = factor * factor; multiple <= PRIME_LIMIT; multiple += factor)
                composite[multiple] = true;
    }
    long n = 1;
    bool skip_next = false;
    for (long candidate = 2; candidate <= PRIME_LIMIT; candidate++) {
        if (composite[candidate]) continue;
        if (skip_next) { skip_next = false; continue; }
        if (2 * candidate * n > limit) return n;
        skip_next = true;
        n += 2;
    }
    return -1;
}
