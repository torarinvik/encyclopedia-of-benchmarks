/// Group cubes by sorted decimal digits and return the first cube in the target group.
const TABLE_SIZE: usize = 16_384;
const MAX_BASE: i64 = 8_384;
const SIGNATURE_LENGTH_FACTOR: i64 = 4_503_599_627_370_496;

fn digit_signature(cube: i64) -> i64 {
    let mut counts = [0i64; 10];
    let mut length = 0i64;
    let mut remaining = cube;
    while remaining > 0 {
        counts[(remaining % 10) as usize] += 1;
        length += 1;
        remaining /= 10;
    }
    if length == 0 {
        counts[0] = 1;
        length = 1;
    }
    let mut sorted_digits = 0i64;
    for (digit, count) in counts.iter().enumerate() {
        for _ in 0..*count {
            sorted_digits = sorted_digits * 16 + digit as i64;
        }
    }
    length * SIGNATURE_LENGTH_FACTOR + sorted_digits
}

fn signature_slot(key: i64) -> usize {
    let size = TABLE_SIZE as i64;
    ((key % size + (key / size % size) * 31 +
      (key / (size * size) % size) * 17 +
      (key / (size * size * size) % size) * 7) % size) as usize
}

#[no_mangle]
pub extern "C" fn problem62(target_count: i64) -> i64 {
    if !(1..=5).contains(&target_count) {
        return -1;
    }
    let mut keys = [0i64; TABLE_SIZE];
    let mut first_cubes = [0i64; TABLE_SIZE];
    let mut counts = [0i64; TABLE_SIZE];
    for base in 0..=MAX_BASE {
        let cube = base * base * base;
        let key = digit_signature(cube);
        let mut slot = signature_slot(key);
        while keys[slot] != 0 && keys[slot] != key {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if keys[slot] == 0 {
            keys[slot] = key;
            first_cubes[slot] = cube;
        }
        counts[slot] += 1;
        if counts[slot] == target_count {
            return first_cubes[slot];
        }
    }
    -1
}
