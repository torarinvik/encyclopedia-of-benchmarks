const MAX_ORDER: usize = 8;
const MODULUS: i64 = 998_244_353;

fn convolve(left: &[i64], right: &[i64]) -> Vec<i64> {
    let mut product = vec![0; left.len() + right.len() - 1];
    for (i, &first) in left.iter().enumerate() {
        for (j, &second) in right.iter().enumerate() {
            product[i + j] = (product[i + j] + first * second) % MODULUS;
        }
    }
    product
}

#[no_mangle]
pub unsafe extern "C" fn bostan_mori_recurrence_term(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let order_word = values[0];
    let index_word = values[1];
    if !(1..=MAX_ORDER as i64).contains(&order_word)
            || !(0..=1_000_000_000_000_000_000i64).contains(&index_word) { return -1; }
    let order = order_word as usize;
    if length != 2 + 2 * order { return -1; }
    let recurrence = &values[2..2 + order];
    let initial = &values[2 + order..];
    if recurrence.iter().chain(initial).any(|&value| !(0..MODULUS).contains(&value)) { return -1; }

    let mut denominator = vec![0; order + 1];
    denominator[0] = 1;
    for i in 0..order { denominator[i + 1] = (MODULUS - recurrence[i]) % MODULUS; }
    let mut numerator = convolve(initial, &denominator)[..order].to_vec();
    let mut index = index_word as u64;
    while index > 0 {
        let denominator_negative: Vec<i64> = denominator.iter().enumerate()
            .map(|(degree, &coefficient)| {
                if degree % 2 == 0 || coefficient == 0 { coefficient }
                else { MODULUS - coefficient }
            })
            .collect();
        let numerator_product = convolve(&numerator, &denominator_negative);
        let denominator_product = convolve(&denominator, &denominator_negative);
        let parity = (index & 1) as usize;
        numerator = (0..order).map(|degree| numerator_product[2 * degree + parity]).collect();
        denominator = (0..=order).map(|degree| denominator_product[2 * degree]).collect();
        index >>= 1;
    }
    numerator[0]
}
