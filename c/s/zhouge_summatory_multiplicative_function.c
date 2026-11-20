/* Zhouge sieve for f(p^e) = a*e + b*p modulo 469762049. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MODULUS INT64_C(469762049)
#define MAX_N INT64_C(10000000)

static int64_t floor_sqrt(int64_t value)
{
    int64_t low = 1, high = 3162;
    while (low < high) {
        const int64_t middle = low + (high - low + 1) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle - 1;
    }
    return low;
}

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t quotient_at(size_t index, int64_t n, int64_t root,
                           size_t high_count, size_t size)
{
    return index < high_count ? n / (int64_t)index : (int64_t)(size - index);
}

static size_t value_index(int64_t value, int64_t n, int64_t root, size_t size)
{
    return value <= root ? size - (size_t)value : (size_t)(n / value);
}

static void apply_skipped_prime_range(size_t index, size_t stage,
                                      const uint32_t *small_lo,
                                      const uint32_t *small_hi,
                                      uint32_t *simple_cursor,
                                      const int64_t *prefix_g,
                                      int64_t *smooth_sum)
{
    uint32_t next = (uint32_t)(stage + 1);
    if (next < small_lo[index]) next = small_lo[index];
    if (next > small_hi[index]) next = small_hi[index];
    const uint32_t old = simple_cursor[index];
    if (next < old) {
        smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[old] - prefix_g[next]);
        simple_cursor[index] = next;
    }
}

static void apply_skipped_power_sums(size_t index, size_t stage,
                                     const uint32_t *small_lo,
                                     const uint32_t *small_hi,
                                     uint32_t *g_cursor,
                                     const int64_t *prefix_sum,
                                     int64_t *g_zero, int64_t *g_one)
{
    uint32_t next = (uint32_t)stage;
    if (next < small_lo[index]) next = small_lo[index];
    if (next > small_hi[index]) next = small_hi[index];
    const uint32_t old = g_cursor[index];
    if (next > old) {
        g_zero[index] = normalize(g_zero[index] - (int64_t)(next - old));
        g_one[index] = normalize(g_one[index] - (prefix_sum[next] - prefix_sum[old]));
        g_cursor[index] = next;
    }
}

int64_t zhouge_summatory_multiplicative_function(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    const int64_t n = input[0], a = input[1], b = input[2];
    if (n < 1 || n > MAX_N || a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;

    const int64_t root = floor_sqrt(n);
    size_t high_count = (size_t)(n / root);
    while (high_count > 1 && n / (int64_t)(high_count - 1) == root) --high_count;
    const size_t size = high_count + (size_t)root;
    const size_t root_size = (size_t)root + 1;

    uint32_t *smallest = calloc(root_size, sizeof(*smallest));
    int32_t *primes = malloc(root_size * sizeof(*primes));
    int64_t *prefix_sum = NULL, *prefix_g = NULL;
    int64_t *g_zero = calloc(size, sizeof(*g_zero));
    int64_t *g_one = calloc(size, sizeof(*g_one));
    int64_t *smooth_sum = malloc(size * sizeof(*smooth_sum));
    uint32_t *small_lo = calloc(size, sizeof(*small_lo));
    uint32_t *small_hi = calloc(size, sizeof(*small_hi));
    uint32_t *simple_cursor = calloc(size, sizeof(*simple_cursor));
    uint32_t *g_cursor = calloc(size, sizeof(*g_cursor));
    if (smallest == NULL || primes == NULL || g_zero == NULL || g_one == NULL ||
        smooth_sum == NULL || small_lo == NULL || small_hi == NULL || simple_cursor == NULL ||
        g_cursor == NULL) {
        free(smallest); free(primes); free(g_zero); free(g_one); free(smooth_sum);
        free(small_lo); free(small_hi); free(simple_cursor); free(g_cursor);
        return -1;
    }

    size_t prime_total = 0;
    for (int64_t value = 2; value <= root; ++value) {
        if (smallest[value] != 0) continue;
        smallest[value] = (uint32_t)value;
        primes[prime_total++] = (int32_t)value;
        if (value <= root / value) {
            for (int64_t multiple = value * value; multiple <= root; multiple += value) {
                if (smallest[multiple] == 0) smallest[multiple] = (uint32_t)value;
            }
        }
    }
    prefix_sum = calloc(prime_total + 1, sizeof(*prefix_sum));
    prefix_g = calloc(prime_total + 1, sizeof(*prefix_g));
    if (prefix_sum == NULL || prefix_g == NULL) {
        free(smallest); free(primes); free(g_zero); free(g_one); free(smooth_sum);
        free(small_lo); free(small_hi); free(simple_cursor); free(g_cursor);
        free(prefix_sum); free(prefix_g);
        return -1;
    }
    for (size_t p_index = 0; p_index < prime_total; ++p_index) {
        const int64_t prime = primes[p_index];
        prefix_sum[p_index + 1] = normalize(prefix_sum[p_index] + prime);
        prefix_g[p_index + 1] = normalize(prefix_g[p_index] + a + b * prime);
    }

    for (size_t index = 1; index < size; ++index) {
        const int64_t value = quotient_at(index, n, root, high_count, size);
        size_t lo = 0, hi = prime_total;
        while (lo < hi) {
            const size_t middle = lo + (hi - lo) / 2;
            if ((int64_t)primes[middle] <= floor_sqrt(value)) lo = middle + 1;
            else hi = middle;
        }
        small_lo[index] = (uint32_t)lo;
        lo = 0; hi = prime_total;
        while (lo < hi) {
            const size_t middle = lo + (hi - lo) / 2;
            if ((int64_t)primes[middle] <= value) lo = middle + 1;
            else hi = middle;
        }
        small_hi[index] = (uint32_t)lo;
        simple_cursor[index] = (uint32_t)hi;
        g_cursor[index] = small_lo[index];

        g_zero[index] = value % MODULUS;
        int64_t left = value, right = value + 1;
        if ((left & 1) == 0) left /= 2; else right /= 2;
        g_one[index] = (left % MODULUS) * (right % MODULUS) % MODULUS;
        smooth_sum[index] = 1;
    }

    /* Full p^2<=y sieve transitions; the p>sqrt(y) tail is prefix-corrected below. */
    for (size_t p_index = 0; p_index < prime_total; ++p_index) {
        const int64_t prime = primes[p_index];
        const int64_t square = prime * prime;
        for (size_t index = 1; index < size; ++index) {
            const int64_t value = quotient_at(index, n, root, high_count, size);
            if (value < square) break;
            const size_t child = value_index(value / prime, n, root, size);
            apply_skipped_power_sums(child, p_index, small_lo, small_hi, g_cursor,
                                     prefix_sum, g_zero, g_one);
            g_zero[index] = normalize(g_zero[index] - g_zero[child]);
            g_one[index] = normalize(g_one[index] - prime * g_one[child]);
        }
    }
    for (size_t index = 1; index < size; ++index) {
        apply_skipped_power_sums(index, prime_total, small_lo, small_hi, g_cursor,
                                 prefix_sum, g_zero, g_one);
    }

    /* Descending-prime smooth-number DP, with skipped single-prime bands lazy. */
    for (size_t position = prime_total; position-- > 0;) {
        const int64_t prime = primes[position];
        const int64_t square = prime * prime;
        for (size_t index = 1; index < size; ++index) {
            const int64_t value = quotient_at(index, n, root, high_count, size);
            if (value < square) break;
            apply_skipped_prime_range(index, position, small_lo, small_hi,
                                      simple_cursor, prefix_g, smooth_sum);
            int64_t power = prime;
            int64_t exponent = 1;
            while (power <= value) {
                const size_t child = value_index(value / power, n, root, size);
                apply_skipped_prime_range(child, position, small_lo, small_hi,
                                          simple_cursor, prefix_g, smooth_sum);
                const int64_t local = (a * exponent + b * prime) % MODULUS;
                smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child]);
                power *= prime;
                ++exponent;
            }
        }
    }

    int64_t answer = smooth_sum[1];
    for (int64_t value = 1; value <= root; ++value) {
        int64_t factor_value = 1;
        int64_t remaining = value;
        while (remaining > 1) {
            const int64_t prime = smallest[remaining];
            int64_t exponent = 0;
            do {
                remaining /= prime;
                ++exponent;
            } while (remaining > 1 && remaining % prime == 0);
            factor_value = factor_value * ((a * exponent + b * prime) % MODULUS) % MODULUS;
        }
        const size_t quotient_index = value_index(n / value, n, root, size);
        const int64_t large_prime_sum = normalize(
            a * normalize(g_zero[quotient_index] - 1) +
            b * normalize(g_one[quotient_index] - 1));
        answer = normalize(answer + factor_value * large_prime_sum);
    }

    free(smallest); free(primes); free(prefix_sum); free(prefix_g);
    free(g_zero); free(g_one); free(smooth_sum); free(small_lo); free(small_hi); free(simple_cursor); free(g_cursor);
    return answer;
}
