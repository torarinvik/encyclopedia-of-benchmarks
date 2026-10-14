/// Overflow-safe modular addition; both operands are below modulus.
fn addMod(left: u64, right: u64, modulus: u64) u64 {
    if (left >= modulus - right) return left - (modulus - right);
    return left + right;
}

fn multiplyMod(input_left: u64, input_right: u64, modulus: u64) u64 {
    var left = input_left;
    var right = input_right;
    var result: u64 = 0;
    while (right != 0) {
        if (right & 1 != 0) result = addMod(result, left, modulus);
        right >>= 1;
        if (right != 0) left = addMod(left, left, modulus);
    }
    return result;
}

export fn automorphic_number(n: i64) i64 {
    if (n < 0) return 0;
    const number: u64 = @intCast(n);
    var modulus: u64 = 10;
    var digits = number;
    while (digits >= 10) {
        digits /= 10;
        modulus *= 10;
    }
    return if (multiplyMod(number, number, modulus) == number) 1 else 0;
}
