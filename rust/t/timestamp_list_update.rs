const MAX_N: usize = 8;
const MAX_REQUESTS: usize = 32;
const MAX_INPUT: usize = 42;
const MAX_OUTPUT_BYTES: usize = 328;

#[no_mangle]
pub unsafe extern "C" fn timestamp_list_update(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n_raw = *input;
    let requests_raw = *input.add(1);
    if n_raw < 1 || n_raw > MAX_N as i64 || requests_raw < 0 || requests_raw > MAX_REQUESTS as i64 { return -1; }
    let n = n_raw as usize;
    let requests = requests_raw as usize;
    if length != 2 + n + requests { return -1; }
    let mut order = [0usize; MAX_N];
    let mut seen = [false; MAX_N];
    for i in 0..n {
        let item = *input.add(2 + i);
        if item < 0 || item >= n_raw || seen[item as usize] { return -1; }
        order[i] = item as usize; seen[item as usize] = true;
    }
    let mut request_ids = [0usize; MAX_REQUESTS];
    for i in 0..requests {
        let item = *input.add(2 + n + i);
        if item < 0 || item >= n_raw { return -1; }
        request_ids[i] = item as usize;
    }
    let mut last_request = [-1i64; MAX_N];
    let mut positions = [0i64; MAX_REQUESTS];
    let mut total_cost = 0i64;
    for time in 0..requests {
        let item = request_ids[time];
        let mut position = 0;
        while position < n && order[position] != item { position += 1; }
        if position == n { return -1; }
        positions[time] = (position + 1) as i64;
        total_cost += (position + 1) as i64;
        if last_request[item] >= 0 {
            for target in 0..position {
                let candidate = order[target];
                let mut occurrences = 0;
                for t in (last_request[item] as usize + 1)..time {
                    if request_ids[t] == candidate { occurrences += 1; }
                }
                if occurrences <= 1 {
                    for shift in (target + 1..=position).rev() { order[shift] = order[shift - 1]; }
                    order[target] = item;
                    break;
                }
            }
        }
        last_request[item] = time as i64;
    }
    let mut words = [0i64; 1 + MAX_N + MAX_REQUESTS];
    words[0] = total_cost;
    for i in 0..n { words[1 + i] = order[i] as i64; }
    for i in 0..requests { words[1 + n + i] = positions[i]; }
    let output_bytes = 8 * (1 + n + requests);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..1 + n + requests {
        let bytes = words[word].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), staged.as_mut_ptr().add(8 * word), 8);
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
