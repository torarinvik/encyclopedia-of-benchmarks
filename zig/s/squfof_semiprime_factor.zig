const max_number: i64 = 1_000_000_000_000;
const max_steps: i64 = 256;

fn sqIsqrt(value: i64, upper: i64) i64 {
    var low: i64 = 0;
    var high = upper + 1;
    while (low + 1 < high) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle * middle <= value) low = middle else high = middle;
    }
    return low;
}

fn sqGcd(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @mod(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn sqReverse(number: i64, discriminant: i64, a: i64, p: i64, q: i64, cap: i64) i64 {
    const root = sqIsqrt(q, 1_414_214);
    if (root * root != q) return 0;
    const quotient = @divTrunc(a - p, root);
    var r = quotient * root + p;
    var previous_s = root;
    var s = @divTrunc(discriminant - r * r, root);
    var step: i64 = 0;
    while (step < cap) : (step += 1) {
        const next_quotient = @divTrunc(a + r, s);
        const next_r = next_quotient * s - r;
        if (next_r == r) {
            const factor = sqGcd(number, r);
            if (factor > 1 and factor < number) {
                const other = @divTrunc(number, factor);
                return @min(factor, other);
            }
            return 0;
        }
        const next_s = previous_s + next_quotient * (r - next_r);
        previous_s = s;
        s = next_s;
        r = next_r;
    }
    return 0;
}

export fn squfof_semiprime_factor(input: ?[*]const i64, length: usize) i64 {
    const values_ptr = input orelse return -1;
    if (length != 3) return -1;
    const values = values_ptr[0..length];
    const number = values[0];
    const forward_cap = values[1];
    const reverse_cap = values[2];
    if (number < 3 or number > max_number or @mod(number, 2) == 0
        or forward_cap < 0 or forward_cap > max_steps
        or reverse_cap < 0 or reverse_cap > max_steps) return -1;
    const exact_root = sqIsqrt(number, 1_000_000);
    if (exact_root * exact_root == number) return exact_root;
    const discriminant = if (@mod(number, 4) == 1) 2 * number else number;
    const a = sqIsqrt(discriminant, 1_414_214);
    var previous_q: i64 = 1;
    var q = discriminant - a * a;
    var p = a;
    var index: i64 = 1;
    var step: i64 = 0;
    while (step < forward_cap) : (step += 1) {
        const quotient = @divTrunc(a + p, q);
        const next_p = quotient * q - p;
        const next_q = previous_q + quotient * (p - next_p);
        previous_q = q;
        q = next_q;
        p = next_p;
        index += 1;
        if (@mod(index, 2) == 0) {
            const factor = sqReverse(number, discriminant, a, p, q, reverse_cap);
            if (factor != 0) return factor;
        }
    }
    return 0;
}
