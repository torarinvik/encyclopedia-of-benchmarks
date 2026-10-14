module linear_sieve;

const usz PRIME_OFFSET = 4097;
const usz COUNT_INDEX = 4661;

// Count primes through limit with the linear (Euler) sieve.
fn long linear_sieve(long limit) @export("linear_sieve")
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;
    long[4662] state;
    for (usz index = 0; index < 4662; index++) state[index] = 0;
    for (long value = 2; value <= limit; value++) {
        usz value_index = (usz)value;
        if (state[value_index] == 0) {
            state[value_index] = value;
            usz count = (usz)state[COUNT_INDEX];
            state[PRIME_OFFSET + count] = value;
            state[COUNT_INDEX] = (long)(count + 1);
        }
        usz count = (usz)state[COUNT_INDEX];
        for (usz index = 0; index < count; index++) {
            long prime = state[PRIME_OFFSET + index];
            if (prime > state[value_index] || prime > limit / value) break;
            state[(usz)(value * prime)] = prime;
        }
    }
    return state[COUNT_INDEX];
}
