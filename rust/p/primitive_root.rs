/// Search in ascending order for a full period of distinct residues.
#[no_mangle]
pub extern "C" fn primitive_root(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let modulus_value = unsafe { *input };
    if !(2..=127).contains(&modulus_value) {
        return -1;
    }
    let modulus = modulus_value as usize;
    for candidate in 1..modulus {
        let mut seen = [false; 127];
        let mut power = 1usize;
        let mut distinct = true;
        for _ in 0..modulus - 1 {
            if seen[power] {
                distinct = false;
                break;
            }
            seen[power] = true;
            power = (power * candidate) % modulus;
        }
        if distinct {
            return candidate as i64;
        }
    }
    0
}
