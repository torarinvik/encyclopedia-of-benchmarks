const MAX_N: i64 = 30;
const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_SUMS: usize = 465;

#[no_mangle]
pub unsafe extern "C" fn mian_chowla_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    let requested = *input;
    if length != 1 || !(1..=MAX_N).contains(&requested) { return -1; }

    let mut terms = [0i64; 30];
    let mut used_sums = [0i64; MAX_SUMS];
    let mut term_count = 1usize;
    let mut sum_count = 1usize;
    terms[0] = 1;
    used_sums[0] = 2;

    while term_count < requested as usize {
        let mut candidate = terms[term_count - 1] + 1;
        loop {
            let mut valid = true;
            for term in 0..term_count {
                let sum = candidate + terms[term];
                if used_sums[..sum_count].contains(&sum) {
                    valid = false;
                    break;
                }
            }
            if valid && used_sums[..sum_count].contains(&(2 * candidate)) {
                valid = false;
            }
            if valid { break; }
            candidate += 1;
        }

        for term in 0..term_count {
            used_sums[sum_count] = candidate + terms[term];
            sum_count += 1;
        }
        used_sums[sum_count] = 2 * candidate;
        sum_count += 1;
        terms[term_count] = candidate;
        term_count += 1;
    }
    terms[requested as usize - 1]
}
