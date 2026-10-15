/// Multiplicative persistence for nonnegative Java int inputs.
#[no_mangle]
pub extern "C" fn number_persistence(input_value: i64) -> i64 {
    if !(0..=2_147_483_647).contains(&input_value) { return -1; }
    let mut input = input_value;
    let mut steps = 0i64;
    while input >= 10 {
        let mut product = 1i64;
        let mut remaining = input;
        while remaining > 0 {
            product *= remaining % 10;
            remaining /= 10;
        }
        input = product;
        steps += 1;
    }
    steps
}
