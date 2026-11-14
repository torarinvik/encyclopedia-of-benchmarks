use std::slice;

#[no_mangle]
pub unsafe extern "C" fn sticky_sampling_summary(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=323).contains(&length) { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    if !(1..=8).contains(&values[0]) || !(0..=64).contains(&values[1])
        || !(0..=256).contains(&values[2]) { return -1; }
    let (t, n, k) = (values[0] as usize, values[1] as usize, values[2] as usize);
    if length != 3+n+k || values[3..3+n].iter().any(|&x| !(0..=15).contains(&x))
        || values[3+n..].iter().any(|&x| !(0..=255).contains(&x)) { return -1; }
    let mut counts = [0i64; 16];
    let (mut cursor, mut rate, mut end) = (0usize, 1usize, 2*t);
    let tape = &values[3+n..];
    for (i, &value) in values[3..3+n].iter().enumerate() {
        if i == end {
            rate *= 2;
            end += rate*t;
            for count in &mut counts {
                while *count != 0 {
                    if cursor == k { return -1; }
                    let draw = tape[cursor];
                    cursor += 1;
                    if draw & 1 != 0 { break; }
                    *count -= 1;
                }
            }
        }
        let item = value as usize;
        if counts[item] != 0 { counts[item] += 1; }
        else {
            if cursor == k { return -1; }
            let draw = tape[cursor] as usize;
            cursor += 1;
            if draw % rate == 0 { counts[item] = 1; }
        }
    }
    if cursor != k { return -1; }
    let active = counts.iter().filter(|&&count| count != 0).count();
    let bytes = 8+16*active;
    if output.is_null() || capacity < bytes { return -2; }
    let out = unsafe { slice::from_raw_parts_mut(output, bytes) };
    out[..8].copy_from_slice(&(active as i64).to_le_bytes());
    let mut offset = 8;
    for (item, &count) in counts.iter().enumerate() {
        if count != 0 {
            out[offset..offset+8].copy_from_slice(&(item as i64).to_le_bytes());
            out[offset+8..offset+16].copy_from_slice(&count.to_le_bytes());
            offset += 16;
        }
    }
    bytes as i64
}
