/// 64-ary hierarchical bitmap predecessor set.
fn wary_low_bit(bits: u64) -> usize {
    let (mut low, mut high) = (0usize, 64usize);
    while high - low > 1 {
        let middle = (low + high) / 2;
        let mask = (1u64 << middle) - 1;
        if bits & mask != 0 { high = middle; } else { low = middle; }
    }
    low
}

fn wary_high_bit(bits: u64) -> usize {
    let (mut low, mut high) = (0usize, 64usize);
    while high - low > 1 {
        let middle = (low + high) / 2;
        if bits >> middle != 0 { low = middle; } else { high = middle; }
    }
    low
}

fn wary_insert(leaf: &mut [u64; 4096], group: &mut [u64; 64], top: &mut u64, key: usize) -> i64 {
    let word = key >> 6;
    let bit_index = key & 63;
    let bit = 1u64 << bit_index;
    let old = leaf[word];
    if old & bit != 0 { return 0; }
    if old == 0 {
        let group_index = word >> 6;
        let slot = word & 63;
        if group[group_index] == 0 { *top |= 1u64 << group_index; }
        group[group_index] |= 1u64 << slot;
    }
    leaf[word] = old | bit;
    1
}

fn wary_erase(leaf: &mut [u64; 4096], group: &mut [u64; 64], top: &mut u64, key: usize) -> i64 {
    let word = key >> 6;
    let bit_index = key & 63;
    let bit = 1u64 << bit_index;
    let old = leaf[word];
    if old & bit == 0 { return 0; }
    leaf[word] = old & !bit;
    if leaf[word] == 0 {
        let group_index = word >> 6;
        let slot = word & 63;
        group[group_index] &= !(1u64 << slot);
        if group[group_index] == 0 { *top &= !(1u64 << group_index); }
    }
    1
}

fn wary_successor(leaf: &[u64; 4096], group: &[u64; 64], top: u64, key: usize) -> i64 {
    let word = key >> 6;
    let bit_index = key & 63;
    let candidates = leaf[word] >> bit_index;
    if candidates != 0 { return (word * 64 + bit_index + wary_low_bit(candidates) + 1) as i64; }
    let group_index = word >> 6;
    let slot = word & 63;
    let mut later = if slot < 63 { group[group_index] >> (slot + 1) } else { 0 };
    let next_word;
    if later != 0 {
        next_word = group_index * 64 + slot + 1 + wary_low_bit(later);
    } else {
        later = if group_index < 63 { top >> (group_index + 1) } else { 0 };
        if later == 0 { return 0; }
        let next_group = group_index + 1 + wary_low_bit(later);
        next_word = next_group * 64 + wary_low_bit(group[next_group]);
    }
    (next_word * 64 + wary_low_bit(leaf[next_word]) + 1) as i64
}

fn wary_predecessor(leaf: &[u64; 4096], group: &[u64; 64], top: u64, key: usize) -> i64 {
    let word = key >> 6;
    let bit_index = key & 63;
    let candidates = leaf[word] & ((1u64 << bit_index) - 1);
    if candidates != 0 { return (word * 64 + wary_high_bit(candidates) + 1) as i64; }
    let group_index = word >> 6;
    let slot = word & 63;
    let mut earlier = group[group_index] & ((1u64 << slot) - 1);
    let previous_word;
    if earlier != 0 {
        previous_word = group_index * 64 + wary_high_bit(earlier);
    } else {
        earlier = top & ((1u64 << group_index) - 1);
        if earlier == 0 { return 0; }
        let previous_group = wary_high_bit(earlier);
        previous_word = previous_group * 64 + wary_high_bit(group[previous_group]);
    }
    (previous_word * 64 + wary_high_bit(leaf[previous_word]) + 1) as i64
}

#[no_mangle]
pub unsafe extern "C" fn w_ary_predecessor_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=66).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=32).contains(&input[0]) { return -1; }
    let q = input[0] as usize;
    if length != 1 + 2 * q { return -1; }
    let mut leaf = [0u64; 4096];
    let mut group = [0u64; 64];
    let mut top = 0u64;
    let mut result = 0i64;
    let mut cursor = 1usize;
    for operation in 0..q {
        let opcode = input[cursor];
        let raw_key = input[cursor + 1];
        cursor += 2;
        if !(0..=4).contains(&opcode) || !(0..262144).contains(&raw_key) { return -1; }
        let key = raw_key as usize;
        let answer = match opcode {
            0 => wary_insert(&mut leaf, &mut group, &mut top, key),
            1 => wary_erase(&mut leaf, &mut group, &mut top, key),
            2 => if leaf[key >> 6] & (1u64 << (key & 63)) != 0 { 1 } else { 0 },
            3 => wary_successor(&leaf, &group, top, key),
            _ => wary_predecessor(&leaf, &group, top, key),
        };
        result += (operation as i64 + 1) * answer;
    }
    result
}
