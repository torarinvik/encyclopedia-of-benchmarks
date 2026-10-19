const SIDE: usize = 40;
const MAX_PASSES: i64 = 40;
const MAX_OUTPUT_BYTES: usize = 14 * SIDE;

noinline fn roundedAdd(left: f32, right: f32) f32 { return left + right; }
noinline fn roundedMul(left: f32, right: f32) f32 { return left * right; }
noinline fn roundedDiv(left: f32, right: f32) f32 { return left / right; }

fn nextRandom(seed: *u32) u32 {
    seed.* = (seed.* * 1309 + 13849) & 65535;
    return seed.*;
}

fn computeDiagonalCell(selected: usize) f32 {
    var left: [SIDE * SIDE]f32 = @splat(0);
    var right: [SIDE * SIDE]f32 = @splat(0);
    var result: [SIDE * SIDE]f32 = @splat(0);
    var seed: u32 = 74755;
    for (0..SIDE) |row| {
        for (0..SIDE) |column| {
            const temp = nextRandom(&seed);
            const remainder: i32 = @intCast(temp - (temp / 120) * 120);
            left[row * SIDE + column] = roundedDiv(@floatFromInt(remainder - 60), 3.0);
        }
    }
    for (0..SIDE) |row| {
        for (0..SIDE) |column| {
            const temp = nextRandom(&seed);
            const remainder: i32 = @intCast(temp - (temp / 120) * 120);
            right[row * SIDE + column] = roundedDiv(@floatFromInt(remainder - 60), 3.0);
        }
    }
    for (0..SIDE) |row| {
        for (0..SIDE) |column| {
            var total: f32 = 0;
            for (0..SIDE) |inner| {
                const product = roundedMul(left[row * SIDE + inner], right[inner * SIDE + column]);
                total = roundedAdd(total, product);
            }
            result[row * SIDE + column] = total;
        }
    }
    return result[selected * SIDE + selected];
}

fn writeUnsigned(value_in: u64, output: [*]u8, offset: usize) usize {
    var value = value_in;
    var reversed: [24]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        reversed[count] = @intCast(48 + value % 10);
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    for (0..count) |index| output[offset + index] = reversed[count - index - 1];
    return count;
}

fn writeFixedSix(value: f32, output: [*]u8, offset: usize) usize {
    const bits: u32 = @bitCast(value);
    const exponent_bits = (bits >> 23) & 255;
    const fraction_bits = bits & 0x7fffff;
    const significand: u64 = if (exponent_bits == 0) fraction_bits else ((1 << 23) | fraction_bits);
    const shift: i32 = if (exponent_bits == 0) -149 else @as(i32, @intCast(exponent_bits)) - 150;
    const numerator = significand * 1_000_000;
    var micros: u64 = 0;
    if (shift >= 0) {
        micros = numerator << @intCast(shift);
    } else {
        const denominator_shift: u32 = @intCast(-shift);
        if (denominator_shift >= 64) {
            micros = 0;
        } else {
            micros = numerator >> @intCast(denominator_shift);
            const mask = (@as(u64, 1) << @intCast(denominator_shift)) - 1;
            const remainder = numerator & mask;
            const halfway = @as(u64, 1) << @intCast(denominator_shift - 1);
            if (remainder > halfway or (remainder == halfway and (micros & 1) != 0)) micros += 1;
        }
    }
    var position = offset;
    if ((bits >> 31) != 0) {
        output[position] = '-';
        position += 1;
    }
    position += writeUnsigned(micros / 1_000_000, output, position);
    output[position] = '.';
    position += 1;
    const fractional: u32 = @intCast(micros % 1_000_000);
    var place: u32 = 100_000;
    while (place > 0) {
        output[position] = @intCast(48 + (fractional / place) % 10);
        position += 1;
        place /= 10;
    }
    output[position] = '\n';
    return position + 1 - offset;
}

export fn floatmm(passes: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (passes < 0 or passes > MAX_PASSES) return -1;
    if (passes == 0) return 0;
    if (output_opt == null) return -2;

    var formatted: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var required: usize = 0;
    for (0..@intCast(passes)) |run| {
        const diagonal = computeDiagonalCell(run);
        required += writeFixedSix(diagonal, &formatted, required);
    }
    if (output_capacity < required) return -2;
    const output = output_opt.?;
    for (0..required) |index| output[index] = formatted[index];
    return @intCast(required);
}
