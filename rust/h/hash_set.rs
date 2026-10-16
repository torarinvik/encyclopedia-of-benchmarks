/// Bounded port of the pinned C hash set's ASCII-key insertion and lookup.
const MAX_IDS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 130;
const CAPACITY: usize = 1024;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn adler_key(id: i64) -> u64 {
    let mut a = 1u64;
    let mut b = 0u64;
    for byte in [b'k', b'e', b'y'] {
        a = (a + u64::from(byte)) % 65521;
        b = (b + a) % 65521;
    }
    if id >= 10 {
        a = (a + (id / 10 + 48) as u64) % 65521;
        b = (b + a) % 65521;
    }
    a = (a + (id % 10 + 48) as u64) % 65521;
    b = (b + a) % 65521;
    (b << 16) | a
}

fn bucket_for_id(id: i64) -> usize {
    let hash = adler_key(id);
    ((CAPACITY - 1) as u64 & (hash ^ (hash >> 12))) as usize
}

fn fnv_word(mut hash: u64, value: i64) -> u64 {
    let bits = value as u64;
    for byte in 0..8 {
        hash ^= (bits >> (8 * byte)) & 0xff;
        hash = hash.wrapping_mul(FNV_PRIME);
    }
    hash
}

#[no_mangle]
pub unsafe extern "C" fn hash_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let add_count_value = input[0];
    if !(0..=MAX_IDS).contains(&add_count_value) {
        return -1;
    }
    let add_count = add_count_value as usize;
    let query_count_index = 1 + add_count;
    if query_count_index >= length {
        return -1;
    }
    let query_count_value = input[query_count_index];
    if !(0..=MAX_IDS).contains(&query_count_value) {
        return -1;
    }
    let query_count = query_count_value as usize;
    if length != 2 + add_count + query_count {
        return -1;
    }
    if input[1..query_count_index]
        .iter()
        .chain(input[query_count_index + 1..].iter())
        .any(|&id| !(0..MAX_IDS).contains(&id))
    {
        return -1;
    }

    let mut occupied = [false; CAPACITY];
    let mut slot_ids = [0i64; CAPACITY];
    let mut set_length = 0i64;
    for &id in &input[1..query_count_index] {
        let bucket = bucket_for_id(id);
        if !occupied[bucket] {
            occupied[bucket] = true;
            slot_ids[bucket] = id;
            set_length += 1;
        } else if slot_ids[bucket] != id {
            return -1;
        }
    }

    let mut result = fnv_word(FNV_OFFSET_BASIS, set_length);
    for &id in &input[query_count_index + 1..] {
        let bucket = bucket_for_id(id);
        let contains = i64::from(occupied[bucket] && slot_ids[bucket] == id);
        result = fnv_word(result, contains);
    }
    (result & i64::MAX as u64) as i64
}
