module fermat_prime_checker;

fn int dotnet_sample(int* seed, int* next, int* next_p) {
    (*next)++;
    if (*next >= 56) *next = 1;
    (*next_p)++;
    if (*next_p >= 56) *next_p = 1;
    int value = (*seed)[*next] - (*seed)[*next_p];
    if (value == 2147483647) value--;
    if (value < 0) value += 2147483647;
    (*seed)[*next] = value;
    return value;
}

fn long mod_pow(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long fermat_prime_checker(long number, long times_to_check) @export("fermat_prime_checker") {
    if (number < 2 || number > 1000000 || times_to_check < 2 || times_to_check > 64) return -1;
    int[56] seed = {0};
    int mj = 161803398, mk = 1;
    seed[55] = mj;
    for (int i = 1; i < 55; i++) {
        int index = (21 * i) % 55;
        seed[index] = mk;
        mk = mj - mk;
        if (mk < 0) mk += 2147483647;
        mj = seed[index];
    }
    for (int pass = 0; pass < 4; pass++) {
        for (int i = 1; i < 56; i++) {
            seed[i] -= seed[1 + (i + 30) % 55];
            if (seed[i] < 0) seed[i] += 2147483647;
        }
    }
    int next = 0, next_p = 21;
    for (long iteration = 1; iteration < times_to_check; iteration++) {
        int sample = dotnet_sample(&seed[0], &next, &next_p);
        long base = ((double)sample / 2147483647.0 * (double)(number - 1)).long() + 1;
        if (mod_pow(base, number - 1, number) != 1) return 0;
    }
    return 1;
}
