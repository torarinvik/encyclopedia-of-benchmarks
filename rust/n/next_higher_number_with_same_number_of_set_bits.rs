/// Return the next larger positive integer with the same population count.
#[no_mangle]
pub extern "C" fn next_higher_number_with_same_number_of_set_bits(input: i64) -> i64 {
    if !(1..=1_073_741_823).contains(&input) {
        return -1;
    }
    let right_one = input & -input;
    let next_higher = input + right_one;
    let packed_ones = (input ^ next_higher) / right_one;
    next_higher | (packed_ones >> 2)
}
