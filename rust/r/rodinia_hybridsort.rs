/// Rodinia hybrid histogram bucket partition followed by per-bucket merge sort.
fn bucket(value: f32, minimum: f32, span: f32) -> usize {
    let mut index = (((value - minimum) / span) * 1024.0f32) as i32;
    if index < 0 { index = 0; }
    if index >= 1024 { index = 1023; }
    index as usize
}
fn merge_sort(items: &mut [i64], scratch: &mut [i64]) {
    let count = items.len(); let mut width = 1;
    while width < count {
        let mut left = 0;
        while left < count {
            let middle = (left + width).min(count); let right = (left + 2 * width).min(count);
            let (mut a, mut b, mut out) = (left, middle, left);
            while a < middle && b < right {
                if items[a] <= items[b] { scratch[out] = items[a]; a += 1; }
                else { scratch[out] = items[b]; b += 1; }
                out += 1;
            }
            while a < middle { scratch[out] = items[a]; a += 1; out += 1; }
            while b < right { scratch[out] = items[b]; b += 1; out += 1; }
            left += 2 * width;
        }
        items.copy_from_slice(&scratch[..count]); width *= 2;
    }
}

#[no_mangle]
pub extern "C" fn rodinia_hybridsort(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 65 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if v[0] < 2 || v[0] > 64 || length != 1 + v[0] as usize { return -1; }
    let count = v[0] as usize; let mut values = [0i64; 64];
    let mut minimum = i64::MAX; let mut maximum = i64::MIN;
    for i in 0..count {
        let x = v[1 + i]; if x < 0 || x > 1_000_000 || x % 1000 != 0 { return -1; }
        values[i] = x; minimum = minimum.min(x); maximum = maximum.max(x);
    }
    if minimum == maximum { return -1; }
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let min_f = minimum as f32 / 1_000_000.0f32; let max_f = maximum as f32 / 1_000_000.0f32;
    let span = max_f - min_f;
    let mut histogram = [0usize; 1024]; let mut offsets = [0usize; 1025]; let mut next = [0usize; 1024];
    for &x in &values[..count] { histogram[bucket(x as f32 / 1_000_000.0f32, min_f, span)] += 1; }
    for b in 0..1024 { offsets[b + 1] = offsets[b] + histogram[b]; next[b] = offsets[b]; }
    let mut scattered = [0i64; 64]; let mut scratch = [0i64; 64];
    for &x in &values[..count] { let b = bucket(x as f32 / 1_000_000.0f32, min_f, span); scattered[next[b]] = x; next[b] += 1; }
    for b in 0..1024 { let start = offsets[b]; let end = offsets[b + 1]; if start < end { merge_sort(&mut scattered[start..end], &mut scratch[..end-start]); } }
    for i in 0..count { let bits = scattered[i].to_le_bytes(); unsafe { std::ptr::copy_nonoverlapping(bits.as_ptr(), output.add(i * 8), 8); } }
    bytes as i64
}
