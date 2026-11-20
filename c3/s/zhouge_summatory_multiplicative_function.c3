module zhouge_summatory_multiplicative_function;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const long MODULUS = 469762049;
const long MAX_N = 10000000;

fn long floor_sqrt(long value) {
    long low = 1, high = 3162;
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

fn long quotient_at(usz index, long n, usz high_count, usz size) {
    return index < high_count ? n / index.long() : (size - index).long();
}

fn usz value_index(long value, long n, long root, usz size) {
    return value <= root ? size - value.usz() : (n / value).usz();
}

fn void apply_skipped_prime_range(usz index, usz stage,
        u32* small_lo, u32* small_hi, u32* simple_cursor,
        long* prefix_g, long* smooth_sum) {
    u32 next = stage.u32() + 1;
    if (next < small_lo[index]) next = small_lo[index];
    if (next > small_hi[index]) next = small_hi[index];
    u32 old = simple_cursor[index];
    if (next < old) {
        smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[old.usz()] - prefix_g[next.usz()]);
        simple_cursor[index] = next;
    }
}

fn void apply_skipped_power_sums(usz index, usz stage,
        u32* small_lo, u32* small_hi, u32* g_cursor,
        long* prefix_sum, long* g_zero, long* g_one) {
    u32 next = stage.u32();
    if (next < small_lo[index]) next = small_lo[index];
    if (next > small_hi[index]) next = small_hi[index];
    u32 old = g_cursor[index];
    if (next > old) {
        g_zero[index] = normalize(g_zero[index] - (next - old).long());
        g_one[index] = normalize(g_one[index] - (prefix_sum[next.usz()] - prefix_sum[old.usz()]));
        g_cursor[index] = next;
    }
}

fn long small_value(long value, u32* smallest, long a, long b) {
    long remaining = value, result = 1;
    while (remaining > 1) {
        long prime = smallest[remaining.usz()].long();
        long exponent = 0;
        while (remaining % prime == 0) {
            remaining = remaining / prime;
            exponent += 1;
        }
        result = result * ((a * exponent + b * prime) % MODULUS) % MODULUS;
    }
    return result;
}

fn long zhouge_summatory_multiplicative_function(long* input, usz length) @export("zhouge_summatory_multiplicative_function") {
    if (input == null || length != 3) return -1;
    long n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > MAX_N || a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;

    long root = floor_sqrt(n);
    usz high_count = (n / root).usz();
    while (high_count > 1 && n / (high_count - 1).long() == root) high_count -= 1;
    usz size = high_count + root.usz();
    usz root_size = root.usz() + 1;

    u32* smallest = (u32*)malloc(root_size * 4);
    long* primes = (long*)malloc(root_size * 8);
    long* g_zero = (long*)malloc(size * 8);
    long* g_one = (long*)malloc(size * 8);
    long* smooth_sum = (long*)malloc(size * 8);
    u32* small_lo = (u32*)malloc(size * 4);
    u32* small_hi = (u32*)malloc(size * 4);
    u32* simple_cursor = (u32*)malloc(size * 4);
    u32* g_cursor = (u32*)malloc(size * 4);
    if (smallest == null || primes == null || g_zero == null || g_one == null || smooth_sum == null ||
        small_lo == null || small_hi == null || simple_cursor == null || g_cursor == null) {
        free(smallest); free(primes); free(g_zero); free(g_one); free(smooth_sum);
        free(small_lo); free(small_hi); free(simple_cursor); free(g_cursor);
        return -1;
    }
    defer free(smallest); defer free(primes); defer free(g_zero); defer free(g_one); defer free(smooth_sum);
    defer free(small_lo); defer free(small_hi); defer free(simple_cursor); defer free(g_cursor);
    for (usz i = 0; i < root_size; i++) smallest[i] = 0;
    for (usz i = 0; i < size; i++) {
        g_zero[i] = 0; g_one[i] = 0; smooth_sum[i] = 1;
        small_lo[i] = 0; small_hi[i] = 0; simple_cursor[i] = 0; g_cursor[i] = 0;
    }

    usz prime_total = 0;
    long value = 2;
    while (value <= root) {
        if (smallest[value.usz()] != 0) { value += 1; continue; }
        smallest[value.usz()] = value.u32();
        primes[prime_total] = value;
        prime_total += 1;
        if (value <= root / value) {
            long multiple = value * value;
            while (multiple <= root) {
                if (smallest[multiple.usz()] == 0) smallest[multiple.usz()] = value.u32();
                multiple += value;
            }
        }
        value += 1;
    }
    long* prefix_sum = (long*)malloc((prime_total + 1) * 8);
    long* prefix_g = (long*)malloc((prime_total + 1) * 8);
    if (prefix_sum == null || prefix_g == null) {
        free(prefix_sum); free(prefix_g);
        return -1;
    }
    defer free(prefix_sum); defer free(prefix_g);
    prefix_sum[0] = 0; prefix_g[0] = 0;
    for (usz i = 0; i < prime_total; i++) {
        prefix_sum[i + 1] = normalize(prefix_sum[i] + primes[i]);
        prefix_g[i + 1] = normalize(prefix_g[i] + a + b * primes[i]);
    }

    for (usz index = 1; index < size; index++) {
        long y = quotient_at(index, n, high_count, size);
        usz lo = 0, hi = prime_total;
        while (lo < hi) {
            usz middle = lo + (hi - lo) / 2;
            if (primes[middle] <= floor_sqrt(y)) lo = middle + 1;
            else hi = middle;
        }
        small_lo[index] = lo.u32();
        lo = 0; hi = prime_total;
        while (lo < hi) {
            usz middle = lo + (hi - lo) / 2;
            if (primes[middle] <= y) lo = middle + 1;
            else hi = middle;
        }
        small_hi[index] = lo.u32();
        simple_cursor[index] = small_hi[index];
        g_cursor[index] = small_lo[index];
        g_zero[index] = y % MODULUS;
        long left = y, right = y + 1;
        if ((left & 1) == 0) left /= 2; else right /= 2;
        g_one[index] = (left % MODULUS) * (right % MODULUS) % MODULUS;
    }

    for (usz stage = 0; stage < prime_total; stage++) {
        long prime = primes[stage], square = prime * prime;
        for (usz index = 1; index < size; index++) {
            long y = quotient_at(index, n, high_count, size);
            if (y < square) break;
            usz child = value_index(y / prime, n, root, size);
            apply_skipped_power_sums(child, stage, small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one);
            g_zero[index] = normalize(g_zero[index] - g_zero[child]);
            g_one[index] = normalize(g_one[index] - prime * g_one[child]);
        }
    }
    for (usz index = 1; index < size; index++)
        apply_skipped_power_sums(index, prime_total, small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one);

    usz position = prime_total;
    while (position > 0) {
        position -= 1;
        long prime = primes[position], square = prime * prime;
        for (usz index = 1; index < size; index++) {
            long y = quotient_at(index, n, high_count, size);
            if (y < square) break;
            apply_skipped_prime_range(index, position, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum);
            long power = prime, exponent = 1;
            while (power <= y) {
                usz child = value_index(y / power, n, root, size);
                apply_skipped_prime_range(child, position, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum);
                long local = (a * exponent + b * prime) % MODULUS;
                smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child]);
                power *= prime;
                exponent += 1;
            }
        }
    }

    long answer = smooth_sum[1];
    for (value = 1; value <= root; value++) {
        usz child = value_index(n / value, n, root, size);
        long large_prime_sum = normalize(a * normalize(g_zero[child] - 1) + b * normalize(g_one[child] - 1));
        answer = normalize(answer + small_value(value, smallest, a, b) * large_prime_sum);
    }
    return answer;
}
