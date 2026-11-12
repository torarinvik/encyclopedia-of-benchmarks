module sum_of_multiplicative_function_large;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const long MODULUS = 469762049;
const long MAX_N = 100000000;

fn long floor_sqrt(long value) {
    long low = 1, high = 31623;
    while (low < high) {
        long middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

fn long normalize(long value) {
    value = value % MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long triangular_mod(long value) {
    long left = value, right = value + 1;
    if ((left & 1) == 0) left /= 2;
    else right /= 2;
    return ((left % MODULUS) * (right % MODULUS)) % MODULUS;
}

fn usz value_index(long value, long n, long root, usz size) {
    if (value <= root) return size - value.usz();
    return (n / value).usz();
}

fn long sum_of_multiplicative_function_large(long* input, usz length) @export("sum_of_multiplicative_function_large") {
    if (input == null || length != 3) return -1;
    long n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > MAX_N || a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;

    long root = floor_sqrt(n);
    usz high_count = (n / root).usz();
    while (high_count > 1 && n / (high_count - 1).long() == root) high_count -= 1;
    usz size = high_count + root.usz();
    long* quotients = (long*)malloc(size * 8);
    long* prime_count = (long*)malloc(size * 8);
    long* prime_sum = (long*)malloc(size * 8);
    u8* composite = (u8*)malloc((root.usz() + 1) * 1);
    long* primes = (long*)malloc((root.usz() + 1) * 8);
    long* values = (long*)malloc(size * 8);
    long* next_values = (long*)malloc(size * 8);
    if (quotients == null || prime_count == null || prime_sum == null || composite == null ||
        primes == null || values == null || next_values == null) {
        free(quotients); free(prime_count); free(prime_sum); free(composite);
        free(primes); free(values); free(next_values);
        return -1;
    }
    defer free(quotients);
    defer free(prime_count);
    defer free(prime_sum);
    defer free(composite);
    defer free(primes);
    defer free(values);
    defer free(next_values);
    for (usz i = 0; i < size; i++) {
        quotients[i] = 0; prime_count[i] = 0; prime_sum[i] = 0;
        values[i] = 0; next_values[i] = 0;
    }
    for (usz i = 0; i <= root.usz(); i++) composite[i] = 0;

    for (usz i = 1; i < high_count; i++) quotients[i] = n / i.long();
    for (long value = 1; value <= root; value++) quotients[size - value.usz()] = value;

    usz prime_total = 0;
    for (long value = 2; value <= root; value++) {
        if (composite[value.usz()] != 0) continue;
        primes[prime_total] = value;
        prime_total += 1;
        if (value <= root / value) {
            for (long multiple = value * value; multiple <= root; multiple += value)
                composite[multiple.usz()] = 1;
        }
    }

    for (usz i = 1; i < size; i++) {
        prime_count[i] = quotients[i] - 1;
        prime_sum[i] = normalize(triangular_mod(quotients[i]) - 1);
    }
    long preceding_count = 0, preceding_sum = 0;
    for (usz p_index = 0; p_index < prime_total; p_index++) {
        long prime = primes[p_index], square = prime * prime;
        for (usz i = 1; i < size && quotients[i] >= square; i++) {
            usz quotient_index = value_index(quotients[i] / prime, n, root, size);
            prime_count[i] -= prime_count[quotient_index] - preceding_count;
            long sum_delta = normalize(prime_sum[quotient_index] - preceding_sum);
            prime_sum[i] = normalize(prime_sum[i] - (prime % MODULUS) * sum_delta);
        }
        preceding_count += 1;
        preceding_sum = normalize(preceding_sum + prime);
    }
    for (usz i = 1; i < size; i++) {
        values[i] = (a * (prime_count[i] % MODULUS) + b * prime_sum[i]) % MODULUS;
        next_values[i] = values[i];
    }

    usz position = prime_total;
    while (position > 0) {
        position -= 1;
        long prime = primes[position], power = prime, exponent = 1;
        long prime_prefix = values[value_index(prime, n, root, size)];
        while (n / prime >= power) {
            long local = (a * exponent + b * prime) % MODULUS;
            long next_local = (a * (exponent + 1) + b * prime) % MODULUS;
            long next_power = power * prime;
            for (usz i = 1; i < size && next_power <= quotients[i]; i++) {
                usz quotient_index = value_index(quotients[i] / power, n, root, size);
                long non_prime_sum = normalize(values[quotient_index] - prime_prefix);
                next_values[i] = normalize(next_values[i] + local * non_prime_sum + next_local);
            }
            power = next_power;
            exponent += 1;
        }
        usz copied = value_index(prime * prime, n, root, size) + 1;
        if (copied > size) copied = size;
        for (usz i = 0; i < copied; i++) values[i] = next_values[i];
    }
    return normalize(values[value_index(n, n, root, size)] + 1);
}
