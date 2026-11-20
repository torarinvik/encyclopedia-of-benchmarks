const MAX_N: i64 = 64;
const MIN_CAP: i64 = 3;
const MAX_CAP: i64 = 256;
const MAX_PARSEABLE_LENGTH: usize = 3;

fn gcd_positive(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn construct_term(requested: i64, candidate_cap: i64) -> i64 {
    let mut terms = [0i64; 64];
    let mut used = [false; 257];
    terms[0] = 1;
    terms[1] = 2;
    terms[2] = 3;
    if requested <= 3 {
        return terms[(requested - 1) as usize];
    }
    used[1] = true;
    used[2] = true;
    used[3] = true;

    let mut term_count = 3usize;
    while term_count < requested as usize {
        let two_back = terms[term_count - 2];
        let previous = terms[term_count - 1];
        let mut candidate = 1i64;
        while candidate <= candidate_cap {
            if !used[candidate as usize]
                && gcd_positive(candidate, two_back) > 1
                && gcd_positive(candidate, previous) == 1
            {
                break;
            }
            candidate += 1;
        }
        if candidate > candidate_cap {
            return -1;
        }
        terms[term_count] = candidate;
        used[candidate as usize] = true;
        term_count += 1;
    }
    terms[(requested - 1) as usize]
}

#[no_mangle]
pub unsafe extern "C" fn yellowstone_permutation_prefix(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    if length != 2 {
        return -1;
    }
    let requested = *input;
    let candidate_cap = *input.add(1);
    if !(1..=MAX_N).contains(&requested)
        || !(MIN_CAP..=MAX_CAP).contains(&candidate_cap)
    {
        return -1;
    }
    construct_term(requested, candidate_cap)
}
