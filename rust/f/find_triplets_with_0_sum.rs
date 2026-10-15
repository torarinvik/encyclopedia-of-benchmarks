const MAX_ITEMS: usize = 64;
const BYTES_PER_TRIPLET: usize = 12;

fn write_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        unsafe { output.add(offset + byte).write((bits >> (byte * 8)) as u8); }
    }
}

unsafe fn enumerate(values: &[i64], output: *mut u8, write_output: bool) -> usize {
    let mut count = 0usize;
    let mut last: Option<(i64, i64, i64)> = None;
    for i in 0..values.len() {
        if i + 2 >= values.len() { break; }
        for j in i + 1..values.len() {
            if j + 1 >= values.len() { break; }
            for k in j + 1..values.len() {
                if values[i] + values[j] + values[k] != 0 { continue; }
                let triple = (values[i], values[j], values[k]);
                if last == Some(triple) { continue; }
                if write_output {
                    let offset = count * BYTES_PER_TRIPLET;
                    write_i32_le(output, offset, triple.0);
                    write_i32_le(output, offset + 4, triple.1);
                    write_i32_le(output, offset + 8, triple.2);
                }
                last = Some(triple);
                count += 1;
            }
        }
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn find_triplets_with_0_sum(input: *const i64, length: usize,
                                                   output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_ITEMS || (length > 0 && input.is_null()) { return -1; }
    let mut values = [0i64; MAX_ITEMS];
    for i in 0..length {
        let value = *input.add(i);
        if !(-100_000..=100_000).contains(&value) { return -1; }
        values[i] = value;
    }
    values[..length].sort_unstable();
    let sorted = &values[..length];
    let count = enumerate(sorted, std::ptr::null_mut(), false);
    if count == 0 { return 0; }
    let needed = count * BYTES_PER_TRIPLET;
    if output.is_null() || output_capacity < needed { return -2; }
    enumerate(sorted, output, true) as i64
}
