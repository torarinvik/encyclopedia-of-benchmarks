/// Count sol2's bounded, source-ordered digit-factorial chains.
const MAX_CHAIN_LENGTH: i64 = 60;
const MAX_NUMBER_LIMIT: i64 = 1_000_000;
const PATH_CAPACITY: usize = (MAX_CHAIN_LENGTH + 1) as usize;
const DIGIT_FACTORIALS: [i64; 10] = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880];

fn digit_factorial_sum(mut value: i64) -> i64 {
    let mut total = 0;
    loop {
        total += DIGIT_FACTORIALS[(value % 10) as usize];
        value /= 10;
        if value == 0 { return total; }
    }
}

fn cache_contains(value: i64, number_limit: i64, cache: &[u32]) -> bool {
    value >= 1 && value < number_limit && cache[value as usize] != 0
}

fn path_contains(path: &[i64], value: i64) -> bool {
    path.contains(&value)
}

#[no_mangle]
pub extern "C" fn problem74_sol2(chain_length: i64, number_limit: i64) -> i64 {
    if !(1..=MAX_CHAIN_LENGTH).contains(&chain_length) ||
        !(1..=MAX_NUMBER_LIMIT).contains(&number_limit) { return -1; }
    if number_limit == 1 { return 0; }

    let mut cache = vec![0_u32; number_limit as usize];
    let mut chains_counter = 0_i64;
    for start in 1..number_limit {
        let mut path = [0_i64; PATH_CAPACITY];
        let mut path_length = 0_usize;
        let mut chain_set_length = 0_i64;
        let mut chain_element = start;
        while !cache_contains(chain_element, number_limit, &cache) &&
            !path_contains(&path[..path_length], chain_element) && chain_set_length <= chain_length {
            path[path_length] = chain_element;
            path_length += 1;
            chain_set_length += 1;
            chain_element = digit_factorial_sum(chain_element);
        }
        if cache_contains(chain_element, number_limit, &cache) {
            chain_set_length += i64::from(cache[chain_element as usize]);
        }

        cache[start as usize] = chain_set_length as u32;
        if chain_set_length == chain_length { chains_counter += 1; }
    }
    chains_counter
}
