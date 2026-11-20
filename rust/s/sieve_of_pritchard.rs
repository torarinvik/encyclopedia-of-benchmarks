/// Count primes through limit with Pritchard's dynamic wheel sieve.
#[no_mangle]
pub extern "C" fn sieve_of_pritchard(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if length != 1 || !(2..=1024).contains(&values[0]) {
        return -1;
    }

    let limit = values[0] as i32;
    let sentinel = limit + 1;
    let mut next_node = [0i32; 1026];
    let mut previous = [0i32; 1026];
    next_node[1] = sentinel;
    next_node[sentinel as usize] = sentinel;
    previous[sentinel as usize] = 1;

    let mut wheel_length = 2i32;
    let mut prime = 3i32;
    let mut prime_count = 1i64;
    while prime * prime <= limit {
        if wheel_length < limit {
            let product = prime * wheel_length;
            let target = if product < limit { product } else { limit };
            let mut wheel_value = 1i32;
            let mut candidate = wheel_length + 1;
            while candidate <= target {
                let tail = previous[sentinel as usize];
                next_node[tail as usize] = candidate;
                previous[candidate as usize] = tail;
                next_node[candidate as usize] = sentinel;
                previous[sentinel as usize] = candidate;
                wheel_value = next_node[wheel_value as usize];
                candidate = wheel_length + wheel_value;
            }
            wheel_length = target;
        }

        let mut wheel_value = prime;
        while prime * wheel_value <= wheel_length {
            wheel_value = next_node[wheel_value as usize];
        }
        while wheel_value > 1 {
            wheel_value = previous[wheel_value as usize];
            let removed = prime * wheel_value;
            let left = previous[removed as usize];
            let right = next_node[removed as usize];
            next_node[left as usize] = right;
            previous[right as usize] = left;
        }
        prime_count += 1;
        prime = next_node[1];
    }

    if wheel_length < limit {
        let mut wheel_value = 1i32;
        let mut candidate = wheel_length + 1;
        while candidate <= limit {
            let tail = previous[sentinel as usize];
            next_node[tail as usize] = candidate;
            previous[candidate as usize] = tail;
            next_node[candidate as usize] = sentinel;
            previous[sentinel as usize] = candidate;
            wheel_value = next_node[wheel_value as usize];
            candidate = wheel_length + wheel_value;
        }
        wheel_length = limit;
    }

    let mut remaining = 0i64;
    let mut value = next_node[1];
    while value != sentinel {
        remaining += 1;
        value = next_node[value as usize];
    }
    prime_count + remaining
}
