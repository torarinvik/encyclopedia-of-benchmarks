/// Count ASCII vowels and consonants, packing both counts into one i64.
const COUNT_BASE: i64 = 4_294_967_296;

#[no_mangle]
pub unsafe extern "C" fn count_vowels_consonants(values: *const i64, length: usize) -> i64 {
    if length > 100_000 || (length != 0 && values.is_null()) { return -1; }
    let mut vowels = 0i64;
    let mut consonants = 0i64;
    for index in 0..length {
        let code = *values.add(index);
        if !(0..=127).contains(&code) { return -1; }
        if (65..=90).contains(&code) || (97..=122).contains(&code) {
            let letter = code | 32;
            if letter == 97 || letter == 101 || letter == 105 || letter == 111 || letter == 117 {
                vowels += 1;
            } else {
                consonants += 1;
            }
        }
    }
    vowels * COUNT_BASE + consonants
}
