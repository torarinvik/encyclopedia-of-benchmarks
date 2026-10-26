const MAX_REQUESTS: usize = 7;
const MAX_FILES: usize = 8;
const MAX_INPUT: usize = 23;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn landlord_file_caching(input: *const i64, length: usize,
                                                 output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let capacity_value = values[0];
    let count_value = values[1];
    if capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > MAX_REQUESTS as i64 ||
        length != 2 + 3 * count_value as usize { return -1; }
    let mut known_size = [0i64; MAX_FILES];
    let mut known_cost = [0i64; MAX_FILES];
    let mut seen = [false; MAX_FILES];
    for request in 0..count_value as usize {
        let id = values[2 + 3 * request];
        let size = values[3 + 3 * request];
        let cost = values[4 + 3 * request];
        if id < 0 || id >= MAX_FILES as i64 || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20 { return -1; }
        let slot = id as usize;
        if seen[slot] && (known_size[slot] != size || known_cost[slot] != cost) { return -1; }
        seen[slot] = true; known_size[slot] = size; known_cost[slot] = cost;
    }
    let mut ids = [0i64; MAX_FILES];
    let mut sizes = [0i64; MAX_FILES];
    let mut credits = [0i64; MAX_FILES];
    let mut resident_count = 0usize;
    let mut misses = 0i64;
    let mut total_cost = 0i64;
    let mut hit_signature = 0u64;
    let mut eviction_signature = 0u64;
    let mut resident_mask = 0u64;
    for request in 0..count_value as usize {
        let id = values[2 + 3 * request];
        let size = values[3 + 3 * request];
        let cost = values[4 + 3 * request];
        let mut position = 0;
        while position < resident_count && ids[position] != id { position += 1; }
        if position < resident_count { hit_signature |= 1u64 << request; continue; }
        misses += 1; total_cost += cost;
        let mut evicted_mask = 0u64;
        let mut used: i64 = sizes[..resident_count].iter().sum();
        while used + size > capacity_value {
            let mut delta = credits[0] / sizes[0];
            for i in 1..resident_count {
                let ratio = credits[i] / sizes[i];
                if ratio < delta { delta = ratio; }
            }
            let mut kept = 0usize;
            used = 0;
            for i in 0..resident_count {
                credits[i] -= delta * sizes[i];
                if credits[i] == 0 { evicted_mask |= 1u64 << ids[i] as u32; }
                else {
                    ids[kept] = ids[i]; sizes[kept] = sizes[i]; credits[kept] = credits[i];
                    used += sizes[kept]; kept += 1;
                }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id; sizes[resident_count] = size; credits[resident_count] = cost * 12; resident_count += 1;
    }
    for i in 0..resident_count { resident_mask |= 1u64 << ids[i] as u32; }
    if output.is_null() || capacity < 40 { return -2; }
    let mut staged = [0u8; 40];
    store_i64_le(staged.as_mut_ptr(), 0, misses);
    store_i64_le(staged.as_mut_ptr(), 8, total_cost);
    store_i64_le(staged.as_mut_ptr(), 16, hit_signature as i64);
    store_i64_le(staged.as_mut_ptr(), 24, eviction_signature as i64);
    store_i64_le(staged.as_mut_ptr(), 32, resident_mask as i64);
    for byte in 0..40 { *output.add(byte) = staged[byte]; }
    40
}
