const MAX_N: usize = 8;
const MAX_REQUESTS: usize = 32;
const MAX_INPUT: usize = 50;
const MAX_OUTPUT_BYTES: usize = 392;

#[no_mangle]
pub unsafe extern "C" fn bit_list_update(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n_raw = *input; let requests_raw = *input.add(1);
    if n_raw < 1 || n_raw > MAX_N as i64 || requests_raw < 0 || requests_raw > MAX_REQUESTS as i64 { return -1; }
    let n = n_raw as usize; let requests = requests_raw as usize;
    if length != 2 + 2 * n + requests { return -1; }
    let mut order = [0usize; MAX_N]; let mut seen = [false; MAX_N];
    for i in 0..n { let page = *input.add(2 + i); if page < 0 || page >= n_raw || seen[page as usize] { return -1; } order[i] = page as usize; seen[page as usize] = true; }
    let mut request_ids = [0usize; MAX_REQUESTS];
    for i in 0..requests { let page = *input.add(2 + n + i); if page < 0 || page >= n_raw { return -1; } request_ids[i] = page as usize; }
    let mut bits = [0i64; MAX_N];
    for i in 0..n { let bit = *input.add(2 + n + requests + i); if bit != 0 && bit != 1 { return -1; } bits[i] = bit; }
    let mut positions = [0i64; MAX_REQUESTS]; let mut total_cost = 0i64;
    for time in 0..requests {
        let page = request_ids[time]; let mut position = 0;
        while position < n && order[position] != page { position += 1; }
        if position == n { return -1; }
        positions[time] = (position + 1) as i64; total_cost += (position + 1) as i64; bits[page] ^= 1;
        if bits[page] == 1 && position > 0 { for shift in (1..=position).rev() { order[shift] = order[shift - 1]; } order[0] = page; }
    }
    let mut words = [0i64; 1 + 2 * MAX_N + MAX_REQUESTS]; words[0] = total_cost;
    for i in 0..n { words[1 + i] = order[i] as i64; }
    for i in 0..requests { words[1 + n + i] = positions[i]; }
    for i in 0..n { words[1 + n + requests + i] = bits[i]; }
    let output_bytes = 8 * (1 + 2 * n + requests);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..1 + 2 * n + requests { let bytes = words[word].to_le_bytes(); std::ptr::copy_nonoverlapping(bytes.as_ptr(), staged.as_mut_ptr().add(8 * word), 8); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes); output_bytes as i64
}
