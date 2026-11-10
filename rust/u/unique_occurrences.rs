/// Check whether every present value has a distinct occurrence count.
#[no_mangle]
pub extern "C" fn unique_occurrences(values: *const i64, length: usize) -> i64 {
    if length == 0 { return 1; }
    if length > 1000 || values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let first = values[0] as u64;
    if length == 1 { return if first.wrapping_add(1000) <= 2000 { 1 } else { -1 }; }
    let (mut largest_biased, mut different_bits) = (0u64, 0u64);
    for &value in values {
        let value = value as u64;
        different_bits |= value ^ first;
        largest_biased = largest_biased.max(value.wrapping_add(1000));
    }
    if largest_biased > 2000 { return -1; }
    if different_bits == 0 { return 1; }

    let mut counts = [0u16; 2001];
    let mut touched = [0u16; 44];
    let mut distinct = 0;
    for &value in values {
        let slot = (value + 1000) as usize;
        if counts[slot] == 0 {
            let next_distinct = distinct + 1;
            if next_distinct * (next_distinct + 1) > 2 * length { return 0; }
            touched[distinct] = slot as u16;
            distinct = next_distinct;
        }
        counts[slot] += 1;
    }
    let mut seen = [0u64; 16];
    for &slot in &touched[..distinct] {
        let frequency = usize::from(counts[usize::from(slot)]);
        let word = frequency >> 6;
        let bit = 1u64 << (frequency & 63);
        if seen[word] & bit != 0 { return 0; }
        seen[word] |= bit;
    }
    1
}
