const TABLE_SIZE: usize = 65_536;
const TABLE_MASK: usize = TABLE_SIZE - 1;
const MAX_MODULUS: u64 = 1_000_000_007;

fn ceil_sqrt(value: u64) -> u64 {
    let (mut low, mut high) = (1u64, 31_624u64);
    while low < high {
        let middle = low + (high - low) / 2;
        if middle * middle >= value { high = middle; } else { low = middle + 1; }
    }
    low
}

fn insert_baby(keys: &mut [u64], encoded_steps: &mut [u32], key: u64, step: u32) {
    let mut slot = (key as usize) & TABLE_MASK;
    while encoded_steps[slot] != 0 && keys[slot] != key { slot = (slot + 1) & TABLE_MASK; }
    keys[slot] = key;
    encoded_steps[slot] = step + 1;
}

fn find_baby(keys: &[u64], encoded_steps: &[u32], key: u64) -> Option<u64> {
    let mut slot = (key as usize) & TABLE_MASK;
    while encoded_steps[slot] != 0 {
        if keys[slot] == key { return Some((encoded_steps[slot] - 1) as u64); }
        slot = (slot + 1) & TABLE_MASK;
    }
    None
}

fn solve(a: u64, b: u64, modulus: u64) -> i64 {
    if gcd(a, modulus) != 1 { return -1; }
    let m = ceil_sqrt(modulus);
    let mut keys = vec![0u64; TABLE_SIZE];
    let mut encoded_steps = vec![0u32; TABLE_SIZE];
    let mut step = 1u64;
    for index in 0..m {
        insert_baby(&mut keys, &mut encoded_steps, (step * b) % modulus, index as u32);
        step = (step * a) % modulus;
    }
    let giant_step = step;
    let mut index = m;
    while index <= modulus {
        if let Some(baby_index) = find_baby(&keys, &encoded_steps, step) {
            return (index - baby_index) as i64;
        }
        step = (step * giant_step) % modulus;
        index += m;
    }
    -1
}

fn gcd(mut left: u64, mut right: u64) -> u64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

/// Packed input: `[a, b, modulus]`. Return the least positive discrete logarithm, or -1.
#[no_mangle]
pub unsafe extern "C" fn baby_step_giant_step(values: *const i64, length: usize) -> i64 {
    if length != 3 || values.is_null() { return -1; }
    let a = *values;
    let b = *values.add(1);
    let modulus = *values.add(2);
    if a < 0 || b < 0 || modulus < 1 || modulus as u64 > MAX_MODULUS || a >= modulus || b >= modulus {
        return -1;
    }
    solve(a as u64, b as u64, modulus as u64)
}
