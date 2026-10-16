const std = @import("std");
const MAX_ORDER: i64 = 35;
const HASH_CAPACITY: usize = 1 << 19;
const BIG_BASE: i64 = 10_000;
const BIG_LIMBS: usize = 8;

fn gcdI64(left_input: i64, right_input: i64) i64 {
    var left = left_input;
    var right = right_input;
    while (right != 0) { const remainder = @rem(left, right); left = right; right = remainder; }
    return left;
}
fn integerSqrt(value: i64) i64 {
    if (value <= 0) return 0;
    var root = value;
    var next = @divTrunc(root + @divTrunc(value, root), 2);
    while (next < root) { root = next; next = @divTrunc(root + @divTrunc(value, root), 2); }
    return root;
}
fn insertFraction(nums: []i64, dens: []i64, numerator: i64, denominator: i64) bool {
    var index: usize = @intCast(@mod(@mod(numerator, @as(i64, @intCast(HASH_CAPACITY))) * 1009 + @mod(denominator, @as(i64, @intCast(HASH_CAPACITY))), @as(i64, @intCast(HASH_CAPACITY))));
    while (dens[index] != 0) {
        if (nums[index] == numerator and dens[index] == denominator) return false;
        index = (index + 1) % HASH_CAPACITY;
    }
    nums[index] = numerator;
    dens[index] = denominator;
    return true;
}
fn recordSum(nums: []i64, dens: []i64, xn: i64, xd: i64, yn: i64, yd: i64,
             zn_input: i64, zd_input: i64, order: i64) void {
    if (zn_input <= 0 or zd_input <= 0) return;
    var zn = zn_input;
    var zd = zd_input;
    var divisor = gcdI64(zn, zd);
    zn = @divTrunc(zn, divisor); zd = @divTrunc(zd, divisor);
    if (zn >= zd or zd > order) return;
    const sum_num = xn * yd * zd + yn * xd * zd + zn * xd * yd;
    const sum_den = xd * yd * zd;
    divisor = gcdI64(sum_num, sum_den);
    _ = insertFraction(nums, dens, @divTrunc(sum_num, divisor), @divTrunc(sum_den, divisor));
}

export fn problem180(order: i64) i64 {
    if (order < 1 or order > MAX_ORDER) return -1;
    const allocator = std.heap.page_allocator;
    const nums = allocator.alloc(i64, HASH_CAPACITY) catch return -1;
    defer allocator.free(nums);
    const dens = allocator.alloc(i64, HASH_CAPACITY) catch return -1;
    defer allocator.free(dens);
    @memset(nums, 0); @memset(dens, 0);

    var xn: i64 = 1;
    while (xn <= order) : (xn += 1) {
        var xd = xn + 1;
        while (xd <= order) : (xd += 1) {
            if (gcdI64(xn, xd) != 1) continue;
            var yn: i64 = 1;
            while (yn <= order) : (yn += 1) {
                var yd = yn + 1;
                while (yd <= order) : (yd += 1) {
                    if (gcdI64(yn, yd) != 1 or xn * yd > yn * xd) continue;
                    var zn = xn * yd + xd * yn;
                    var zd = xd * yd;
                    recordSum(nums, dens, xn, xd, yn, yd, zn, zd, order);
                    var square_num = xn*xn*yd*yd + xd*xd*yn*yn;
                    var square_den = xd*xd*yd*yd;
                    var root_num = integerSqrt(square_num);
                    var root_den = integerSqrt(square_den);
                    if (root_num*root_num == square_num and root_den*root_den == square_den)
                        recordSum(nums, dens, xn, xd, yn, yd, root_num, root_den, order);
                    zn = xn * yn; zd = xd * yn + xn * yd;
                    recordSum(nums, dens, xn, xd, yn, yd, zn, zd, order);
                    square_num = xn*xn*yn*yn;
                    square_den = xd*xd*yn*yn + xn*xn*yd*yd;
                    root_num = integerSqrt(square_num); root_den = integerSqrt(square_den);
                    if (root_num*root_num == square_num and root_den*root_den == square_den)
                        recordSum(nums, dens, xn, xd, yn, yd, root_num, root_den, order);
                }
            }
        }
    }
    var common: i64 = 1;
    var factor: i64 = 2;
    while (factor <= order) : (factor += 1) common = @divTrunc(common, gcdI64(common, factor)) * factor;
    var total: [BIG_LIMBS]i64 = @splat(0);
    for (dens, 0..) |den, i| {
        if (den == 0) continue;
        if (@rem(common, den) != 0) return -1;
        var carry = nums[i] * @divTrunc(common, den);
        var limb: usize = 0;
        while (carry > 0) : (limb += 1) {
            const current = total[limb] + carry;
            total[limb] = @rem(current, BIG_BASE);
            carry = @divTrunc(current, BIG_BASE);
        }
    }
    var remainder: i64 = 0;
    var i: usize = BIG_LIMBS;
    while (i > 0) { i -= 1; remainder = @rem(remainder * BIG_BASE + total[i], common); }
    const divisor = gcdI64(remainder, common);
    remainder = 0; i = BIG_LIMBS;
    while (i > 0) {
        i -= 1;
        const current = remainder * BIG_BASE + total[i];
        total[i] = @divTrunc(current, divisor);
        remainder = @rem(current, divisor);
    }
    var numerator: i64 = 0;
    i = BIG_LIMBS;
    while (i > 0) {
        i -= 1;
        const limb = total[i];
        if (numerator > @divTrunc(9223372036854775807 - limb, BIG_BASE)) return -1;
        numerator = numerator * BIG_BASE + limb;
    }
    const denominator = @divTrunc(common, divisor);
    if (numerator > 9223372036854775807 - denominator) return -1;
    return numerator + denominator;
}
