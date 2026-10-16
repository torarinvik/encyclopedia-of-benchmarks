fn dotnetSample(seed: *[56]i32, next: *usize, next_p: *usize) i32 {
    next.* += 1;
    if (next.* >= 56) next.* = 1;
    next_p.* += 1;
    if (next_p.* >= 56) next_p.* = 1;
    var value = seed[next.*] - seed[next_p.*];
    if (value == 2_147_483_647) value -= 1;
    if (value < 0) value += 2_147_483_647;
    seed[next.*] = value;
    return value;
}

fn modPow(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@as(u64, @bitCast(exponent)) & 1 != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

export fn fermat_prime_checker(number: i64, times_to_check: i64) i64 {
    if (number < 2 or number > 1_000_000 or times_to_check < 2 or times_to_check > 64) return -1;
    var seed = [_]i32{0} ** 56;
    var mj: i32 = 161_803_398;
    var mk: i32 = 1;
    seed[55] = mj;
    for (1..55) |i| {
        const index = (21 * i) % 55;
        seed[index] = mk;
        mk = mj - mk;
        if (mk < 0) mk += 2_147_483_647;
        mj = seed[index];
    }
    for (0..4) |_| {
        for (1..56) |i| {
            seed[i] -= seed[1 + (i + 30) % 55];
            if (seed[i] < 0) seed[i] += 2_147_483_647;
        }
    }
    var next: usize = 0;
    var next_p: usize = 21;
    var iteration: i64 = 1;
    while (iteration < times_to_check) : (iteration += 1) {
        const sample = dotnetSample(&seed, &next, &next_p);
        const base: i64 = @as(i64, @intFromFloat(@as(f64, @floatFromInt(sample)) / 2_147_483_647.0 * @as(f64, @floatFromInt(number - 1)))) + 1;
        if (modPow(base, number - 1, number) != 1) return 0;
    }
    return 1;
}
