/* Clean-room bounded CFRAC profile based on the published
   Morrison-Brillhart continued-fraction factorization method.
   No code from the restricted arbitrary-precision package is included. */
const MAX_BASE: usize = 10;
const MAX_ITERATIONS: usize = 48;
const MAX_PRIME: u32 = 10000;

fn gcd(a_value: u64, b_value: u64) u64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) { const r = a % b; a = b; b = r; }
    return a;
}

fn modpow(base_value: u64, exponent_value: u64, modulus: u64) u64 {
    var base = base_value % modulus;
    var exponent = exponent_value;
    var result: u64 = 1;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn isPrime(value: u32) bool {
    if (value < 2) return false;
    var divisor: u32 = 2;
    while (@as(u64, divisor) * divisor <= value) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn makeBase(n: u64, requested: usize, base: *[MAX_BASE]u32) bool {
    var count: usize = 1;
    base[0] = 2;
    var p: u32 = 3;
    while (p <= MAX_PRIME and count < requested) : (p += 2) {
        if (!isPrime(p)) continue;
        const residue = modpow(n % p, (p - 1) / 2, p);
        // Upstream selects residue zero too; this profile rejects that domain case.
        if (residue == 0) return false;
        if (residue == 1) {
            base[count] = p;
            count += 1;
        }
    }
    return count == requested;
}

export fn mallocbench_cfrac(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const n_value = input[0];
    const base_value = input[1];
    const iteration_value = input[2];
    if (n_value < 15 or n_value > 1_000_000 or (n_value & 1) == 0 or
        base_value < 2 or base_value > MAX_BASE or iteration_value < 1 or iteration_value > MAX_ITERATIONS) return -1;
    const n: u64 = @intCast(n_value);
    var root: u64 = 0;
    while (root + 1 <= n / (root + 1)) : (root += 1) {}
    if (root * root == n) return -1;
    const base_count: usize = @intCast(base_value);
    const iteration_limit: usize = @intCast(iteration_value);
    var base: [MAX_BASE]u32 = undefined;
    if (!makeBase(n, base_count, &base)) return -1;

    var basis_vector = [_]u64{0} ** (MAX_BASE + 1);
    var basis_combo = [_]u64{0} ** (MAX_BASE + 1);
    var basis_used = [_]bool{false} ** (MAX_BASE + 1);
    var relation_a = [_]u64{0} ** MAX_ITERATIONS;
    var relation_exp = [_][MAX_BASE]u8{[_]u8{0} ** MAX_BASE} ** MAX_ITERATIONS;
    var relation_count: usize = 0;
    var u: i64 = @intCast(2 * root);
    var previous_u = u;
    var q_value: i64 = 0;
    var q_denominator: i64 = 1;
    var previous_denominator: i64 = @intCast(n - root * root);
    var a_value: i64 = 1;
    var previous_a: i64 = @intCast(root);
    var sign: u64 = 0;

    for (0..iteration_limit) |_| {
        const old_a = a_value;
        a_value = @rem(q_value * a_value + previous_a, n_value);
        previous_a = old_a;
        const old_denominator = q_denominator;
        q_denominator = q_value * (previous_u - u) + previous_denominator;
        previous_denominator = old_denominator;
        previous_u = u;
        if (q_denominator <= 0) return n_value;
        q_value = 1;
        var remainder = u - q_denominator;
        if (remainder >= q_denominator) {
            q_value = @divTrunc(u, q_denominator);
            remainder = @rem(u, q_denominator);
        }
        u = @as(i64, @intCast(2 * root)) - remainder;
        sign ^= 1;
        if (q_denominator == 1) return n_value;

        var residual: u64 = @intCast(q_denominator);
        var exponents = [_]u8{0} ** MAX_BASE;
        for (0..base_count) |j| {
            while (residual % base[j] == 0) { residual /= base[j]; exponents[j] += 1; }
        }
        if (residual != 1) continue;
        relation_a[relation_count] = @intCast(a_value);
        relation_exp[relation_count] = exponents;
        var vector = sign;
        for (0..base_count) |j| if ((exponents[j] & 1) != 0) { vector |= @as(u64, 1) << @intCast(j + 1); };
        var combination: u64 = @as(u64, 1) << @intCast(relation_count);
        relation_count += 1;
        var inserted = false;
        for (0..base_count + 1) |bit| {
            const bit_mask: u64 = @as(u64, 1) << @intCast(bit);
            if ((vector & bit_mask) == 0) continue;
            if (basis_used[bit]) {
                vector ^= basis_vector[bit];
                combination ^= basis_combo[bit];
            } else {
                basis_used[bit] = true;
                basis_vector[bit] = vector;
                basis_combo[bit] = combination;
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            var x: u64 = 1;
            var exponent_sum = [_]u64{0} ** MAX_BASE;
            for (0..relation_count) |i| {
                if ((combination & (@as(u64, 1) << @intCast(i))) == 0) continue;
                x = (x * relation_a[i]) % n;
                for (0..base_count) |j| exponent_sum[j] += relation_exp[i][j];
            }
            var y: u64 = 1;
            for (0..base_count) |j| y = (y * modpow(base[j], exponent_sum[j] / 2, n)) % n;
            const minus = gcd(if (x >= y) x - y else y - x, n);
            if (minus > 1 and minus < n) return @intCast(minus);
            const plus = gcd(x + y, n);
            if (plus > 1 and plus < n) return @intCast(plus);
        }
    }
    return n_value;
}
