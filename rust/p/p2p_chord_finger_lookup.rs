const MAX_NODES: usize = 16;
const MAX_BITS: usize = 6;
const MAX_INPUT: usize = 116;
const MAX_OUTPUT: usize = 128;

fn put(out: &mut [u8], at: usize, value: i64) { out[at..at + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn p2p_chord_finger_lookup(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_BITS as i64).contains(&values[0]) || !(2..=MAX_NODES as i64).contains(&values[1]) { return -1; }
    let bits = values[0] as usize; let n = values[1] as usize; let ring = 1usize << bits;
    if n > ring || values[2] < 0 || values[2] >= n as i64 || values[3] < 0 || values[3] >= ring as i64 { return -1; }
    if length != 4 + n + n * bits { return -1; }
    let mut ids = [0usize; MAX_NODES]; let mut fingers = [0usize; MAX_NODES * MAX_BITS];
    for i in 0..n {
        let raw = values[4 + i]; if raw < 0 || raw >= ring as i64 { return -1; }
        ids[i] = raw as usize; if i > 0 && ids[i] <= ids[i - 1] { return -1; }
    }
    for node in 0..n {
        for level in 0..bits {
            let target = (ids[node] + (1usize << level)) % ring;
            let mut successor = 0usize;
            while successor < n && ids[successor] < target { successor += 1; }
            if successor == n { successor = 0; }
            let raw = values[4 + n + node * bits + level];
            if raw < 0 || raw >= n as i64 || raw as usize != successor { return -1; }
            fingers[node * bits + level] = successor;
        }
    }
    let key = values[3] as usize; let mut owner = 0usize;
    while owner < n && ids[owner] < key { owner += 1; }
    if owner == n { owner = 0; }
    let mut route = [0usize; MAX_NODES]; let mut route_len = 1usize;
    let mut current = values[2] as usize; route[0] = current;
    for _ in 0..n {
        if current == owner { break; }
        let distance = (ids[owner] + ring - ids[current]) % ring;
        let mut chosen = None;
        for level in (0..bits).rev() {
            let candidate = fingers[current * bits + level];
            let progress = (ids[candidate] + ring - ids[current]) % ring;
            if progress > 0 && progress <= distance { chosen = Some(candidate); break; }
        }
        let next = match chosen { Some(value) => value, None => return -1 };
        if route_len >= n || route[..route_len].contains(&next) { return -1; }
        current = next; route[route_len] = current; route_len += 1;
    }
    if current != owner { return -1; }
    let bytes = 8 * route_len;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    for i in 0..route_len { put(&mut staged, 8 * i, ids[route[i]] as i64); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
