const MAX_REQUESTS: usize = 4096;
const MAX_TRACK: usize = 256;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_i64(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn look_scheduling(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_REQUESTS + 4 { return -1; }
    let a = unsafe { std::slice::from_raw_parts(input, length) };
    let max_track64 = a[0];
    let start64 = a[1];
    let direction = a[2];
    let count64 = a[3];
    if max_track64 < 1 || max_track64 > MAX_TRACK as i64 || start64 < 0 || start64 >= max_track64 ||
        (direction != 0 && direction != 1) || count64 < 0 || count64 > MAX_REQUESTS as i64 || length != count64 as usize + 4 { return -1; }
    let max_track = max_track64 as usize;
    let start = start64 as usize;
    let mut lower_counts = [0usize; MAX_TRACK];
    let mut upper_counts = [0usize; MAX_TRACK];
    let mut farthest = 0i64;
    for &request in &a[4..] {
        if request < i32::MIN as i64 || request > i32::MAX as i64 { return -1; }
        if request >= 0 && request < max_track64 {
            let track = request as usize;
            if track < start { lower_counts[track] += 1; } else { upper_counts[track] += 1; }
            if request > farthest { farthest = request; }
        }
    }

    let mut route = [0i64; MAX_REQUESTS];
    let mut route_count = 0usize;
    if direction == 1 {
        for track in start..max_track {
            for _ in 0..upper_counts[track] { route[route_count] = track as i64; route_count += 1; }
        }
        let mut track = start;
        while track > 0 {
            track -= 1;
            for _ in 0..lower_counts[track] { route[route_count] = track as i64; route_count += 1; }
        }
    } else {
        let mut track = start;
        while track > 0 {
            track -= 1;
            for _ in 0..lower_counts[track] { route[route_count] = track as i64; route_count += 1; }
        }
        for track in start..max_track {
            for _ in 0..upper_counts[track] { route[route_count] = track as i64; route_count += 1; }
        }
    }
    let mut hash = hash_i64(FNV_OFFSET, route_count as i64);
    for &request in &route[..route_count] { hash = hash_i64(hash, request); }
    hash = hash_i64(hash, if direction == 1 { 0 } else { 1 });
    hash = hash_i64(hash, farthest);
    hash = hash_i64(hash, start64);
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
