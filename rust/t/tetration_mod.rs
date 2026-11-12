const MAX_VALUE: i64 = 1_000_000_000;

fn totient(value: i64) -> i64 {
    let mut result = value;
    let mut remaining = value;
    if remaining % 2 == 0 {
        result -= result / 2;
        while remaining % 2 == 0 { remaining /= 2; }
    }
    let mut factor = 3i64;
    while factor <= remaining / factor {
        if remaining % factor == 0 {
            result -= result / factor;
            while remaining % factor == 0 { remaining /= factor; }
        }
        factor += 2;
    }
    if remaining > 1 { result -= result / remaining; }
    result
}

fn power_capped(base: i64, exponent_input: i64, cap: i64) -> i64 {
    let mut result = 1i64;
    let mut factor = base.min(cap);
    let mut exponent = exponent_input;
    while exponent > 0 {
        if exponent % 2 != 0 {
            result *= factor;
            if result >= cap { return cap; }
        }
        exponent /= 2;
        if exponent > 0 {
            factor *= factor;
            if factor >= cap { factor = cap; }
        }
    }
    result
}

fn tower_capped(base: i64, height_input: i64, cap: i64) -> i64 {
    if height_input == 0 { return 1.min(cap); }
    if base == 0 { return if height_input % 2 == 0 { 1 } else { 0 }; }
    if base == 1 { return 1.min(cap); }
    let mut value = 1i64;
    if value >= cap { return cap; }
    let mut height = height_input;
    while height > 0 {
        value = power_capped(base, value, cap);
        if value >= cap { return cap; }
        height -= 1;
    }
    value
}

fn modular_power(base_input: i64, exponent_input: i64, modulus: i64) -> i64 {
    let mut result = 1 % modulus;
    let mut base = base_input % modulus;
    let mut exponent = exponent_input;
    while exponent > 0 {
        if exponent % 2 != 0 { result = (result * base) % modulus; }
        exponent /= 2;
        base = (base * base) % modulus;
    }
    result
}

fn tetration(base: i64, height: i64, modulus: i64) -> i64 {
    if modulus == 1 { return 0; }
    if height == 0 { return 1 % modulus; }
    if height == 1 { return base % modulus; }
    let exponent_modulus = totient(modulus);
    let mut exponent = tetration(base, height - 1, exponent_modulus);
    if tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus {
        exponent += exponent_modulus;
    }
    modular_power(base, exponent, modulus)
}

/// Packed input `[A, B, M]`, where `B` is the power-tower height.
#[no_mangle]
pub unsafe extern "C" fn tetration_mod(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let base = *values;
    let height = *values.add(1);
    let modulus = *values.add(2);
    if base < 0 || base > MAX_VALUE || height < 0 || height > MAX_VALUE
        || modulus < 1 || modulus > MAX_VALUE { return -1; }
    tetration(base, height, modulus)
}
