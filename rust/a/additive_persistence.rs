/// Count repeated decimal digit-sum steps until one digit remains.
#[no_mangle]
pub extern "C" fn additive_persistence(input_value: i64) -> i64 {
    if input_value < 0 { return -1; }
    let mut input = input_value;
    let mut steps = 0i64;
    while input >= 10 {
        let mut total = 0i64;
        let mut remaining = input;
        while remaining > 0 {
            total += remaining % 10;
            remaining /= 10;
        }
        input = total;
        steps += 1;
    }
    steps
}
