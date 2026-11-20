fn fundamental_solution(discriminant: i64) -> (i64, i64) {
    let mut root = 0_i64;
    while (root + 1) * (root + 1) <= discriminant {
        root += 1;
    }

    let (mut previous_numerator, mut numerator) = (0_i64, 1_i64);
    let (mut previous_denominator, mut denominator) = (1_i64, 0_i64);
    let (mut m, mut d, mut a) = (0_i64, 1_i64, root);

    loop {
        let next_numerator = a * numerator + previous_numerator;
        let next_denominator = a * denominator + previous_denominator;
        if next_numerator * next_numerator - discriminant * next_denominator * next_denominator == 1 {
            return (next_numerator, next_denominator);
        }

        previous_numerator = numerator;
        numerator = next_numerator;
        previous_denominator = denominator;
        denominator = next_denominator;

        m = d * a - m;
        d = (discriminant - m * m) / d;
        a = (root + m) / d;
    }
}

#[no_mangle]
pub unsafe extern "C" fn pell_fundamental_solution(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let discriminant = *input;
    if !(2..=31).contains(&discriminant) { return -1; }

    let mut root = 0_i64;
    while (root + 1) * (root + 1) <= discriminant {
        root += 1;
    }
    if root * root == discriminant { return -1; }

    let (x, y) = fundamental_solution(discriminant);
    (x << 32) | y
}
