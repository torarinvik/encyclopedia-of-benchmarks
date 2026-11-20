#include <stddef.h>
#include <stdint.h>

enum { MAX_DIGITS = 64, MAX_LIMBS = 8, MAX_INPUT = 130, MAX_OUTPUT = 129 };
static const int64_t BASE = INT64_C(1000000000);

static size_t parse_limbs(const int64_t *text, size_t length, int64_t *limbs) {
    size_t count = 0;
    for (size_t at = 0; at < length; ++at) {
        int64_t carry = text[at] - 48;
        for (size_t i = 0; i < count; ++i) {
            const int64_t value = limbs[i] * 10 + carry;
            limbs[i] = value % BASE;
            carry = value / BASE;
        }
        if (carry != 0) limbs[count++] = carry;
        if (count == 0) count = 1;
    }
    while (count > 0 && limbs[count - 1] == 0) --count;
    return count;
}

static int compare(const int64_t *a, size_t na, const int64_t *b, size_t nb) {
    if (na != nb) return na > nb ? 1 : -1;
    while (na > 0) {
        --na;
        if (a[na] != b[na]) return a[na] > b[na] ? 1 : -1;
    }
    return 0;
}

static size_t trim(const int64_t *a, size_t n) {
    while (n > 0 && a[n - 1] == 0) --n;
    return n;
}

static size_t emit_decimal(const int64_t *limbs, size_t count, uint8_t *out, size_t at) {
    count = trim(limbs, count);
    if (count == 0) { out[at++] = 48; return at; }
    int64_t value = limbs[count - 1];
    int64_t power = 1;
    while (value / power >= 10) power *= 10;
    while (power > 0) { out[at++] = (uint8_t)(48 + value / power % 10); power /= 10; }
    while (--count > 0) {
        value = limbs[count - 1];
        power = BASE / 10;
        while (power > 0) { out[at++] = (uint8_t)(48 + value / power % 10); power /= 10; }
    }
    return at;
}

static void divide_limbs(const int64_t *a, size_t na, const int64_t *b, size_t nb,
                         int64_t *q, size_t *nq, int64_t *r, size_t *nr) {
    *nq = 0; *nr = 0;
    if (na == 0) return;
    if (compare(a, na, b, nb) < 0) {
        for (size_t i = 0; i < na; ++i) r[i] = a[i];
        *nr = na;
        return;
    }
    if (nb == 1) {
        int64_t rem = 0;
        for (size_t i = na; i > 0; --i) {
            const int64_t current = rem * BASE + a[i - 1];
            q[i - 1] = current / b[0]; rem = current % b[0];
        }
        *nq = trim(q, na);
        if (rem != 0) { r[0] = rem; *nr = 1; }
        return;
    }

    int64_t v[MAX_LIMBS] = {0}, u[MAX_LIMBS + 1] = {0};
    const size_t n = nb;
    const int64_t scale = BASE / (b[n - 1] + 1);
    int64_t carry = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t current = b[i] * scale + carry;
        v[i] = current % BASE; carry = current / BASE;
    }
    carry = 0;
    for (size_t i = 0; i < na; ++i) {
        const int64_t current = a[i] * scale + carry;
        u[i] = current % BASE; carry = current / BASE;
    }
    u[na] = carry;

    const size_t width = na - n + 1;
    for (size_t step = width; step > 0; --step) {
        const size_t j = step - 1;
        const int64_t numerator = u[j + n] * BASE + u[j + n - 1];
        int64_t estimate = numerator / v[n - 1];
        int64_t estimate_rem = numerator % v[n - 1];
        if (estimate >= BASE) { estimate = BASE - 1; estimate_rem = numerator - estimate * v[n - 1]; }
        while (estimate_rem < BASE && estimate * v[n - 2] > estimate_rem * BASE + u[j + n - 2]) {
            --estimate; estimate_rem += v[n - 1];
        }
        int64_t borrow = 0;
        for (size_t i = 0; i < n; ++i) {
            const int64_t product = estimate * v[i] + borrow;
            const int64_t low = product % BASE;
            borrow = product / BASE;
            int64_t difference = u[j + i] - low;
            if (difference < 0) { difference += BASE; ++borrow; }
            u[j + i] = difference;
        }
        const int64_t top = u[j + n] - borrow;
        if (top < 0) {
            --estimate; carry = 0;
            for (size_t i = 0; i < n; ++i) {
                int64_t sum = u[j + i] + v[i] + carry;
                if (sum >= BASE) { sum -= BASE; carry = 1; } else carry = 0;
                u[j + i] = sum;
            }
            u[j + n] = top + carry;
        } else u[j + n] = top;
        q[j] = estimate;
    }
    *nq = trim(q, width);
    carry = 0;
    for (size_t i = n; i > 0; --i) {
        const int64_t current = carry * BASE + u[i - 1];
        r[i - 1] = current / scale; carry = current % scale;
    }
    *nr = trim(r, n);
}

int64_t knuth_big_integer_division(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_DIGITS || input[1] < 1 || input[1] > MAX_DIGITS) return -1;
    const size_t na_text = (size_t)input[0], nb_text = (size_t)input[1];
    if (length != 2 + na_text + nb_text) return -1;
    const int64_t *a_text = input + 2, *b_text = input + 2 + na_text;
    for (size_t i = 0; i < na_text; ++i) if (a_text[i] < 48 || a_text[i] > 57) return -1;
    for (size_t i = 0; i < nb_text; ++i) if (b_text[i] < 48 || b_text[i] > 57) return -1;
    if ((na_text > 1 && a_text[0] == 48) || (nb_text > 1 && b_text[0] == 48) ||
        (nb_text == 1 && b_text[0] == 48)) return -1;

    int64_t a[MAX_LIMBS] = {0}, b[MAX_LIMBS] = {0}, q[MAX_LIMBS] = {0}, r[MAX_LIMBS] = {0};
    const size_t na = parse_limbs(a_text, na_text, a), nb = parse_limbs(b_text, nb_text, b);
    size_t nq = 0, nr = 0;
    divide_limbs(a, na, b, nb, q, &nq, r, &nr);
    uint8_t result[MAX_OUTPUT];
    size_t bytes = emit_decimal(q, nq, result, 0);
    result[bytes++] = 58;
    bytes = emit_decimal(r, nr, result, bytes);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = result[i];
    return (int64_t)bytes;
}
