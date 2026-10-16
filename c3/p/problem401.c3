module problem401;

const long MAX_LIMIT = 1000;
const long MOD_LIMIT = 1000000000;

fn bool contains(long value, long* divisors, long length) {
    for (long i = 0; i < length; i++) if (divisors[i] == value) return true;
    return false;
}
fn long get_divisors(long number, long* divisors) {
    if (number == 1) { divisors[0] = 1; return 1; }
    long count = 0;
    for (long i = 1; i * i <= number + 1; i++) if (number % i == 0) {
        long quotient = number / i;
        if (!contains(i, divisors, count)) divisors[count++] = i;
        if (!contains(quotient, divisors, count)) divisors[count++] = quotient;
    }
    return count;
}
fn long sigma2_source(long number) {
    long[128] divisors = {0};
    long count = get_divisors(number, &divisors[0]);
    long sum = 0;
    for (long i = 1; i < count; i++) sum += (divisors[i] * divisors[i]) % MOD_LIMIT;
    return sum % MOD_LIMIT;
}
fn long problem401(long limit) @export("problem401") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long sum = 0;
    for (long number = 0; number <= limit; number++) sum += sigma2_source(number);
    return sum % MOD_LIMIT;
}
