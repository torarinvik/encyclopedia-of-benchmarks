const LIMBS: usize = 4;

fn divideWords(comptime limbs: usize, dividend: []const u32, divisor: []const u32,
    quotient: []u32, remainder: []u32) void {
    @memset(quotient, 0);
    var rem = [_]u32{0} ** (limbs + 1);
    for (0..limbs * 32) |offset| {
        const bit = limbs * 32 - 1 - offset;
        var carry: u32 = (dividend[bit / 32] >> @as(u5, @intCast(bit % 32))) & 1;
        for (0..limbs) |i| {
            const next = rem[i] >> 31;
            rem[i] = (rem[i] << 1) | carry;
            carry = next;
        }
        rem[limbs] = carry;
        var comparison: i8 = if (rem[limbs] == 0) 0 else 1;
        if (comparison == 0) {
            var i = limbs;
            while (i > 0) {
                i -= 1;
                if (rem[i] > divisor[i]) { comparison = 1; break; }
                if (rem[i] < divisor[i]) { comparison = -1; break; }
            }
        }
        if (comparison >= 0) {
            var borrow: u64 = 0;
            for (0..limbs) |i| {
                const sub: u64 = @as(u64, divisor[i]) + borrow;
                const old: u64 = @as(u64, rem[i]);
                if (old >= sub) { rem[i] = @intCast(old - sub); borrow = 0; }
                else { rem[i] = @intCast(old + 0x1_0000_0000 - sub); borrow = 1; }
            }
            rem[limbs] = @intCast(@as(u64, rem[limbs]) - borrow);
            quotient[bit / 32] |= @as(u32, 1) << @as(u5, @intCast(bit % 32));
        }
    }
    for (0..limbs) |i| remainder[i] = rem[i];
}

export fn uint128_t(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 10 or length != 1 + 2 * LIMBS) return -1;
    const values = input.?[0..length];
    if (values[0] != 0 and values[0] != 1) return -1;
    var dividend = [_]u32{0} ** LIMBS;
    var divisor = [_]u32{0} ** LIMBS;
    var divisor_nonzero = false;
    for (0..LIMBS) |i| {
        const a = values[1 + i]; const b = values[1 + LIMBS + i];
        if (a < 0 or a > 4_294_967_295 or b < 0 or b > 4_294_967_295) return -1;
        dividend[i] = @intCast(a); divisor[i] = @intCast(b); divisor_nonzero = divisor_nonzero or divisor[i] != 0;
    }
    if (!divisor_nonzero) return -1;
    if (output == null or capacity < 16) return -2;
    var quotient = [_]u32{0} ** LIMBS; var remainder = [_]u32{0} ** LIMBS;
    divideWords(LIMBS, dividend[0..], divisor[0..], quotient[0..], remainder[0..]);
    const answer = if (values[0] == 0) quotient else remainder;
    for (0..LIMBS) |i| {
        for (0..4) |byte| {
            output.?[i * 4 + byte] = @truncate(answer[i] >> @as(u5, @intCast(byte * 8)));
        }
    }
    return 16;
}
