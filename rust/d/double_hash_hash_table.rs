/// Run bounded insert (1), search (2), and delete (3) operations on a double-hash table.
#[no_mangle]
pub extern "C" fn double_hash_hash_table(ptr: *const i64, length: usize) -> i64 {
    if ptr.is_null() || length < 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(ptr, length) };
    let cap64 = input[0]; let count64 = input[1];
    if !(3..=101).contains(&cap64) || count64 < 0 || count64 > 512 { return -1; }
    let cap = cap64 as usize;
    if length != 2 + 2 * count64 as usize { return -1; }
    if (2..).take_while(|d| d * d <= cap).any(|d| cap % d == 0) { return -1; }
    let mut state = [0u8; 101]; let mut keys = [0i64; 101];
    let mut successes = 0i64;
    for i in 0..count64 as usize {
        let op = input[2 + 2 * i]; let key = input[3 + 2 * i];
        if !(1..=3).contains(&op) { return -1; }
        let first = key.rem_euclid(cap64) as usize;
        let step = 1 + key.rem_euclid(cap64 - 1) as usize;
        if op == 1 {
            let mut tomb = cap; let mut inserted = false;
            for p in 0..cap {
                let slot = (first + p * step) % cap;
                if state[slot] == 1 && keys[slot] == key { tomb = cap; break; }
                if state[slot] == 2 && tomb == cap { tomb = slot; }
                if state[slot] == 0 {
                    let target = if tomb == cap { slot } else { tomb };
                    state[target] = 1; keys[target] = key; inserted = true; break;
                }
            }
            if !inserted && tomb != cap { state[tomb] = 1; keys[tomb] = key; inserted = true; }
            successes += inserted as i64;
        } else {
            for p in 0..cap {
                let slot = (first + p * step) % cap;
                if state[slot] == 0 { break; }
                if state[slot] == 1 && keys[slot] == key {
                    successes += 1; if op == 3 { state[slot] = 2; } break;
                }
            }
        }
    }
    successes
}
