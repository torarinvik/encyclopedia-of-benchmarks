const MAX_STRINGS: usize = 256;
const MAX_STRING_LENGTH: usize = 32;
const MAX_PARSEABLE: usize = 8450;
const BUCKET_COUNT: usize = 257;

fn symbol_at(
    strings: &[[u8; MAX_STRING_LENGTH]; MAX_STRINGS],
    lengths: &[usize; MAX_STRINGS],
    record: usize,
    depth: usize,
) -> usize {
    if depth == lengths[record] { 0 } else { strings[record][depth] as usize + 1 }
}

fn american_flag_sort(
    strings: &[[u8; MAX_STRING_LENGTH]; MAX_STRINGS],
    lengths: &[usize; MAX_STRINGS],
    order: &mut [usize; MAX_STRINGS],
    lo: usize,
    hi: usize,
    depth: usize,
) {
    if hi - lo < 2 { return; }

    let mut counts = [0_usize; BUCKET_COUNT];
    for position in lo..hi {
        counts[symbol_at(strings, lengths, order[position], depth)] += 1;
    }

    let mut starts = [0_usize; BUCKET_COUNT + 1];
    let mut next = [0_usize; BUCKET_COUNT];
    starts[0] = lo;
    for bucket in 0..BUCKET_COUNT {
        starts[bucket + 1] = starts[bucket] + counts[bucket];
        next[bucket] = starts[bucket];
    }

    for bucket in 0..BUCKET_COUNT {
        while next[bucket] < starts[bucket + 1] {
            let position = next[bucket];
            let destination_bucket = symbol_at(strings, lengths, order[position], depth);
            if destination_bucket == bucket {
                next[bucket] += 1;
            } else {
                order.swap(position, next[destination_bucket]);
                next[destination_bucket] += 1;
            }
        }
    }

    for bucket in 1..BUCKET_COUNT {
        if counts[bucket] > 1 {
            american_flag_sort(strings, lengths, order, starts[bucket], starts[bucket + 1], depth + 1);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn american_flag_string_sorter(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE { return -1; }
    let string_count_value = *input;
    if !(0..=MAX_STRINGS as i64).contains(&string_count_value) { return -1; }
    let string_count = string_count_value as usize;

    let mut strings = [[0_u8; MAX_STRING_LENGTH]; MAX_STRINGS];
    let mut string_lengths = [0_usize; MAX_STRINGS];
    let mut position = 1_usize;
    for record in 0..string_count {
        if position >= length { return -1; }
        let string_length_value = *input.add(position);
        position += 1;
        if !(0..=MAX_STRING_LENGTH as i64).contains(&string_length_value) { return -1; }
        let string_length = string_length_value as usize;
        if string_length > length - position { return -1; }
        string_lengths[record] = string_length;
        for byte_index in 0..string_length {
            let byte = *input.add(position);
            position += 1;
            if !(0..=255).contains(&byte) { return -1; }
            strings[record][byte_index] = byte as u8;
        }
    }
    if position != length { return -1; }

    let mut order = [0_usize; MAX_STRINGS];
    for index in 0..string_count { order[index] = index; }
    american_flag_sort(&strings, &string_lengths, &mut order, 0, string_count, 0);

    let mut checksum = 0_i64;
    for rank in 0..string_count {
        let record = order[rank];
        let mut contribution = string_lengths[record] as i64 + 1;
        for byte_index in 0..string_lengths[record] {
            contribution += strings[record][byte_index] as i64 + 1;
        }
        checksum += (rank as i64 + 1) * contribution;
    }
    checksum
}
