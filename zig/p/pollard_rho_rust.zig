const MAX_NUM: i64 = 1_000_000_000;
const U32_MOD: i64 = 4_294_967_296;
const BATCH: i64 = 32;
const CUTOFF: i64 = 262_144;

fn gcdNonnegative(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (left != 0) {
        const remainder = @rem(right, left);
        right = left;
        left = remainder;
    }
    return right;
}

fn modPower(base_value: i64, power_value: i64, modulus: i64) i64 {
    var base = @mod(base_value, modulus);
    var power = power_value;
    if (base == 0) return 0;
    var result: i64 = 1;
    while (power > 0) {
        if (@rem(power, 2) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        power = @divTrunc(power, 2);
    }
    return result;
}

fn passesBase(number: i64, base: i64) bool {
    var odd_power = number - 1;
    var two_power: i64 = 0;
    while (@rem(odd_power, 2) == 0) {
        odd_power = @divTrunc(odd_power, 2);
        two_power += 1;
    }
    var value = modPower(base, odd_power, number);
    if (value == 1 or value == number - 1) return true;
    var r: i64 = 1;
    while (r < two_power) : (r += 1) {
        value = @rem(value * value, number);
        if (value == number - 1) return true;
    }
    return false;
}

fn probablePrime(number: i64) bool {
    if (number <= 4) return number == 2 or number == 3;
    if (number == 5 or number == 7) return true;
    return passesBase(number, 2) and passesBase(number, 3) and passesBase(number, 5) and passesBase(number, 7);
}

fn advance(x: i64, c: i64, number: i64) i64 {
    return @mod(x * x + c, number);
}

fn brentFactor(number: i64, x0: i64, c: i64) i64 {
    var x = x0;
    var x_start: i64 = 0;
    var y: i64 = 0;
    var remainder: i64 = 1;
    var current_gcd: i64 = 1;
    var max_iterations: i64 = 1;
    while (current_gcd == 1) {
        y = x;
        var i: i64 = 1;
        while (i < max_iterations) : (i += 1) x = advance(x, c, number);
        var big_iteration: i64 = 0;
        while (big_iteration < max_iterations and current_gcd == 1) {
            x_start = x;
            var small_iteration: i64 = 0;
            while (small_iteration < BATCH and small_iteration < max_iterations - big_iteration) {
                small_iteration += 1;
                x = advance(x, c, number);
                const difference = if (x >= y) x - y else y - x;
                remainder = @mod(remainder * difference, number);
            }
            current_gcd = gcdNonnegative(remainder, number);
            big_iteration += BATCH;
        }
        max_iterations *= 2;
        if (max_iterations > CUTOFF) break;
    }
    if (current_gcd == number) {
        while (current_gcd == 1) {
            x_start = advance(x_start, c, number);
            const difference = if (x_start >= y) x_start - y else y - x_start;
            current_gcd = gcdNonnegative(difference, number);
        }
    }
    return current_gcd;
}

export fn pollard_rho_rust(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?;
    const number = values[0];
    var state = values[1];
    const restart_limit = values[2];
    if (number < 2 or number > MAX_NUM or state < 0 or state >= U32_MOD or restart_limit < 1 or restart_limit > 16) return -1;
    if (probablePrime(number)) return number;

    var restart: i64 = 0;
    while (restart < restart_limit) : (restart += 1) {
        state = @rem(1_103_515_245 * state + 12_345, U32_MOD);
        const high_x = state;
        state = @rem(1_103_515_245 * state + 12_345, U32_MOD);
        const low_x = state;
        const x_mod = number - 3;
        const x0 = @mod((@mod(high_x, x_mod) * @mod(U32_MOD, x_mod) + @mod(low_x, x_mod)), x_mod) + 2;
        state = @rem(1_103_515_245 * state + 12_345, U32_MOD);
        const high_c = state;
        state = @rem(1_103_515_245 * state + 12_345, U32_MOD);
        const low_c = state;
        const c_mod = number - 2;
        const c = @mod((@mod(high_c, c_mod) * @mod(U32_MOD, c_mod) + @mod(low_c, c_mod)), c_mod) + 1;
        const factor = brentFactor(number, x0, c);
        if (factor != 1 and factor != number) return factor;
    }
    return 0;
}
