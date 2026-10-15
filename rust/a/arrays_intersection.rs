/// Count three-array occurrences and emit keys with total count exactly three.
const ARRAY_COUNT: usize = 3;
const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1);
const MAX_OCCURRENCES: usize = ARRAY_COUNT * MAX_ARRAY_LENGTH;
const TABLE_SIZE: usize = 257;

fn add_occurrence(
    value: i64,
    keys: &mut [i64; TABLE_SIZE],
    counts: &mut [usize; TABLE_SIZE],
    occupied: &mut [bool; TABLE_SIZE],
    order: &mut [usize; MAX_OCCURRENCES],
    order_length: &mut usize,
) {
    let mut slot = value.rem_euclid(TABLE_SIZE as i64) as usize;
    while occupied[slot] && keys[slot] != value {
        slot = (slot + 1) % TABLE_SIZE;
    }
    if !occupied[slot] {
        occupied[slot] = true;
        keys[slot] = value;
        counts[slot] = 0;
        order[*order_length] = slot;
        *order_length += 1;
    }
    counts[slot] += 1;
}

fn store_i32_le(output: *mut u8, position: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        unsafe { *output.add(position + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn arrays_intersection(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < ARRAY_COUNT || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let mut starts = [0usize; ARRAY_COUNT];
    let mut sizes = [0usize; ARRAY_COUNT];
    let mut position = 0usize;
    for array in 0..ARRAY_COUNT {
        if position >= length || input[position] < 0 || input[position] > MAX_ARRAY_LENGTH as i64 {
            return -1;
        }
        let size = input[position] as usize;
        position += 1;
        if size > length - position {
            return -1;
        }
        starts[array] = position;
        sizes[array] = size;
        if input[position..position + size]
            .iter()
            .any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64)
        {
            return -1;
        }
        position += size;
    }
    if position != length {
        return -1;
    }

    let mut keys = [0i64; TABLE_SIZE];
    let mut counts = [0usize; TABLE_SIZE];
    let mut occupied = [false; TABLE_SIZE];
    let mut order = [0usize; MAX_OCCURRENCES];
    let mut order_length = 0usize;
    for array in 0..ARRAY_COUNT {
        for index in 0..sizes[array] {
            add_occurrence(
                input[starts[array] + index],
                &mut keys,
                &mut counts,
                &mut occupied,
                &mut order,
                &mut order_length,
            );
        }
    }

    let match_count = order[..order_length]
        .iter()
        .filter(|&&slot| counts[slot] == ARRAY_COUNT)
        .count();
    let required = match_count * 4;
    if output_capacity < required || (match_count > 0 && output.is_null()) {
        return -2;
    }
    let mut written = 0usize;
    for &slot in &order[..order_length] {
        if counts[slot] == ARRAY_COUNT {
            store_i32_le(output, written * 4, keys[slot]);
            written += 1;
        }
    }
    written as i64
}
