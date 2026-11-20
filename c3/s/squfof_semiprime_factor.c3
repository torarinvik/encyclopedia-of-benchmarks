module squfof_semiprime_factor;

const long MAX_NUMBER = 1000000000000;
const long MAX_STEPS = 256;

fn long sq_isqrt(long value, long upper) {
    long low = 0, high = upper + 1;
    while (low + 1 < high) {
        long middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn long sq_gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long sq_reverse(long number, long discriminant, long a, long p, long q, long cap) {
    long root = sq_isqrt(q, 1414214);
    if (root * root != q) return 0;
    long quotient = (a - p) / root;
    long r = quotient * root + p;
    long previous_s = root;
    long s = (discriminant - r * r) / root;
    for (long step = 0; step < cap; step++) {
        long next_quotient = (a + r) / s;
        long next_r = next_quotient * s - r;
        if (next_r == r) {
            long factor = sq_gcd(number, r);
            if (factor > 1 && factor < number) {
                long other = number / factor;
                return factor < other ? factor : other;
            }
            return 0;
        }
        long next_s = previous_s + next_quotient * (r - next_r);
        previous_s = s;
        s = next_s;
        r = next_r;
    }
    return 0;
}

fn long squfof_semiprime_factor(long* input, usz length) @export("squfof_semiprime_factor") {
    if (input == null || length != 3) return -1;
    long number = input[0], forward_cap = input[1], reverse_cap = input[2];
    if (number < 3 || number > MAX_NUMBER || number % 2 == 0
        || forward_cap < 0 || forward_cap > MAX_STEPS
        || reverse_cap < 0 || reverse_cap > MAX_STEPS) return -1;
    long exact_root = sq_isqrt(number, 1000000);
    if (exact_root * exact_root == number) return exact_root;
    long discriminant = number % 4 == 1 ? 2 * number : number;
    long a = sq_isqrt(discriminant, 1414214);
    long previous_q = 1, q = discriminant - a * a, p = a, index = 1;
    for (long step = 0; step < forward_cap; step++) {
        long quotient = (a + p) / q;
        long next_p = quotient * q - p;
        long next_q = previous_q + quotient * (p - next_p);
        previous_q = q;
        q = next_q;
        p = next_p;
        index++;
        if (index % 2 == 0) {
            long factor = sq_reverse(number, discriminant, a, p, q, reverse_cap);
            if (factor != 0) return factor;
        }
    }
    return 0;
}
