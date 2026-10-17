const MAX_STRINGS: usize = 32;
const MAX_STRING_LENGTH: usize = 16;
const MAX_INPUT_WORDS: usize = 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH);
const MAX_PARSEABLE_INPUT_WORDS: usize = MAX_INPUT_WORDS + 1;
const MAX_OUTPUT_BYTES: usize = 4 * MAX_INPUT_WORDS;

#[derive(Clone, Copy, Default)]
struct StringRecord { length: usize, bytes: [u8; MAX_STRING_LENGTH] }

fn char_at(value: &StringRecord, depth: usize) -> i32 {
    if depth < value.length { value.bytes[depth] as i32 } else { 0 }
}
fn median3(a: i32, b: i32, c: i32) -> i32 {
    if a < b { if b < c { b } else if a < c { c } else { a } }
    else if b > c { b } else if a < c { a } else { c }
}
fn compare_from_depth(left: &StringRecord, right: &StringRecord, mut depth: usize) -> i32 {
    while depth < left.length && depth < right.length && left.bytes[depth] == right.bytes[depth] { depth += 1; }
    let a = char_at(left, depth); let b = char_at(right, depth);
    (a > b) as i32 - (a < b) as i32
}
fn insertion_sort(values: &mut [StringRecord], depth: usize) {
    for i in 1..values.len() {
        let value = values[i];
        let mut j = i;
        while j > 0 && compare_from_depth(&values[j - 1], &value, depth) > 0 {
            values[j] = values[j - 1]; j -= 1;
        }
        values[j] = value;
    }
}
fn multikey_sort(values: &mut [StringRecord], depth: usize) {
    let count = values.len();
    if count < 10 { insertion_sort(values, depth); return; }
    let mid = count / 2;
    let pivot = if count > 30 {
        let delta = count / 8;
        median3(median3(char_at(&values[0], depth), char_at(&values[delta], depth), char_at(&values[2 * delta], depth)),
                median3(char_at(&values[mid - delta], depth), char_at(&values[mid], depth), char_at(&values[mid + delta], depth)),
                median3(char_at(&values[count - 1 - 2 * delta], depth), char_at(&values[count - 1 - delta], depth), char_at(&values[count - 1], depth)))
    } else { median3(char_at(&values[0], depth), char_at(&values[mid], depth), char_at(&values[count - 1], depth)) };
    let (mut less, mut scan, mut greater) = (0usize, 0usize, count);
    while scan < greater {
        let key = char_at(&values[scan], depth);
        if key < pivot { values.swap(less, scan); less += 1; scan += 1; }
        else if key > pivot { greater -= 1; values.swap(scan, greater); }
        else { scan += 1; }
    }
    let (low, tail) = values.split_at_mut(less);
    let (equal, high) = tail.split_at_mut(greater - less);
    multikey_sort(low, depth);
    if pivot != 0 { multikey_sort(equal, depth + 1); }
    multikey_sort(high, depth);
}

#[no_mangle]
pub unsafe extern "C" fn multikey_quick_sort(input: *const i32, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_WORDS { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let count = input[0];
    if !(0..=MAX_STRINGS as i32).contains(&count) { return -1; }
    let mut values = [StringRecord::default(); MAX_STRINGS];
    let mut pos = 1usize;
    for i in 0..count as usize {
        if pos >= length || !(0..=MAX_STRING_LENGTH as i32).contains(&input[pos]) { return -1; }
        let string_length = input[pos] as usize; pos += 1;
        if pos + string_length > length { return -1; }
        values[i].length = string_length;
        for j in 0..string_length {
            let byte = input[pos]; pos += 1;
            if !(1..=127).contains(&byte) { return -1; }
            values[i].bytes[j] = byte as u8;
        }
    }
    if pos != length { return -1; }
    let bytes = length * 4;
    if output.is_null() || capacity < bytes { return -2; }
    multikey_sort(&mut values[..count as usize], 0);
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut word = 0usize;
    let put = |buffer: &mut [u8], word: &mut usize, value: i32| {
        buffer[*word * 4..*word * 4 + 4].copy_from_slice(&value.to_le_bytes()); *word += 1;
    };
    put(&mut buffer, &mut word, count);
    for value in values.iter().take(count as usize) {
        put(&mut buffer, &mut word, value.length as i32);
        for byte in value.bytes.iter().take(value.length) { put(&mut buffer, &mut word, *byte as i32); }
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
