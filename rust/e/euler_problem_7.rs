const SIEVE_LIMIT: usize = 1_000_000;
const MAX_ORDINAL: i64 = 10_001;
const MAX_VALID_INPUT_LENGTH: usize = 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2;

#[no_mangle]
pub unsafe extern "C" fn euler_problem_7(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < MAX_VALID_INPUT_LENGTH || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    if length != MAX_VALID_INPUT_LENGTH {
        return -1;
    }
    let ordinal = *input;
    if !(1..=MAX_ORDINAL).contains(&ordinal) {
        return -1;
    }

    let mut composite = vec![false; SIEVE_LIMIT];
    let mut count = 0i64;
    for candidate in 2..SIEVE_LIMIT {
        if !composite[candidate] {
            count += 1;
            if count == ordinal {
                return candidate as i64;
            }
            let mut multiple = candidate * 2;
            while multiple < SIEVE_LIMIT {
                composite[multiple] = true;
                multiple += candidate;
            }
        }
    }
    -1
}
