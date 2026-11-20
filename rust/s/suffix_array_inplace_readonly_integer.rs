use core::slice;

const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const PACKED_FIELD_WORDS: usize = 4;
const PACKED_LIST_WORDS: usize = 2;

#[derive(Clone, Copy)]
enum Input<'a> {
    Raw(&'a [i64]),
    Packed(&'a [u64; PACKED_LIST_WORDS]),
}

#[derive(Clone, Copy)]
struct PackedFields([u64; PACKED_FIELD_WORDS]);

impl PackedFields {
    fn zeroed() -> Self { Self([0; PACKED_FIELD_WORDS]) }

    fn get(&self, index: usize) -> i32 {
        let value = ((self.0[index / 9] >> ((index % 9) * 7)) & 127) as i32;
        if value == 127 { -1 } else { value }
    }

    fn set(&mut self, index: usize, value: i32) {
        let shift = (index % 9) * 7;
        let mask = 127u64 << shift;
        let encoded = if value < 0 { 127u64 } else { value as u64 };
        self.0[index / 9] = (self.0[index / 9] & !mask) | (encoded << shift);
    }
}

fn list_get(list: &[u64; PACKED_LIST_WORDS], index: usize) -> usize {
    ((list[index / 10] >> ((index % 10) * 6)) & 63) as usize
}

fn list_set(list: &mut [u64; PACKED_LIST_WORDS], index: usize, value: usize) {
    let shift = (index % 10) * 6;
    let mask = 63u64 << shift;
    list[index / 10] = (list[index / 10] & !mask) | ((value as u64) << shift);
}

fn bit_is_set(bits: u64, index: usize) -> bool { ((bits >> index) & 1) != 0 }

fn bits_below(bits: u64, index: usize) -> usize {
    let mask = if index == 0 { 0 } else { (1u64 << index) - 1 };
    (bits & mask).count_ones() as usize
}

fn symbol_at(input: Input<'_>, index: usize) -> i32 {
    match input {
        Input::Raw(raw) => if index == raw.len() { 0 } else { raw[index] as i32 + 1 },
        Input::Packed(packed) => list_get(packed, index) as i32,
    }
}

fn sa_get(output: &[u8], index: usize) -> i64 {
    let offset = index * 8;
    let mut bytes = [0u8; 8];
    bytes.copy_from_slice(&output[offset..offset + 8]);
    let value = i64::from_le_bytes(bytes);
    if value < 0 { -1 } else { value }
}

fn sa_set(output: &mut [u8], index: usize, value: i64) {
    let offset = index * 8;
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn build_buckets(input: Input<'_>, length: usize, upper: usize,
                 types: u64, heads: &mut PackedFields, tails: &mut PackedFields,
                 s_starts: &mut PackedFields) {
    let mut counts = PackedFields::zeroed();
    let mut l_counts = PackedFields::zeroed();
    let mut prefix = 0i32;
    for index in 0..length {
        let symbol = symbol_at(input, index) as usize;
        counts.set(symbol, counts.get(symbol) + 1);
        if !bit_is_set(types, index) { l_counts.set(symbol, l_counts.get(symbol) + 1); }
    }
    for symbol in 0..=upper {
        let count = counts.get(symbol);
        heads.set(symbol, prefix);
        tails.set(symbol, prefix + count - 1);
        s_starts.set(symbol, prefix + l_counts.get(symbol));
        prefix += count;
    }
}

fn same_lms_substring(input: Input<'_>, length: usize, types: u64, lms: u64,
                      left: usize, right: usize) -> bool {
    if left == right { return true; }
    for offset in 0..length {
        let a = left + offset;
        let b = right + offset;
        if a >= length || b >= length || symbol_at(input, a) != symbol_at(input, b)
            || bit_is_set(types, a) != bit_is_set(types, b) { return false; }
        if offset > 0 && (bit_is_set(lms, a) || bit_is_set(lms, b)) {
            return bit_is_set(lms, a) && bit_is_set(lms, b);
        }
    }
    false
}

fn induce(input: Input<'_>, length: usize, upper: usize, types: u64, lms: u64,
          seeds: &[u64; PACKED_LIST_WORDS], seed_count: usize,
          use_lms_mask: bool, output: &mut [u8]) {
    let mut heads = PackedFields::zeroed();
    let mut tails = PackedFields::zeroed();
    let mut s_starts = PackedFields::zeroed();
    let mut l_cursor = PackedFields::zeroed();
    let mut s_cursor = PackedFields::zeroed();
    build_buckets(input, length, upper, types, &mut heads, &mut tails, &mut s_starts);
    for index in 0..length { sa_set(output, index, -1); }
    for symbol in 0..=upper { s_cursor.set(symbol, s_starts.get(symbol)); }
    if use_lms_mask {
        for position in 0..length {
            if !bit_is_set(lms, position) { continue; }
            let symbol = symbol_at(input, position) as usize;
            let slot = s_cursor.get(symbol);
            sa_set(output, slot as usize, position as i64);
            s_cursor.set(symbol, slot + 1);
        }
    } else {
        for item in 0..seed_count {
            let position = list_get(seeds, item);
            let symbol = symbol_at(input, position) as usize;
            let slot = s_cursor.get(symbol);
            sa_set(output, slot as usize, position as i64);
            s_cursor.set(symbol, slot + 1);
        }
    }
    for symbol in 0..=upper {
        l_cursor.set(symbol, heads.get(symbol));
        s_cursor.set(symbol, tails.get(symbol) + 1);
    }
    for slot in 0..length {
        let position = sa_get(output, slot);
        if position <= 0 { continue; }
        let previous = (position - 1) as usize;
        if bit_is_set(types, previous) { continue; }
        let symbol = symbol_at(input, previous) as usize;
        let target = l_cursor.get(symbol);
        sa_set(output, target as usize, previous as i64);
        l_cursor.set(symbol, target + 1);
    }
    for slot in (0..length).rev() {
        let position = sa_get(output, slot);
        if position <= 0 { continue; }
        let previous = (position - 1) as usize;
        if !bit_is_set(types, previous) { continue; }
        let symbol = symbol_at(input, previous) as usize;
        let target = s_cursor.get(symbol) - 1;
        sa_set(output, target as usize, previous as i64);
        s_cursor.set(symbol, target);
    }
}

fn sais_readonly(input: Input<'_>, length: usize, upper: usize, output: &mut [u8]) {
    if length == 0 { return; }
    if length == 1 { sa_set(output, 0, 0); return; }
    if length == 2 {
        if symbol_at(input, 0) >= symbol_at(input, 1) {
            sa_set(output, 0, 1); sa_set(output, 1, 0);
        } else { sa_set(output, 0, 0); sa_set(output, 1, 1); }
        return;
    }

    let mut types = 1u64 << (length - 1);
    for index in (0..length - 1).rev() {
        let current = symbol_at(input, index);
        let next = symbol_at(input, index + 1);
        if current < next || (current == next && bit_is_set(types, index + 1)) {
            types |= 1u64 << index;
        }
    }
    let mut lms = 0u64;
    let mut lms_positions = [0u64; PACKED_LIST_WORDS];
    let mut lms_count = 0usize;
    for index in 1..length {
        if !bit_is_set(types, index - 1) && bit_is_set(types, index) {
            lms |= 1u64 << index;
            list_set(&mut lms_positions, lms_count, index);
            lms_count += 1;
        }
    }

    let empty_seeds = [0u64; PACKED_LIST_WORDS];
    induce(input, length, upper, types, lms, &empty_seeds, 0, true, output);
    let mut reduced = [0u64; PACKED_LIST_WORDS];
    let mut name = 0usize;
    let mut sorted_count = 0usize;
    let mut previous_lms: Option<usize> = None;
    for slot in 0..length {
        let candidate = sa_get(output, slot);
        if candidate < 0 || !bit_is_set(lms, candidate as usize) { continue; }
        let position = candidate as usize;
        if let Some(previous) = previous_lms {
            if !same_lms_substring(input, length, types, lms, previous, position) { name += 1; }
        }
        list_set(&mut reduced, bits_below(lms, position), name);
        previous_lms = Some(position);
        sorted_count += 1;
    }
    if sorted_count != lms_count { return; }
    if name + 1 == lms_count {
        for ordinal in 0..lms_count {
            sa_set(output, list_get(&reduced, ordinal), ordinal as i64);
        }
    } else {
        sais_readonly(Input::Packed(&reduced), lms_count, name, output);
    }
    let mut ordered_lms = [0u64; PACKED_LIST_WORDS];
    for item in 0..lms_count {
        let ordinal = sa_get(output, item) as usize;
        list_set(&mut ordered_lms, item, list_get(&lms_positions, ordinal));
    }
    induce(input, length, upper, types, lms, &ordered_lms, lms_count, false, output);
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array_inplace_readonly_integer(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let frame = slice::from_raw_parts(values, length);
    let count_value = frame[0];
    if count_value < 0 || count_value > MAX_TEXT_LENGTH as i64 { return -1; }
    let count = count_value as usize;
    if length != count + 1 || frame[1..].iter().any(|&value| value < 0 || value >= count as i64) {
        return -1;
    }
    let workspace_bytes = (count + 1) * 8;
    let output_bytes = count * 8;
    if output.is_null() || capacity < workspace_bytes { return -2; }
    let output_slice = slice::from_raw_parts_mut(output, workspace_bytes);
    sais_readonly(Input::Raw(&frame[1..]), count + 1, count, output_slice);
    for index in 0..count {
        let position = sa_get(output_slice, index + 1);
        sa_set(output_slice, index, position);
    }
    output_bytes as i64
}
