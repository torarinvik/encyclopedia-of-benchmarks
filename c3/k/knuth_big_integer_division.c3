module knuth_big_integer_division;

const long BASE = 1000000000;
const usz MAX_LIMBS = 8;
const usz MAX_INPUT = 130;
const usz MAX_OUTPUT = 129;

fn usz trim(long* values, usz count) {
    while (count > 0 && values[count - 1] == 0) count -= 1;
    return count;
}

fn usz parse_limbs(long* text, usz length, long* limbs) {
    usz count = 0;
    for (usz at = 0; at < length; at++) {
        long carry = text[at] - 48;
        for (usz i = 0; i < count; i++) {
            long value = limbs[i] * 10 + carry;
            limbs[i] = value % BASE;
            carry = value / BASE;
        }
        if (carry != 0) limbs[count++] = carry;
        if (count == 0) count = 1;
    }
    return trim(limbs, count);
}

fn int compare(long* a, usz na, long* b, usz nb) {
    if (na != nb) return na > nb ? 1 : -1;
    while (na > 0) {
        na -= 1;
        if (a[na] != b[na]) return a[na] > b[na] ? 1 : -1;
    }
    return 0;
}

fn void divide_limbs(long* a, usz na, long* b, usz nb, long* q, usz* nq, long* r, usz* nr) {
    *nq = 0; *nr = 0;
    if (na == 0) return;
    if (compare(a, na, b, nb) < 0) {
        for (usz i = 0; i < na; i++) r[i] = a[i];
        *nr = na; return;
    }
    if (nb == 1) {
        long rem = 0;
        for (usz i = na; i > 0; i--) { long current = rem * BASE + a[i - 1]; q[i - 1] = current / b[0]; rem = current % b[0]; }
        *nq = trim(q, na);
        if (rem != 0) { r[0] = rem; *nr = 1; }
        return;
    }
    long v[MAX_LIMBS] = {0}; long u[MAX_LIMBS + 1] = {0};
    usz n = nb;
    long scale = BASE / (b[n - 1] + 1);
    long carry = 0;
    for (usz i = 0; i < n; i++) { long current = b[i] * scale + carry; v[i] = current % BASE; carry = current / BASE; }
    carry = 0;
    for (usz i = 0; i < na; i++) { long current = a[i] * scale + carry; u[i] = current % BASE; carry = current / BASE; }
    u[na] = carry;
    usz width = na - n + 1;
    for (usz step = width; step > 0; step--) {
        usz j = step - 1;
        long numerator = u[j + n] * BASE + u[j + n - 1];
        long estimate = numerator / v[n - 1];
        long estimate_rem = numerator % v[n - 1];
        if (estimate >= BASE) { estimate = BASE - 1; estimate_rem = numerator - estimate * v[n - 1]; }
        while (estimate_rem < BASE && estimate * v[n - 2] > estimate_rem * BASE + u[j + n - 2]) {
            estimate -= 1; estimate_rem += v[n - 1];
        }
        long borrow = 0;
        for (usz i = 0; i < n; i++) {
            long product = estimate * v[i] + borrow;
            long low = product % BASE; borrow = product / BASE;
            long difference = u[j + i] - low;
            if (difference < 0) { difference += BASE; borrow += 1; }
            u[j + i] = difference;
        }
        long top = u[j + n] - borrow;
        if (top < 0) {
            estimate -= 1; carry = 0;
            for (usz i = 0; i < n; i++) {
                long sum = u[j + i] + v[i] + carry;
                if (sum >= BASE) { sum -= BASE; carry = 1; } else carry = 0;
                u[j + i] = sum;
            }
            u[j + n] = top + carry;
        } else u[j + n] = top;
        q[j] = estimate;
    }
    *nq = trim(q, width); carry = 0;
    for (usz i = n; i > 0; i--) { long current = carry * BASE + u[i - 1]; r[i - 1] = current / scale; carry = current % scale; }
    *nr = trim(r, n);
}

fn usz emit_decimal(long* limbs, usz count, uint8* output, usz at) {
    count = trim(limbs, count);
    if (count == 0) { output[at] = 48; return at + 1; }
    long value = limbs[count - 1]; long power = 1;
    while (value / power >= 10) power *= 10;
    while (power > 0) { output[at++] = (uint8)(48 + value / power % 10); power /= 10; }
    while (count > 1) {
        count -= 1; value = limbs[count - 1]; power = BASE / 10;
        while (power > 0) { output[at++] = (uint8)(48 + value / power % 10); power /= 10; }
    }
    return at;
}

fn long knuth_big_integer_division(long* input, usz length, uint8* output, usz capacity)
    @export("knuth_big_integer_division") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return -1;
    usz na_text = (usz)input[0]; usz nb_text = (usz)input[1];
    if (length != 2 + na_text + nb_text) return -1;
    long* a_text = input + 2; long* b_text = input + 2 + na_text;
    for (usz i = 0; i < na_text; i++) if (a_text[i] < 48 || a_text[i] > 57) return -1;
    for (usz i = 0; i < nb_text; i++) if (b_text[i] < 48 || b_text[i] > 57) return -1;
    if ((na_text > 1 && a_text[0] == 48) || (nb_text > 1 && b_text[0] == 48) || (nb_text == 1 && b_text[0] == 48)) return -1;
    long a[MAX_LIMBS] = {0}; long b[MAX_LIMBS] = {0}; long q[MAX_LIMBS] = {0}; long r[MAX_LIMBS] = {0};
    usz na = parse_limbs(a_text, na_text, &a[0]); usz nb = parse_limbs(b_text, nb_text, &b[0]);
    usz nq = 0; usz nr = 0;
    divide_limbs(&a[0], na, &b[0], nb, &q[0], &nq, &r[0], &nr);
    uint8 result[MAX_OUTPUT] = {0};
    usz bytes = emit_decimal(&q[0], nq, &result[0], 0);
    result[bytes++] = 58;
    bytes = emit_decimal(&r[0], nr, &result[0], bytes);
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < bytes; i++) output[i] = result[i];
    return (long)bytes;
}
