const MAX_STRINGS: usize = 256;
const MAX_LENGTH: usize = 32;
const MAX_INPUT: usize = 1 + MAX_STRINGS * (1 + MAX_LENGTH) + 1;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

#[derive(Clone, Copy)]
struct EncodedString { bytes: [u8; MAX_LENGTH], length: usize }

fn bucket(value: &EncodedString, digit: usize) -> usize {
    if digit >= value.length { 0 } else { usize::from(value.bytes[digit]) + 1 }
}

fn msd_sort(values: &mut [EncodedString; MAX_STRINGS], auxiliary: &mut [EncodedString; MAX_STRINGS],
            low: usize, high: usize, digit: usize) {
    if high - low < 2 || digit >= MAX_LENGTH { return; }
    let mut counts = [0usize; 257];
    for i in low..high { counts[bucket(&values[i], digit)] += 1; }
    let mut starts = [0usize; 257];
    let mut next = [0usize; 257];
    let mut position = low;
    for b in 0..257 { starts[b] = position; next[b] = position; position += counts[b]; }
    for i in low..high { let b = bucket(&values[i], digit); auxiliary[next[b]] = values[i]; next[b] += 1; }
    for i in low..high { values[i] = auxiliary[i]; }
    for b in 1..257 {
        let first = starts[b]; let last = first + counts[b];
        if last - first > 1 { msd_sort(values, auxiliary, first, last, digit + 1); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn msd_radix_string_sorter(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_STRINGS as i64).contains(&input[0]) { return -1; }
    let count = input[0] as usize;
    let empty = EncodedString { bytes: [0; MAX_LENGTH], length: 0 };
    let mut values = [empty; MAX_STRINGS];
    let mut auxiliary = [empty; MAX_STRINGS];
    let mut position = 1;
    for value in values.iter_mut().take(count) {
        if position >= length || !(0..=MAX_LENGTH as i64).contains(&input[position]) { return -1; }
        let n = input[position] as usize; position += 1;
        if n > length - position { return -1; }
        value.length = n;
        for digit in 0..n {
            if !(0..=255).contains(&input[position]) { return -1; }
            value.bytes[digit] = input[position] as u8; position += 1;
        }
    }
    if position != length { return -1; }
    if count > 1 { msd_sort(&mut values, &mut auxiliary, 0, count, 0); }
    let mut hash = FNV_OFFSET;
    for byte in (count as u16).to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    for value in values.iter().take(count) {
        hash = (hash ^ value.length as u64).wrapping_mul(FNV_PRIME);
        for &byte in &value.bytes[..value.length] { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    }
    (hash & i64::MAX as u64) as i64
}
