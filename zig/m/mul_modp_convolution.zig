const MaxP: usize = 97;
const MaxInput: usize = 196;
const MaxOutput: usize = 776;
const Mod: i64 = 998244353;

fn powMod(base_input: i64, exponent_input: usize, modulus: usize) usize {
    var base = base_input % @as(i64, @intCast(modulus));
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % @as(i64, @intCast(modulus));
        base = base * base % @as(i64, @intCast(modulus));
        exponent >>= 1;
    }
    return @intCast(result);
}

fn isPrime(p: usize) bool {
    if (p < 2) return false;
    var d: usize = 2;
    while (d * d <= p) : (d += 1) if (p % d == 0) return false;
    return true;
}

fn primitiveRoot(p: usize) usize {
    const order = p - 1;
    var candidate: usize = 1;
    while (candidate < p) : (candidate += 1) {
        var good = true;
        var factor: usize = 2;
        while (factor <= order) : (factor += 1) {
            if (order % factor == 0 and isPrime(factor) and powMod(@intCast(candidate), order / factor, p) == 1) {
                good = false; break;
            }
        }
        if (good) return candidate;
    }
    return 1;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn mul_modp_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MaxInput) return -1;
    const input = input_opt.?;
    const p0 = input[0];
    if (p0 < 2 or p0 > @as(i64, @intCast(MaxP)) or !isPrime(@intCast(p0))) return -1;
    const p: usize = @intCast(p0);
    if (length != 1 + 2 * p) return -1;
    const words = input[0..length];
    for (words[1..]) |x| if (x < 0 or x >= Mod) return -1;
    const bytes = 8 * p;
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    var a: [MaxP]i64 = undefined; var b: [MaxP]i64 = undefined;
    for (0..p) |i| { a[i] = words[1+i]; b[i] = words[1+p+i]; }
    const q = p - 1; const root = primitiveRoot(p);
    var by_exp: [MaxP]usize = undefined; var residue: usize = 1;
    for (0..q) |e| { by_exp[e] = residue; residue = residue * root % p; }
    var left: [MaxP]i64 = undefined; var right: [MaxP]i64 = undefined;
    var cyclic: [MaxP]i64 = undefined; var result: [MaxP]i64 = undefined;
    for (0..MaxP) |i| { cyclic[i] = 0; result[i] = 0; }
    for (0..q) |e| { left[e] = a[by_exp[e]]; right[e] = b[by_exp[e]]; }
    for (0..q) |i| for (0..q) |j| {
        const slot = (i + j) % q;
        cyclic[slot] = (cyclic[slot] + left[i] * right[j] % Mod) % Mod;
    };
    var sum_a: i64 = 0; var sum_b: i64 = 0;
    for (0..p) |i| sum_a = (sum_a + a[i]) % Mod;
    for (1..p) |i| sum_b = (sum_b + b[i]) % Mod;
    result[0] = (sum_a * b[0] % Mod + a[0] * sum_b % Mod) % Mod;
    for (0..q) |e| result[by_exp[e]] = cyclic[e];
    const output = output_opt.?;
    for (0..p) |i| storeLe(output, 8*i, result[i]);
    return @intCast(bytes);
}
