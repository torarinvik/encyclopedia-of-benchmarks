#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 16
#define MAX_SUPPORT 17

static int64_t choose_value(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    int64_t result = 1;
    for (int i = 1; i <= k; ++i) result = result * (n - k + i) / i;
    return result;
}
static int64_t gcd_value(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}
static void put_i64(uint8_t *output, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t spatial_motif_same_type_contact_pmf(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    int64_t l0 = input[0], x10 = input[1], x20 = input[2];
    if (l0 < 1 || l0 > MAX_LENGTH || x10 < 0 || x10 > l0 || x20 < 0 || x20 > l0) return -1;
    int l = (int)l0, x1 = (int)x10, x2 = (int)x20;
    int low = x1 + x2 > l ? x1 + x2 - l : 0;
    int high = x1 < x2 ? x1 : x2;
    int64_t denominator = choose_value(l, x2);
    int64_t numerators[MAX_SUPPORT];
    for (int i = low; i <= high; ++i)
        numerators[i - low] = choose_value(x1, i) * choose_value(l - x1, x2 - i);
    int64_t expected_num = (int64_t)x1 * x2, expected_den = l;
    int64_t divisor = gcd_value(expected_num, expected_den);
    expected_num /= divisor; expected_den /= divisor;
    size_t count = (size_t)(high - low + 1), words = 3 + count + 2, bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, low); put_i64(output, 1, high); put_i64(output, 2, denominator);
    for (size_t i = 0; i < count; ++i) put_i64(output, 3 + i, numerators[i]);
    put_i64(output, 3 + count, expected_num); put_i64(output, 4 + count, expected_den);
    return (int64_t)bytes;
}
