module rational_approximation;

struct Bounds { long lower_num; long lower_den; long upper_num; long upper_den; }

fn long gcd_positive(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn Bounds bounded_neighbors(long limit, long x, long y) {
    long divisor = gcd_positive(x, y);
    long reduced_x = x / divisor;
    long reduced_y = y / divisor;
    if (reduced_x <= limit && reduced_y <= limit)
        return Bounds{reduced_x, reduced_y, reduced_x, reduced_y};

    long a = 0, b = 1;
    long c = 1, d = 0;
    while (true) {
        long middle_num = a + c;
        long middle_den = b + d;
        if (middle_num > limit || middle_den > limit) break;
        long target_side = middle_num * y;
        long middle_side = middle_den * x;
        if (target_side == middle_side)
            return Bounds{middle_num, middle_den, middle_num, middle_den};

        if (target_side < middle_side) {
            long lower_gap = b * x - a * y;
            long upper_gap = c * y - d * x;
            long step = lower_gap / upper_gap;
            long numerator_cap = (limit - a) / c;
            if (step > numerator_cap) step = numerator_cap;
            if (d > 0) {
                long denominator_cap = (limit - b) / d;
                if (step > denominator_cap) step = denominator_cap;
            }
            a += step * c;
            b += step * d;
        } else {
            long upper_gap = c * y - d * x;
            long lower_gap = b * x - a * y;
            long step = upper_gap / lower_gap;
            if (a > 0) {
                long numerator_cap = (limit - c) / a;
                if (step > numerator_cap) step = numerator_cap;
            }
            long denominator_cap = (limit - d) / b;
            if (step > denominator_cap) step = denominator_cap;
            c += step * a;
            d += step * b;
        }
    }
    return Bounds{a, b, c, d};
}

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long rational_approximation(long* values, usz length, char* output,
                               usz output_capacity) @export("rational_approximation") {
    if (values == null || length != 3) return -1;
    long limit = values[0], x = values[1], y = values[2];
    if (limit < 1 || limit > 1000000000 || x < 1 || x > 1000000000 ||
        y < 1 || y > 1000000000) return -1;
    if (output == null || output_capacity < 32) return -2;

    Bounds bounds = bounded_neighbors(limit, x, y);
    store_i64_le(output, 0, bounds.lower_num);
    store_i64_le(output, 8, bounds.lower_den);
    store_i64_le(output, 16, bounds.upper_num);
    store_i64_le(output, 24, bounds.upper_den);
    return 32;
}
