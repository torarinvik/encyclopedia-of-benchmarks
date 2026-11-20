const MAX_CAPACITY: usize = 32;
const MAX_INPUT_LENGTH: usize = 35;
const MAX_KEY: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn lcfs_hashing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let capacity_value = values[0];
    let count_value = values[1];
    if capacity_value < 1 || capacity_value > MAX_CAPACITY as i64
        || count_value < 0 || count_value > capacity_value
        || length != count_value as usize + 2
    {
        return -1;
    }
    let capacity = capacity_value as usize;
    let count = count_value as usize;
    let keys = &values[2..];
    for i in 0..count {
        if !(0..=MAX_KEY).contains(&keys[i])
            || keys[..i].iter().any(|&key| key == keys[i])
        {
            return -1;
        }
    }

    let mut table = [-1i64; MAX_CAPACITY];
    let mut displacements = 0i64;
    for &key in keys {
        let mut incoming = key;
        let mut slot = (incoming % capacity_value) as usize;
        let mut probes = 0usize;
        while table[slot] != -1 {
            if probes >= capacity {
                return -1;
            }
            let resident = table[slot];
            table[slot] = incoming;
            incoming = resident;
            slot = (slot + 1) % capacity;
            probes += 1;
            displacements += 1;
        }
        table[slot] = incoming;
    }
    displacements
}
