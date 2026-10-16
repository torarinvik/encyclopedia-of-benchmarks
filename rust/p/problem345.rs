const MAX_DIMENSION: usize = 15;
const MAX_STATES: usize = 1 << MAX_DIMENSION;

fn bit_count(mut value: usize) -> usize {
    let mut count = 0;
    while value != 0 {
        count += value & 1;
        value >>= 1;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn problem345(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_DIMENSION * MAX_DIMENSION + 1 { return -1; }
    let dimension = *input;
    if !(1..=MAX_DIMENSION as i64).contains(&dimension)
        || length != (dimension * dimension) as usize + 1 { return -1; }
    for index in 1..length {
        let value = *input.add(index);
        if !(0..=1000).contains(&value) { return -1; }
    }

    let mut best = [-1i64; MAX_STATES];
    best[0] = 0;
    let state_count = 1usize << dimension as usize;
    for mask in 0..state_count {
        if best[mask] < 0 { continue; }
        let row = bit_count(mask);
        if row >= dimension as usize { continue; }
        for column in 0..dimension as usize {
            let bit = 1usize << column;
            if mask & bit != 0 { continue; }
            let next = mask | bit;
            let value = *input.add(1 + row * dimension as usize + column);
            let candidate = best[mask] + value;
            if candidate > best[next] { best[next] = candidate; }
        }
    }
    best[state_count - 1]
}
