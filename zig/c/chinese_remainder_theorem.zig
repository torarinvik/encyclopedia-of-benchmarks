const MAX_INPUTS: usize = 8;
const MAX_MODULUS: i64 = 1000;

fn modularInverse(value: i64, modulus: i64) i64 {
    var old_remainder = @mod(value, modulus);
    var remainder = modulus;
    var old_coefficient: i64 = 1;
    var coefficient: i64 = 0;
    while (remainder != 0) {
        const quotient = @divTrunc(old_remainder, remainder);
        const next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    old_coefficient = @rem(old_coefficient, modulus);
    if (old_coefficient < 0) old_coefficient += modulus;
    return old_coefficient;
}

export fn chinese_remainder_theorem(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUTS or length % 2 != 0) return -1;
    var result: i64 = 0;
    var product: i64 = 1;
    var index: usize = 0;
    while (index < length) : (index += 2) {
        const residue = values[index];
        const modulus = values[index + 1];
        if (modulus < 2 or modulus > MAX_MODULUS or residue < 0 or residue >= modulus) return -1;
        const inverse = modularInverse(@mod(product, modulus), modulus);
        if (inverse < 0) return -1;
        var difference = residue - @mod(result, modulus);
        if (difference < 0) difference += modulus;
        const factor = @rem(difference * inverse, modulus);
        result += product * factor;
        product *= modulus;
    }
    return result;
}
