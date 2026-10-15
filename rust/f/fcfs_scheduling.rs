unsafe fn store_i64_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(position + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn fcfs_scheduling(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || !(1..=193).contains(&length) { return -2; }
    let count_value = *values;
    if !(0..=64).contains(&count_value) { return -2; }
    let count = count_value as usize;
    if length != 1 + 3 * count { return -2; }

    let mut ids = [0_i64; 64];
    let mut arrivals = [0_i64; 64];
    let mut bursts = [0_i64; 64];
    let mut order = [0_usize; 64];
    for i in 0..count {
        let id = *values.add(1 + 3 * i);
        let arrival = *values.add(2 + 3 * i);
        let burst = *values.add(3 + 3 * i);
        if !(0..=63).contains(&id) || !(0..=1_000_000).contains(&arrival)
            || !(1..=1_000_000).contains(&burst) { return -2; }
        if ids[..i].contains(&id) { return -2; }
        ids[i] = id;
        arrivals[i] = arrival;
        bursts[i] = burst;
        order[i] = i;
    }
    for i in 1..count {
        let key = order[i];
        let mut j = i;
        while j > 0 && (arrivals[order[j - 1]] > arrivals[key]
            || (arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key])) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = key;
    }

    let required = count * 48;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut elapsed = 0_i64;
    for position in 0..count {
        let i = order[position];
        if elapsed < arrivals[i] { elapsed = arrivals[i]; }
        let completion = elapsed + bursts[i];
        let turnaround = completion - arrivals[i];
        let waiting = turnaround - bursts[i];
        let fields = [ids[i], arrivals[i], bursts[i], completion, turnaround, waiting];
        for field in 0..6 {
            store_i64_le(output, position * 48 + field * 8, fields[field]);
        }
        elapsed = completion;
    }
    count as i64
}
