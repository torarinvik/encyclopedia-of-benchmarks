const MAX_LENGTH: usize = 128;
const INSERTION_THRESHOLD: usize = 16;

fn spread_sort_segment(values: &mut [i32]) {
    if values.len() < 2 {
        return;
    }
    if values.len() <= INSERTION_THRESHOLD {
        for index in 1..values.len() {
            let key = values[index];
            let mut position = index;
            while position > 0 && values[position - 1] > key {
                values[position] = values[position - 1];
                position -= 1;
            }
            values[position] = key;
        }
        return;
    }

    let mut minimum = values[0];
    let mut maximum = values[0];
    for &value in &values[1..] {
        minimum = minimum.min(value);
        maximum = maximum.max(value);
    }
    if minimum == maximum {
        return;
    }

    let bucket_count = (values.len() / INSERTION_THRESHOLD).max(2);
    let middle_bucket = bucket_count / 2;
    let mut buckets: Vec<Vec<i32>> = (0..bucket_count)
        .map(|_| Vec::with_capacity(16))
        .collect();
    for &value in values.iter() {
        let bucket = if value == minimum { 0 } else { middle_bucket };
        buckets[bucket].push(value);
    }

    let mut written = 0;
    for mut bucket in buckets {
        if bucket.is_empty() {
            continue;
        }
        spread_sort_segment(&mut bucket);
        let end = written + bucket.len();
        values[written..end].copy_from_slice(&bucket);
        written = end;
    }
}

#[no_mangle]
pub unsafe extern "C" fn spread_sort(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length > MAX_LENGTH {
        return -1;
    }

    let mut values = Vec::with_capacity(length);
    for index in 0..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
        values.push(value as i32);
    }
    if length == 0 {
        return 0;
    }

    let output_bytes = length * 4;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    spread_sort_segment(&mut values);
    for (index, value) in values.iter().enumerate() {
        let bytes = value.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 4), 4);
    }
    output_bytes as i64
}
