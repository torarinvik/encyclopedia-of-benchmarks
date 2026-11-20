const MAX_CAPACITY: i64 = 8;
const MAX_REQUESTS: usize = 64;
const PAGE_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 67;
const CHECKSUM_RADIX: i64 = 33_281;

#[no_mangle]
pub unsafe extern "C" fn belady_optimal_paging(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let capacity_value = *input;
    let count_value = *input.add(1);
    if !(1..=MAX_CAPACITY).contains(&capacity_value)
        || count_value < 0 || count_value as usize > MAX_REQUESTS
        || length != 2 + count_value as usize { return -1; }
    let capacity = capacity_value as usize;
    let count = count_value as usize;
    let values = std::slice::from_raw_parts(input.add(2), count);
    let mut requests = [0usize; MAX_REQUESTS];
    for time in 0..count {
        if values[time] < 0 || values[time] >= PAGE_COUNT as i64 { return -1; }
        requests[time] = values[time] as usize;
    }
    let mut next_after = [[count; PAGE_COUNT]; MAX_REQUESTS];
    let mut next_position = [count; PAGE_COUNT];
    for time in (0..count).rev() {
        next_after[time] = next_position;
        next_position[requests[time]] = time;
    }

    let mut resident = [false; PAGE_COUNT];
    let mut resident_count = 0usize;
    let mut misses = 0i64;
    let mut eviction_checksum = 0i64;
    for time in 0..count {
        let requested = requests[time];
        if resident[requested] { continue; }
        misses += 1;
        if resident_count == capacity {
            let mut victim = PAGE_COUNT;
            let mut farthest = 0usize;
            for page in 0..PAGE_COUNT {
                if resident[page] && (victim == PAGE_COUNT || next_after[time][page] > farthest) {
                    victim = page;
                    farthest = next_after[time][page];
                }
            }
            resident[victim] = false;
            resident_count -= 1;
            eviction_checksum += ((time + 1) * (victim + 1)) as i64;
        }
        resident[requested] = true;
        resident_count += 1;
    }
    misses * CHECKSUM_RADIX + eviction_checksum
}
