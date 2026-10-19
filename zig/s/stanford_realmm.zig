/// Source-ordered double-precision matrix multiplication from Stanford RealMM.
const ROWSIZE: usize = 40;
const CELL_COUNT: usize = ROWSIZE * ROWSIZE;
const MAX_PASSES: i64 = 10;
const MAX_OUTPUT_BYTES: usize = 140;

fn roundedMicroUnits(bits: u64) u64 {
    const exponent: i32 = @intCast((bits >> 52) & 0x7ff);
    if (exponent == 0) return 0;
    const significand = (bits & 0x000f_ffff_ffff_ffff) | (@as(u64, 1) << 52);
    const shift = 1075 - exponent;
    if (shift >= 74) return 0;
    const low_product = (significand & 0xffff_ffff) * 1_000_000;
    const high_product = (significand >> 32) * 1_000_000;
    const middle = (low_product >> 32) + (high_product & 0xffff_ffff);
    const limb0 = low_product & 0xffff_ffff;
    const limb1 = middle & 0xffff_ffff;
    const limb2 = (high_product >> 32) + (middle >> 32);
    var quotient: u64 = undefined;
    var half_bit: u64 = undefined;
    var lower_nonzero: bool = undefined;
    if (shift < 64) {
        const part = shift - 32;
        quotient = (limb1 >> @intCast(part)) | (limb2 << @intCast(32 - part));
        half_bit = (limb1 >> @intCast(part - 1)) & 1;
        lower_nonzero = limb0 != 0 or (limb1 & ((@as(u64, 1) << @intCast(part - 1)) - 1)) != 0;
    } else if (shift == 64) {
        quotient = limb2;
        half_bit = limb1 >> 31;
        lower_nonzero = limb0 != 0 or (limb1 & 0x7fff_ffff) != 0;
    } else {
        const part = shift - 64;
        quotient = limb2 >> @intCast(part);
        half_bit = (limb2 >> @intCast(part - 1)) & 1;
        lower_nonzero = limb0 != 0 or limb1 != 0 or (limb2 & ((@as(u64, 1) << @intCast(part - 1)) - 1)) != 0;
    }
    if (half_bit != 0 and (lower_nonzero or (quotient & 1) != 0)) quotient += 1;
    return quotient;
}

fn appendInteger(value: u64, buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize) void {
    var remaining = value;
    var reversed: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + @as(i64, @intCast(@mod(remaining, 10))));
        count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    while (count > 0) {
        count -= 1;
        buffer[used.*] = reversed[count];
        used.* += 1;
    }
}

fn appendFixed(value: f64, buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize) void {
    const bits: u64 = @bitCast(value);
    if ((bits >> 63) != 0) {
        buffer[used.*] = '-';
        used.* += 1;
    }
    const scaled = roundedMicroUnits(bits & 0x7fff_ffff_ffff_ffff);
    appendInteger(scaled / 1_000_000, buffer, used);
    buffer[used.*] = '.';
    used.* += 1;
    var fraction = scaled % 1_000_000;
    var place: u64 = 100_000;
    while (place > 0) {
        buffer[used.*] = @intCast(48 + @as(i64, @intCast(fraction / place)));
        used.* += 1;
        fraction %= place;
        place /= 10;
    }
}

export fn stanford_realmm(pass_count: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (pass_count < 1 or pass_count > MAX_PASSES) return -1;
    if (output_opt == null) return -2;

    const pass_total: usize = @intCast(pass_count);
    var a: [CELL_COUNT]f64 = undefined;
    var b: [CELL_COUNT]f64 = undefined;
    var product: [CELL_COUNT]f64 = undefined;
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    for (0..pass_total) |pass| {
        var seed: i64 = 74755;
        for (0..CELL_COUNT) |index| {
            seed = (seed * 1309 + 13849) & 65535;
            const temp = seed;
            const residue = temp - @divTrunc(temp, 120) * 120 - 60;
            a[index] = @as(f64, @floatFromInt(residue)) / 3.0;
        }
        for (0..CELL_COUNT) |index| {
            seed = (seed * 1309 + 13849) & 65535;
            const temp = seed;
            const residue = temp - @divTrunc(temp, 120) * 120 - 60;
            b[index] = @as(f64, @floatFromInt(residue)) / 3.0;
        }

        for (0..ROWSIZE) |row| {
            for (0..ROWSIZE) |column| {
                var sum: f64 = 0.0;
                for (0..ROWSIZE) |inner| {
                    sum = sum + a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                }
                product[row * ROWSIZE + column] = sum;
            }
        }
        appendFixed(product[pass * ROWSIZE + pass], &staged, &used);
        staged[used] = '\n';
        used += 1;
    }

    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
