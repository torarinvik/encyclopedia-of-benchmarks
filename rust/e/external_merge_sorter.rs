/// Bottom-up merge passes over two bounded buffers, modeling sequential stores.
const MAX_VALUES: usize = 4096;

fn merge_pass(source: &[i64; MAX_VALUES], destination: &mut [i64; MAX_VALUES],
              length: usize, width: usize) {
    let mut start = 0;
    while start < length {
        let middle = (start + width).min(length);
        let end = (middle + width).min(length);
        let (mut left, mut right, mut output) = (start, middle, start);
        while left < middle && right < end {
            if source[left] < source[right] {
                destination[output] = source[left];
                left += 1;
            } else {
                destination[output] = source[right];
                right += 1;
            }
            output += 1;
        }
        while left < middle { destination[output] = source[left]; left += 1; output += 1; }
        while right < end { destination[output] = source[right]; right += 1; output += 1; }
        start += width * 2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn external_merge_sorter(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_VALUES || (length != 0 && values.is_null()) { return -1; }
    let output_bytes = length * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let mut primary = [0_i64; MAX_VALUES];
    let mut temporary = [0_i64; MAX_VALUES];
    if length != 0 {
        primary[..length].copy_from_slice(std::slice::from_raw_parts(values, length));
    }
    let mut primary_is_source = true;
    let mut width = 1;
    while width < length {
        if primary_is_source {
            merge_pass(&primary, &mut temporary, length, width);
        } else {
            merge_pass(&temporary, &mut primary, length, width);
        }
        primary_is_source = !primary_is_source;
        if width > length / 2 { break; }
        width *= 2;
    }
    for index in 0..length {
        let value = if primary_is_source { primary[index] } else { temporary[index] };
        let bits = value as u64;
        for byte in 0..8 {
            *output.add(index * 8 + byte) = (bits >> (byte * 8)) as u8;
        }
    }
    output_bytes as i64
}
