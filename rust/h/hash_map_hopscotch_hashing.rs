const SLOTS: usize = 16;
const H: usize = 4;
const MAX_OPS: usize = 32;
const MAX_WORDS: usize = 1 + 3 * MAX_OPS;

fn distance(from: usize, to: usize) -> usize {
    (to + SLOTS - from) % SLOTS
}

fn contains(keys: &[i16; SLOTS], hops: &[u8; SLOTS], key: i16, home: usize) -> bool {
    for offset in 0..H {
        if hops[home] & (1 << offset) != 0
            && keys[(home + offset) % SLOTS] == key
        {
            return true;
        }
    }
    false
}

fn insert(
    keys: &mut [i16; SLOTS],
    homes: &mut [u8; SLOTS],
    hops: &mut [u8; SLOTS],
    key: i16,
    home: usize,
) -> u8 {
    if contains(keys, hops, key, home) { return 2; }
    let mut hole = None;
    for step in 0..SLOTS {
        let slot = (home + step) % SLOTS;
        if keys[slot] < 0 {
            hole = Some(slot);
            break;
        }
    }
    let Some(mut empty) = hole else { return 0; };
    let mut reach = distance(home, empty);
    while reach >= H {
        let mut shifted = false;
        for back in (1..H).rev() {
            let bucket = (empty + SLOTS - back) % SLOTS;
            let new_offset = distance(bucket, empty);
            if distance(home, bucket) >= reach { continue; }
            for old_offset in 0..new_offset {
                if hops[bucket] & (1 << old_offset) == 0 { continue; }
                let old_slot = (bucket + old_offset) % SLOTS;
                if keys[old_slot] < 0 || homes[old_slot] as usize != bucket
                    || distance(home, old_slot) >= reach
                {
                    continue;
                }
                keys[empty] = keys[old_slot];
                homes[empty] = homes[old_slot];
                keys[old_slot] = -1;
                homes[old_slot] = 0;
                hops[bucket] &= !(1 << old_offset);
                hops[bucket] |= 1 << new_offset;
                empty = old_slot;
                reach = distance(home, empty);
                shifted = true;
                break;
            }
            if shifted { break; }
        }
        if !shifted { return 0; }
    }
    keys[empty] = key;
    homes[empty] = home as u8;
    hops[home] |= 1 << reach;
    1
}

#[no_mangle]
pub unsafe extern "C" fn hash_map_hopscotch_hashing(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_WORDS { return -1; }
    let count_value = unsafe { *input };
    if count_value < 0 || count_value > MAX_OPS as i64 { return -1; }
    let count = count_value as usize;
    if length != 1 + 3 * count { return -1; }

    let mut known_home = [-1i8; 64];
    for op in 0..count {
        let opcode = unsafe { *input.add(1 + 3 * op) };
        let key = unsafe { *input.add(2 + 3 * op) };
        let home = unsafe { *input.add(3 + 3 * op) };
        if (opcode != 1 && opcode != 2) || !(0..64).contains(&key)
            || !(0..SLOTS as i64).contains(&home)
        {
            return -1;
        }
        let key_index = key as usize;
        if known_home[key_index] >= 0 && known_home[key_index] as i64 != home { return -1; }
        known_home[key_index] = home as i8;
    }

    let required = count + 2 * SLOTS;
    if output.is_null() || capacity < required { return -2; }
    let mut keys = [-1i16; SLOTS];
    let mut homes = [0u8; SLOTS];
    let mut hops = [0u8; SLOTS];
    let mut statuses = [0u8; MAX_OPS];
    for op in 0..count {
        let opcode = unsafe { *input.add(1 + 3 * op) };
        let key = unsafe { *input.add(2 + 3 * op) } as i16;
        let home = unsafe { *input.add(3 + 3 * op) } as usize;
        statuses[op] = if opcode == 1 {
            insert(&mut keys, &mut homes, &mut hops, key, home)
        } else {
            contains(&keys, &hops, key, home) as u8
        };
    }
    let mut cursor = 0;
    for status in statuses.iter().take(count) {
        unsafe { output.add(cursor).write(*status); }
        cursor += 1;
    }
    for key in keys {
        unsafe { output.add(cursor).write(if key < 0 { 0 } else { key as u8 + 1 }); }
        cursor += 1;
    }
    for mask in hops {
        unsafe { output.add(cursor).write(mask); }
        cursor += 1;
    }
    required as i64
}
