module problem57;

const usz MAX_ITERATIONS = 10000;
const usz MAX_LIMBS = 512;
const ulong LIMB_BASE = 1000000000ul;

fn usz decimal_digits(ulong value) {
    usz digits = 1;
    while (value >= 10) { value /= 10; digits++; }
    return digits;
}

fn long problem57(long iterations) @export("problem57") {
    if (iterations <= 0) return 0;
    if (iterations > (long)MAX_ITERATIONS) return -1;
    ulong[MAX_LIMBS] numerator = {1};
    ulong[MAX_LIMBS] denominator = {1};
    ulong[MAX_LIMBS] next_numerator = {0};
    ulong[MAX_LIMBS] next_denominator = {0};
    usz numerator_length = 1, denominator_length = 1;
    long result = 0;
    for (long iteration = 0; iteration < iterations; iteration++) {
        usz shared_length = numerator_length > denominator_length ? numerator_length : denominator_length;
        ulong numerator_carry = 0, denominator_carry = 0;
        for (usz index = 0; index < shared_length; index++) {
            ulong n_digit = index < numerator_length ? numerator[index] : 0;
            ulong d_digit = index < denominator_length ? denominator[index] : 0;
            ulong n_sum = n_digit + 2 * d_digit + numerator_carry;
            ulong d_sum = n_digit + d_digit + denominator_carry;
            next_numerator[index] = n_sum % LIMB_BASE;
            next_denominator[index] = d_sum % LIMB_BASE;
            numerator_carry = n_sum / LIMB_BASE;
            denominator_carry = d_sum / LIMB_BASE;
        }
        usz next_numerator_length = shared_length, next_denominator_length = shared_length;
        while (numerator_carry > 0) {
            if (next_numerator_length >= MAX_LIMBS) return -1;
            next_numerator[next_numerator_length] = numerator_carry % LIMB_BASE;
            next_numerator_length++;
            numerator_carry /= LIMB_BASE;
        }
        while (denominator_carry > 0) {
            if (next_denominator_length >= MAX_LIMBS) return -1;
            next_denominator[next_denominator_length] = denominator_carry % LIMB_BASE;
            next_denominator_length++;
            denominator_carry /= LIMB_BASE;
        }
        usz numerator_digits = (next_numerator_length - 1) * 9 + decimal_digits(next_numerator[next_numerator_length - 1]);
        usz denominator_digits = (next_denominator_length - 1) * 9 + decimal_digits(next_denominator[next_denominator_length - 1]);
        if (numerator_digits > denominator_digits) result++;
        for (usz index = 0; index < next_numerator_length; index++) numerator[index] = next_numerator[index];
        for (usz index = 0; index < next_denominator_length; index++) denominator[index] = next_denominator[index];
        numerator_length = next_numerator_length;
        denominator_length = next_denominator_length;
    }
    return result;
}
