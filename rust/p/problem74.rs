/// Count starts with the source's memoized digit-factorial chain length.
const MAX_START: i64 = 1_000_000;
const CACHE_SIZE: usize = 2_540_161;
const MAX_PATH_LENGTH: usize = 128;
const DIGIT_FACTORIALS: [i64; 10] = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880];

fn sum_digit_factorials(value: i64) -> i64 {
    let mut remaining = value;
    let mut total = 0;
    while remaining > 0 {
        total += DIGIT_FACTORIALS[(remaining % 10) as usize];
        remaining /= 10;
    }
    if value == 0 { 1 } else { total }
}

fn chain_length(start: i64, cache: &mut [u8; CACHE_SIZE]) -> i64 {
    let mut path = [0i64; MAX_PATH_LENGTH];
    let mut path_length = 0usize;
    let mut current = start;
    let mut result = 0i64;
    loop {
        let encoded = cache[current as usize];
        if encoded != 0 {
            result = i64::from(encoded) - 1;
            break;
        }
        let next_value = sum_digit_factorials(current);
        if path[..path_length].contains(&next_value) {
            cache[current as usize] = 1;
            result = 0;
            break;
        }
        path[path_length] = current;
        path_length += 1;
        current = next_value;
    }
    while path_length > 0 {
        path_length -= 1;
        current = path[path_length];
        result += 1;
        cache[current as usize] = (result + 1) as u8;
    }
    i64::from(cache[start as usize]) - 1
}

#[no_mangle]
pub extern "C" fn problem74(num_terms: i64, max_start: i64) -> i64 {
    if max_start > MAX_START { return -1; }
    if max_start <= 1 { return 0; }
    let mut cache = [0u8; CACHE_SIZE];
    cache[145] = 1;
    cache[169] = 4;
    cache[36301] = 4;
    cache[1454] = 4;
    cache[871] = 3;
    cache[45361] = 3;
    cache[872] = 3;
    let mut count = 0i64;
    for start in 1..max_start {
        if chain_length(start, &mut cache) == num_terms { count += 1; }
    }
    count
}
