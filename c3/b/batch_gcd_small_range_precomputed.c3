module batch_gcd_small_range_precomputed;

const long MAX_VALUE = 64;
const usz MAX_SMALL = 8;
const usz MAX_QUERIES = 64;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_QUERIES;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long batch_gcd_small_range_precomputed(long* input, usz length,
    char* output, usz capacity) @export("batch_gcd_small_range_precomputed") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH + 1) return -1;
    long limit_value = input[0], query_value = input[1];
    if (limit_value < 1 || limit_value > MAX_VALUE || query_value < 0 ||
        query_value > (long)MAX_QUERIES) return -1;
    usz limit = (usz)limit_value, queries = (usz)query_value;
    if (length != 2 + 2 * queries) return -1;
    for (usz query = 0; query < queries; query += 1) {
        long left = input[2 + 2 * query], right = input[3 + 2 * query];
        if (left < 0 || left > limit_value || right < 0 || right > limit_value) return -1;
    }
    usz required = 8 * queries;
    if (output == null || capacity < required) return -2;

    usz[MAX_VALUE + 1] least = zeroed;
    usz[MAX_VALUE + 1] primes = zeroed;
    usz prime_count = 0;
    for (usz value = 2; value <= limit; value += 1) {
        if (least[value] == 0) {
            least[value] = value;
            primes[prime_count] = value;
            prime_count += 1;
        }
        for (usz index = 0; index < prime_count; index += 1) {
            usz prime = primes[index], composite = value * prime;
            if (composite > limit || prime > least[value]) break;
            least[composite] = prime;
        }
    }

    usz[MAX_VALUE + 1][3] factors = zeroed;
    factors[1][0] = 1; factors[1][1] = 1; factors[1][2] = 1;
    for (usz value = 2; value <= limit; value += 1) {
        usz prime = least[value], quotient = value / prime;
        usz a = factors[quotient][0] * prime;
        usz b = factors[quotient][1], c = factors[quotient][2];
        usz temp;
        if (a > b) { temp = a; a = b; b = temp; }
        if (b > c) { temp = b; b = c; c = temp; }
        if (a > b) { temp = a; a = b; b = temp; }
        factors[value][0] = a; factors[value][1] = b; factors[value][2] = c;
    }

    usz small_limit = 1;
    while ((small_limit + 1) * (small_limit + 1) <= limit) small_limit += 1;
    usz[MAX_SMALL + 1][MAX_SMALL + 1] gcd_table = zeroed;
    for (usz left = 1; left <= small_limit; left += 1) {
        gcd_table[left][0] = left;
        for (usz right = 1; right < left; right += 1)
            gcd_table[left][right] = gcd_table[right][left % right];
    }

    for (usz query = 0; query < queries; query += 1) {
        usz left = (usz)input[2 + 2 * query];
        usz remaining = (usz)input[3 + 2 * query];
        usz result = 0;
        if (left == 0) result = remaining;
        else {
            result = 1;
            for (usz part = 0; part < 3; part += 1) {
                usz factor = factors[left][part], common;
                if (factor <= small_limit) common = gcd_table[factor][remaining % factor];
                else if (remaining % factor == 0) common = factor;
                else common = 1;
                remaining /= common;
                result *= common;
            }
        }
        store_i64_le(output, 8 * query, (long)result);
    }
    return (long)required;
}
