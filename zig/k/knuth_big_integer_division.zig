const BASE: i64 = 1_000_000_000;
const MAX_LIMBS: usize = 8;
const Limbs = [MAX_LIMBS]i64;

fn trim(x: *const Limbs, count_input: usize) usize {
    var count = count_input;
    while (count > 0 and x[count - 1] == 0) count -= 1;
    return count;
}

fn parse(text: []const i64, x: *Limbs) usize {
    var count: usize = 0;
    for (text) |byte| {
        var carry = byte - 48;
        for (0..count) |i| {
            carry += x[i] * 10;
            x[i] = @rem(carry, BASE);
            carry = @divTrunc(carry, BASE);
        }
        if (carry != 0) { x[count] = carry; count += 1; }
        if (count == 0) count = 1;
    }
    return trim(x, count);
}

fn compare(a: *const Limbs, na: usize, b: *const Limbs, nb: usize) i32 {
    if (na != nb) return if (na > nb) 1 else -1;
    var i = na;
    while (i > 0) {
        i -= 1;
        if (a[i] != b[i]) return if (a[i] > b[i]) 1 else -1;
    }
    return 0;
}

fn divide(a: *const Limbs, na: usize, b: *const Limbs, nb: usize,
    q: *Limbs, r: *Limbs) struct { quotient_length: usize, remainder_length: usize } {
    if (na == 0) return .{ .quotient_length = 0, .remainder_length = 0 };
    if (compare(a, na, b, nb) < 0) { r.* = a.*; return .{ .quotient_length = 0, .remainder_length = na }; }
    if (nb == 1) {
        var rem: i64 = 0;
        var i = na;
        while (i > 0) { i -= 1; const current = rem * BASE + a[i]; q[i] = @divTrunc(current, b[0]); rem = @rem(current, b[0]); }
        if (rem != 0) { r[0] = rem; return .{ .quotient_length = trim(q, na), .remainder_length = 1 }; }
        return .{ .quotient_length = trim(q, na), .remainder_length = 0 };
    }
    var v: Limbs = @splat(0);
    var u: [MAX_LIMBS + 1]i64 = @splat(0);
    const scale = @divTrunc(BASE, b[nb - 1] + 1);
    var carry: i64 = 0;
    for (0..nb) |i| { const current = b[i] * scale + carry; v[i] = @rem(current, BASE); carry = @divTrunc(current, BASE); }
    carry = 0;
    for (0..na) |i| { const current = a[i] * scale + carry; u[i] = @rem(current, BASE); carry = @divTrunc(current, BASE); }
    u[na] = carry;
    const width = na - nb + 1;
    var step = width;
    while (step > 0) {
        step -= 1;
        const j = step;
        const numerator = u[j + nb] * BASE + u[j + nb - 1];
        var estimate = @divTrunc(numerator, v[nb - 1]);
        var rem_estimate = @rem(numerator, v[nb - 1]);
        if (estimate >= BASE) { estimate = BASE - 1; rem_estimate = numerator - estimate * v[nb - 1]; }
        while (rem_estimate < BASE and estimate * v[nb - 2] > rem_estimate * BASE + u[j + nb - 2]) {
            estimate -= 1; rem_estimate += v[nb - 1];
        }
        var borrow: i64 = 0;
        for (0..nb) |i| {
            const product = estimate * v[i] + borrow;
            const low = @rem(product, BASE);
            borrow = @divTrunc(product, BASE);
            var diff = u[j + i] - low;
            if (diff < 0) { diff += BASE; borrow += 1; }
            u[j + i] = diff;
        }
        const top = u[j + nb] - borrow;
        if (top < 0) {
            estimate -= 1; carry = 0;
            for (0..nb) |i| {
                var sum = u[j + i] + v[i] + carry;
                if (sum >= BASE) { sum -= BASE; carry = 1; } else carry = 0;
                u[j + i] = sum;
            }
            u[j + nb] = top + carry;
        } else u[j + nb] = top;
        q[j] = estimate;
    }
    carry = 0;
    var i = nb;
    while (i > 0) { i -= 1; const current = carry * BASE + u[i]; r[i] = @divTrunc(current, scale); carry = @rem(current, scale); }
    return .{ .quotient_length = trim(q, width), .remainder_length = trim(r, nb) };
}

fn emit(x: *const Limbs, count_input: usize, output: []u8, at_input: usize) usize {
    const count = trim(x, count_input);
    var at = at_input;
    if (count == 0) { output[at] = '0'; return at + 1; }
    var value = x[count - 1];
    var power: i64 = 1;
    while (@divTrunc(value, power) >= 10) power *= 10;
    while (power > 0) { output[at] = @intCast(48 + @rem(@divTrunc(value, power), 10)); at += 1; power = @divTrunc(power, 10); }
    var n = count;
    while (n > 1) {
        n -= 1; value = x[n - 1]; power = @divTrunc(BASE, 10);
        while (power > 0) { output[at] = @intCast(48 + @rem(@divTrunc(value, power), 10)); at += 1; power = @divTrunc(power, 10); }
    }
    return at;
}

export fn knuth_big_integer_division(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 130) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64) return -1;
    const na_text: usize = @intCast(input[0]);
    const nb_text: usize = @intCast(input[1]);
    if (length != 2 + na_text + nb_text) return -1;
    const a_text = input[2 .. 2 + na_text];
    const b_text = input[2 + na_text .. 2 + na_text + nb_text];
    for (a_text) |byte| { if (byte < 48 or byte > 57) return -1; }
    for (b_text) |byte| { if (byte < 48 or byte > 57) return -1; }
    if ((na_text > 1 and a_text[0] == 48) or (nb_text > 1 and b_text[0] == 48) or (nb_text == 1 and b_text[0] == 48)) return -1;
    var a: Limbs = @splat(0); var b: Limbs = @splat(0); var q: Limbs = @splat(0); var r: Limbs = @splat(0);
    const na = parse(a_text, &a); const nb = parse(b_text, &b);
    const counts = divide(&a, na, &b, nb, &q, &r);
    var result: [129]u8 = @splat(0);
    var bytes = emit(&q, counts.quotient_length, result[0..], 0);
    result[bytes] = ':'; bytes += 1;
    bytes = emit(&r, counts.remainder_length, result[0..], bytes);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = result[i];
    return @intCast(bytes);
}
