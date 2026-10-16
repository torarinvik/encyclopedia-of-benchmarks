/* Exact golden-triple fraction enumeration for Project Euler 180. */
#include <stdint.h>
#include <stdlib.h>

#define MAX_ORDER INT64_C(35)
#define HASH_CAPACITY ((size_t)1 << 19)
#define HASH_MASK (HASH_CAPACITY - 1)
#define BIG_BASE INT64_C(10000)
#define BIG_LIMBS 8

static int64_t gcd_i64(int64_t left, int64_t right)
{
    while (right != 0) { int64_t remainder = left % right; left = right; right = remainder; }
    return left;
}

static int64_t integer_sqrt(int64_t value)
{
    if (value <= 0) return 0;
    int64_t root = value;
    int64_t next = (root + value / root) / 2;
    while (next < root) { root = next; next = (root + value / root) / 2; }
    return root;
}

static int insert_fraction(int64_t *numerators, int64_t *denominators,
                           int64_t numerator, int64_t denominator)
{
    size_t index = (size_t)(((numerator % HASH_CAPACITY) * 1009 + denominator % HASH_CAPACITY) & HASH_MASK);
    while (denominators[index] != 0) {
        if (numerators[index] == numerator && denominators[index] == denominator) return 0;
        index = (index + 1) & HASH_MASK;
    }
    numerators[index] = numerator;
    denominators[index] = denominator;
    return 1;
}

static void record_sum(int64_t *numerators, int64_t *denominators,
                       int64_t xn, int64_t xd, int64_t yn, int64_t yd,
                       int64_t zn, int64_t zd, int64_t order)
{
    if (zn <= 0 || zd <= 0) return;
    int64_t divisor = gcd_i64(zn, zd); zn /= divisor; zd /= divisor;
    if (zn >= zd || zd > order) return;
    int64_t numerator = xn * yd * zd + yn * xd * zd + zn * xd * yd;
    int64_t denominator = xd * yd * zd;
    divisor = gcd_i64(numerator, denominator);
    insert_fraction(numerators, denominators, numerator / divisor, denominator / divisor);
}

static void add_big(int64_t limbs[BIG_LIMBS], int64_t value)
{
    size_t index = 0;
    while (value > 0) {
        int64_t total = limbs[index] + value;
        limbs[index] = total % BIG_BASE;
        value = total / BIG_BASE;
        ++index;
    }
}

int64_t problem180(int64_t order)
{
    if (order < 1 || order > MAX_ORDER) return -1;
    int64_t *numerators = (int64_t *)calloc(HASH_CAPACITY, sizeof(int64_t));
    int64_t *denominators = (int64_t *)calloc(HASH_CAPACITY, sizeof(int64_t));
    if (numerators == NULL || denominators == NULL) { free(numerators); free(denominators); return -1; }

    for (int64_t xn = 1; xn <= order; ++xn) for (int64_t xd = xn + 1; xd <= order; ++xd) {
        if (gcd_i64(xn, xd) != 1) continue;
        for (int64_t yn = 1; yn <= order; ++yn) for (int64_t yd = yn + 1; yd <= order; ++yd) {
            if (gcd_i64(yn, yd) != 1 || xn * yd > yn * xd) continue;

            int64_t zn = xn * yd + xd * yn, zd = xd * yd;
            record_sum(numerators, denominators, xn, xd, yn, yd, zn, zd, order);

            int64_t square_num = xn*xn*yd*yd + xd*xd*yn*yn;
            int64_t square_den = xd*xd*yd*yd;
            int64_t root_num = integer_sqrt(square_num), root_den = integer_sqrt(square_den);
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

    int64_t common_denominator = 1;
    for (int64_t factor = 2; factor <= order; ++factor)
        common_denominator = common_denominator / gcd_i64(common_denominator, factor) * factor;
    int64_t total[BIG_LIMBS] = {0};
    for (size_t index = 0; index < HASH_CAPACITY; ++index) if (denominators[index] != 0) {
        if (common_denominator % denominators[index] != 0) { free(numerators); free(denominators); return -1; }
        add_big(total, numerators[index] * (common_denominator / denominators[index]));
    }
    free(numerators); free(denominators);

    int64_t remainder = 0;
    for (int index = BIG_LIMBS - 1; index >= 0; --index)
        remainder = (remainder * BIG_BASE + total[index]) % common_denominator;
    int64_t divisor = gcd_i64(remainder, common_denominator);
    remainder = 0;
    for (int index = BIG_LIMBS - 1; index >= 0; --index) {
        int64_t current = remainder * BIG_BASE + total[index];
        total[index] = current / divisor;
        remainder = current % divisor;
    }
    int64_t numerator = 0;
    for (int index = BIG_LIMBS - 1; index >= 0; --index) {
        if (numerator > (INT64_MAX - total[index]) / BIG_BASE) return -1;
        numerator = numerator * BIG_BASE + total[index];
    }
    int64_t denominator = common_denominator / divisor;
    if (numerator > INT64_MAX - denominator) return -1;
    return numerator + denominator;
}
