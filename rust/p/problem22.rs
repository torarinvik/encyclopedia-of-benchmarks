const MAX_NAMES: usize = 6000;
const MAX_NAME_LENGTH: i64 = 19;
const MAX_INPUT_LENGTH: usize = 100001;

fn compare_names(
    input: *const i64,
    offsets: &[usize; MAX_NAMES],
    name_lengths: &[usize; MAX_NAMES],
    first: usize,
    second: usize,
) -> i32 {
    let first_length = name_lengths[first];
    let second_length = name_lengths[second];
    let shared_length = first_length.min(second_length);
    for index in 0..shared_length {
        let first_letter = unsafe { *input.add(offsets[first] + index) };
        let second_letter = unsafe { *input.add(offsets[second] + index) };
        if first_letter < second_letter {
            return -1;
        }
        if first_letter > second_letter {
            return 1;
        }
    }
    if first_length < second_length {
        -1
    } else if first_length > second_length {
        1
    } else {
        0
    }
}

/// Return the sum of alphabetical name scores for packed A=1..Z=26 names.
#[no_mangle]
pub unsafe extern "C" fn problem22(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let raw_count = *input;
    if !(0..=MAX_NAMES as i64).contains(&raw_count) {
        return -1;
    }
    let count = raw_count as usize;
    let mut offsets = [0usize; MAX_NAMES];
    let mut name_lengths = [0usize; MAX_NAMES];
    let mut order = [0usize; MAX_NAMES];
    let mut cursor = 1usize;
    for name in 0..count {
        if cursor >= length {
            return -1;
        }
        let raw_name_length = *input.add(cursor);
        cursor += 1;
        if !(1..=MAX_NAME_LENGTH).contains(&raw_name_length) {
            return -1;
        }
        let name_length = raw_name_length as usize;
        if name_length > length - cursor {
            return -1;
        }
        offsets[name] = cursor;
        name_lengths[name] = name_length;
        for letter in 0..name_length {
            let value = *input.add(cursor + letter);
            if !(1..=26).contains(&value) {
                return -1;
            }
        }
        cursor += name_length;
        order[name] = name;
    }
    if cursor != length {
        return -1;
    }

    for gap in [701usize, 301, 132, 57, 23, 10, 4, 1] {
        if gap >= count {
            continue;
        }
        for index in gap..count {
            let key = order[index];
            let mut position = index;
            while position >= gap
                && compare_names(input, &offsets, &name_lengths, order[position - gap], key) > 0
            {
                order[position] = order[position - gap];
                position -= gap;
            }
            order[position] = key;
        }
    }

    let mut total = 0i64;
    for position in 0..count {
        let name = order[position];
        let mut score = 0i64;
        for letter in 0..name_lengths[name] {
            score += *input.add(offsets[name] + letter);
        }
        total += (position as i64 + 1) * score;
    }
    total
}
