fn floor_sqrt(value: i64) -> i64 {
    let mut root = 0_i64;
    while (root + 1) * (root + 1) <= value { root += 1; }
    root
}

#[no_mangle]
pub unsafe extern "C" fn four_square_sum_representation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n = *input;
    if !(0..=1024).contains(&n) { return -1; }

    let mut a = floor_sqrt(n);
    while a >= 0 {
        let remainder_a = n - a * a;
        let mut b_max = floor_sqrt(remainder_a);
        if b_max > a { b_max = a; }
        let mut b = b_max;
        while b >= 0 {
            let remainder_b = remainder_a - b * b;
            let mut c_max = floor_sqrt(remainder_b);
            if c_max > b { c_max = b; }
            let mut c = c_max;
            while c >= 0 {
                let remainder_c = remainder_b - c * c;
                let d = floor_sqrt(remainder_c);
                if d <= c && d * d == remainder_c {
                    return (((a * 33 + b) * 33 + c) * 33 + d);
                }
                c -= 1;
            }
            b -= 1;
        }
        a -= 1;
    }
    -2
}
