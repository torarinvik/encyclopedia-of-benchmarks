module miller_rabin_primality_checker;

fn ulong next_word(ulong* state) {
    *state += 0x9e3779b97f4a7c15u64;
    ulong z = *state;
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9u64;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebu64;
    return z ^ (z >> 31);
}
fn long mod_power(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}
fn bool passes_witness(long n, long a, long d, long powers_of_two) {
    long x = mod_power(a, d, n);
    if (x == 1 || x == n - 1) return true;
    for (long round = 1; round < powers_of_two; round++) {
        x = (x * x) % n;
        if (x == n - 1) return true;
    }
    return false;
}

fn long miller_rabin_primality_checker(long* values, usz length) @export("miller_rabin_primality_checker") {
    if (values == null || length < 3 || length > 4) return -1;
    long n = values[0], rounds = values[1], seed = values[2];
    if (length != 3 || n < 5 || n > 2147483647 || (n & 1) == 0 || rounds < 1 || rounds > 64 || seed < 0 || seed > 2147483647) return -1;
    ulong state = (ulong)seed;
    ulong span = (ulong)(n - 4);
    ulong threshold = (0u64 - span) % span;
    ulong word;
    while (true) { word = next_word(&state); if (word >= threshold) break; }
    long a = 2 + (long)(word % span);
    long d = n - 1, powers_of_two = 0;
    while ((d & 1) == 0) { d >>= 1; powers_of_two++; }
    for (long i = 0; i < rounds; i++) if (!passes_witness(n, a, d, powers_of_two)) return 0;
    return 1;
}
