const MAX_N: i64 = 14;
const MAX_CANDIDATE: i64 = 64;
const MAX_SUM: usize = 74;
const MAX_PARSEABLE_LENGTH: usize = 2;

#[no_mangle]
pub unsafe extern "C" fn ulam_sequence_1_2(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    let requested = *input;
    if length != 1 || !(1..=MAX_N).contains(&requested) { return -1; }

    let mut terms = [0i64; 14];
    let mut representations = [0i64; MAX_SUM + 1];
    terms[0] = 1;
    terms[1] = 2;
    representations[3] = 1;
    let mut term_count = 2usize;

    while term_count < requested as usize {
        let mut candidate = terms[term_count - 1] + 1;
        while candidate <= MAX_CANDIDATE && representations[candidate as usize] != 1 {
            candidate += 1;
        }
        if candidate > MAX_CANDIDATE { return -1; }
        for old in 0..term_count {
            let sum = (candidate + terms[old]) as usize;
            if representations[sum] < 2 { representations[sum] += 1; }
        }
        terms[term_count] = candidate;
        term_count += 1;
    }
    terms[requested as usize - 1]
}
