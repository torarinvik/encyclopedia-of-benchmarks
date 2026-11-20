const MAX_PRIME: i64 = 1_000_003;

#[derive(Clone, Copy)]
struct Pair {
    real: i64,
    radical: i64,
}

fn modular_power(base_value: i64, exponent_value: i64, prime: i64) -> i64 {
    let mut result = 1i64;
    let mut base = base_value % prime;
    let mut exponent = exponent_value;
    while exponent > 0 {
        if exponent % 2 != 0 {
            result = (result * base) % prime;
        }
        exponent /= 2;
        if exponent > 0 {
            base = (base * base) % prime;
        }
    }
    result
}

fn legendre(value: i64, prime: i64) -> i64 {
    let symbol = modular_power(value % prime, (prime - 1) / 2, prime);
    if symbol == prime - 1 { -1 } else { symbol }
}

fn multiply(left: Pair, right: Pair, radicand: i64, prime: i64) -> Pair {
    Pair {
        real: (left.real * right.real + radicand * left.radical * right.radical) % prime,
        radical: (left.real * right.radical + left.radical * right.real) % prime,
    }
}

fn pair_power(base: Pair, exponent_value: i64, radicand: i64, prime: i64) -> Pair {
    let mut result = Pair { real: 1, radical: 0 };
    let mut factor = base;
    let mut exponent = exponent_value;
    while exponent > 0 {
        if exponent % 2 != 0 {
            result = multiply(result, factor, radicand, prime);
        }
        exponent /= 2;
        if exponent > 0 {
            factor = multiply(factor, factor, radicand, prime);
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn cipolla_modular_square_root(packed: *const i64, length: usize) -> i64 {
    unsafe {
        if packed.is_null() || length != 2 {
            return -1;
        }
        let residue = *packed;
        let prime = *packed.add(1);
        if !(3..=MAX_PRIME).contains(&prime)
            || prime % 2 == 0
            || residue < 0
            || residue >= prime
        {
            return -1;
        }
        if residue == 0 {
            return 0;
        }
        if legendre(residue, prime) != 1 {
            return -1;
        }

        let mut parameter = 0i64;
        let mut radicand = 0i64;
        while parameter < prime {
            radicand = (parameter * parameter - residue) % prime;
            if radicand < 0 {
                radicand += prime;
            }
            if legendre(radicand, prime) == -1 {
                break;
            }
            parameter += 1;
        }
        if parameter == prime {
            return -1;
        }

        let result = pair_power(
            Pair { real: parameter, radical: 1 },
            (prime + 1) / 2,
            radicand,
            prime,
        );
        if result.real < prime - result.real {
            result.real
        } else {
            prime - result.real
        }
    }
}
