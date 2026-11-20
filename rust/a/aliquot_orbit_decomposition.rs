const MAX_TERMS: usize = 4097;
const MAX_INPUT: usize = 3;
const MAX_SEED: i64 = 100_000;
const MAX_VALUE: i64 = 100_000;
const MAX_TRANSITIONS: i64 = 4_096;

fn aliquot_sum(value: i64) -> i64 {
    if value == 1 { return 0; }
    let mut sum = 1_i64;
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        if value % divisor == 0 {
            sum += divisor;
            let partner = value / divisor;
            if partner != divisor { sum += partner; }
        }
        divisor += 1;
    }
    sum
}

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn decompose(seed: i64, max_transitions: i64) -> [i64; 3] {
    let mut keys = [0_i64; MAX_TERMS];
    let mut first_indices = [0_i64; MAX_TERMS];
    let mut key_count = 0_usize;
    let mut words = [0_i64; 3];
    let mut current = seed;
    let mut transitions = 0_i64;
    let mut positive_term_count = 0_i64;
    loop {
        if current == 0 {
            words = [0, positive_term_count, 0];
            break;
        }
        let mut low = 0_usize;
        let mut high = key_count;
        while low < high {
            let middle = low + (high - low) / 2;
            if keys[middle] < current { low = middle + 1; }
            else { high = middle; }
        }
        if low < key_count && keys[low] == current {
            words = [1, first_indices[low], transitions - first_indices[low]];
            break;
        }
        for index in (low..key_count).rev() {
            keys[index + 1] = keys[index];
            first_indices[index + 1] = first_indices[index];
        }
        keys[low] = current;
        first_indices[low] = transitions;
        key_count += 1;
        positive_term_count += 1;
        if transitions >= max_transitions {
            words = [-3, transitions, current];
            break;
        }
        let next_value = aliquot_sum(current);
        transitions += 1;
        if next_value > MAX_VALUE {
            words = [-2, transitions, next_value];
            break;
        }
        current = next_value;
    }
    words
}

#[no_mangle]
pub unsafe extern "C" fn aliquot_orbit_decomposition(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 2 || !(1..=MAX_SEED).contains(&values[0]) ||
        !(1..=MAX_TRANSITIONS).contains(&values[1]) { return -1; }
    if output.is_null() || capacity < 24 { return -2; }
    let words = decompose(values[0], values[1]);
    let bytes = std::slice::from_raw_parts_mut(output, 24);
    for (index, word) in words.into_iter().enumerate() {
        store_i64(bytes, index * 8, word);
    }
    24
}
