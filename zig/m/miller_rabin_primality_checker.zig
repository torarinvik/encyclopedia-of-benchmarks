const MAX_N: i64 = 2147483647;
fn nextWord(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var z = state.*;
    z = (z ^ (z >> 30)) *% 0xBF58476D1CE4E5B9;
    z = (z ^ (z >> 27)) *% 0x94D049BB133111EB;
    return z ^ (z >> 31);
}
fn modPower(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = @mod(base_value, modulus);
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}
fn passesWitness(n: i64, a: i64, d: i64, powers_of_two: i64) bool {
    var x = modPower(a, d, n);
    if (x == 1 or x == n - 1) return true;
    var round: i64 = 1;
    while (round < powers_of_two) : (round += 1) {
        x = @rem(x * x, n);
        if (x == n - 1) return true;
    }
    return false;
}
export fn miller_rabin_primality_checker(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > 4) return -1;
    const n = values[0];
    const rounds = values[1];
    const seed = values[2];
    if (length != 3 or n < 5 or n > MAX_N or @rem(n, 2) == 0 or rounds < 1 or rounds > 64 or seed < 0 or seed > MAX_N) return -1;
    var state: u64 = @intCast(seed);
    const span: u64 = @intCast(n - 4);
    const threshold = (0 -% span) % span;
    var word: u64 = undefined;
    while (true) { word = nextWord(&state); if (word >= threshold) break; }
    const a: i64 = 2 + @as(i64, @intCast(word % span));
    var d = n - 1;
    var powers_of_two: i64 = 0;
    while (@rem(d, 2) == 0) { d = @divTrunc(d, 2); powers_of_two += 1; }
    var index: i64 = 0;
    while (index < rounds) : (index += 1) if (!passesWitness(n, a, d, powers_of_two)) return 0;
    return 1;
}
