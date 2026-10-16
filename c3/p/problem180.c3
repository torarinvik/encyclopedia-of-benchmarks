module problem180;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_ORDER = 35;
const usz HASH_CAPACITY = 524288;
const usz HASH_MASK = HASH_CAPACITY - 1;
const long BIG_BASE = 10000;

fn long gcd_i64(long left, long right) {
    while (right != 0) { long remainder = left % right; left = right; right = remainder; }
    return left;
}
fn long integer_sqrt(long value) {
    if (value <= 0) return 0;
    long root = value, next = (root + value / root) / 2;
    while (next < root) { root = next; next = (root + value / root) / 2; }
    return root;
}
fn bool insert_fraction(long* numerators, long* denominators, long numerator, long denominator) {
    usz index = (usz)(((numerator % (long)HASH_CAPACITY) * 1009 + denominator % (long)HASH_CAPACITY) % (long)HASH_CAPACITY);
    while (denominators[index] != 0) {
        if (numerators[index] == numerator && denominators[index] == denominator) return false;
        index = (index + 1) & HASH_MASK;
    }
    numerators[index] = numerator; denominators[index] = denominator;
    return true;
}
fn void record_sum(long* numerators, long* denominators, long xn, long xd, long yn, long yd,
                   long zn, long zd, long order) {
    if (zn <= 0 || zd <= 0) return;
    long divisor = gcd_i64(zn, zd); zn /= divisor; zd /= divisor;
    if (zn >= zd || zd > order) return;
    long numerator = xn * yd * zd + yn * xd * zd + zn * xd * yd;
    long denominator = xd * yd * zd;
    divisor = gcd_i64(numerator, denominator);
    insert_fraction(numerators, denominators, numerator / divisor, denominator / divisor);
}

fn long problem180(long order) @export("problem180") {
    if (order < 1 || order > MAX_ORDER) return -1;
    long* numerators = (long*)calloc(HASH_CAPACITY, sizeof(long));
    long* denominators = (long*)calloc(HASH_CAPACITY, sizeof(long));
    if (numerators == null || denominators == null) { free(numerators); free(denominators); return -1; }
    defer free(numerators); defer free(denominators);

    for (long xn = 1; xn <= order; xn++) for (long xd = xn + 1; xd <= order; xd++) {
        if (gcd_i64(xn, xd) != 1) continue;
        for (long yn = 1; yn <= order; yn++) for (long yd = yn + 1; yd <= order; yd++) {
            if (gcd_i64(yn, yd) != 1 || xn * yd > yn * xd) continue;
            long zn = xn * yd + xd * yn, zd = xd * yd;
            record_sum(numerators, denominators, xn, xd, yn, yd, zn, zd, order);
            long square_num = xn*xn*yd*yd + xd*xd*yn*yn;
            long square_den = xd*xd*yd*yd;
            long root_num = integer_sqrt(square_num), root_den = integer_sqrt(square_den);
            if (root_num*root_num == square_num && root_den*root_den == square_den)
                record_sum(numerators, denominators, xn, xd, yn, yd, root_num, root_den, order);
            zn = xn * yn; zd = xd * yn + xn * yd;
            record_sum(numerators, denominators, xn, xd, yn, yd, zn, zd, order);
            square_num = xn*xn*yn*yn;
            square_den = xd*xd*yn*yn + xn*xn*yd*yd;
            root_num = integer_sqrt(square_num); root_den = integer_sqrt(square_den);
            if (root_num*root_num == square_num && root_den*root_den == square_den)
                record_sum(numerators, denominators, xn, xd, yn, yd, root_num, root_den, order);
        }
    }

    long common = 1;
    for (long factor = 2; factor <= order; factor++) common = common / gcd_i64(common, factor) * factor;
    long[8] total = {0};
    for (usz i = 0; i < HASH_CAPACITY; i++) if (denominators[i] != 0) {
        if (common % denominators[i] != 0) return -1;
        long value = numerators[i] * (common / denominators[i]);
        usz limb = 0;
        while (value > 0) { long current = total[limb] + value; total[limb] = current % BIG_BASE; value = current / BIG_BASE; limb++; }
    }
    long remainder = 0;
    for (isz i = 7; i >= 0; i--) remainder = (remainder * BIG_BASE + total[(usz)i]) % common;
    long divisor = gcd_i64(remainder, common); remainder = 0;
    for (isz i = 7; i >= 0; i--) { long current = remainder * BIG_BASE + total[(usz)i]; total[(usz)i] = current / divisor; remainder = current % divisor; }
    long numerator = 0;
    for (isz i = 7; i >= 0; i--) {
        long limb = total[(usz)i];
        if (numerator > (9223372036854775807 - limb) / BIG_BASE) return -1;
        numerator = numerator * BIG_BASE + limb;
    }
    long denominator = common / divisor;
    if (numerator > 9223372036854775807 - denominator) return -1;
    return numerator + denominator;
}
