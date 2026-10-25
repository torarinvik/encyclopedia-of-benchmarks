const CACHE_SIZE: usize = 512;
const RUN_SIZE: usize = 16;
const MAX_LENGTH: usize = 2048;

fn reverse_range(values: &mut [i64], mut first: usize, mut last: usize) {
    while first < last {
        last -= 1;
        if first >= last {
            break;
        }
        values.swap(first, last);
        first += 1;
    }
}

fn insertion_sort(values: &mut [i64], first: usize, last: usize) {
    for index in first + 1..last {
        let item = values[index];
        let mut position = index;
        while position > first && item < values[position - 1] {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = item;
    }
}

fn rotate_adjacent(
    values: &mut [i64],
    scratch: &mut [i64],
    first: usize,
    middle: usize,
    last: usize,
    cache_size: usize,
) {
    let left_length = middle - first;
    let right_length = last - middle;
    if left_length == 0 || right_length == 0 {
        return;
    }
    if left_length <= right_length && left_length <= cache_size {
        scratch[..left_length].copy_from_slice(&values[first..middle]);
        for index in 0..right_length {
            values[first + index] = values[middle + index];
        }
        values[first + right_length..last].copy_from_slice(&scratch[..left_length]);
        return;
    }
    if right_length < left_length && right_length <= cache_size {
        scratch[..right_length].copy_from_slice(&values[middle..last]);
        for index in (0..left_length).rev() {
            values[first + right_length + index] = values[first + index];
        }
        values[first..first + right_length].copy_from_slice(&scratch[..right_length]);
        return;
    }
    reverse_range(values, first, middle);
    reverse_range(values, middle, last);
    reverse_range(values, first, last);
}

fn merge_from_cache(values: &mut [i64], scratch: &mut [i64], first: usize, middle: usize, last: usize) {
    let left_length = middle - first;
    scratch[..left_length].copy_from_slice(&values[first..middle]);
    let (mut left, mut right, mut output) = (0usize, middle, first);
    while left < left_length && right < last {
        if scratch[left] <= values[right] {
            values[output] = scratch[left];
            left += 1;
        } else {
            values[output] = values[right];
            right += 1;
        }
        output += 1;
    }
    while left < left_length {
        values[output] = scratch[left];
        left += 1;
        output += 1;
    }
}

fn block_rotation_merge(
    values: &mut [i64],
    scratch: &mut [i64],
    first: usize,
    mut middle: usize,
    last: usize,
    cache_size: usize,
) {
    let total = last - first;
    let mut block_size = 1usize;
    while block_size + 1 <= total / (block_size + 1) {
        block_size += 1;
    }
    let mut left = first;
    while left < middle && middle < last {
        if values[left] <= values[middle] {
            let boundary_value = values[middle];
            let (mut low, mut high) = (left, middle);
            while low < high {
                let probe = low + (high - low) / 2;
                if values[probe] <= boundary_value {
                    low = probe + 1;
                } else {
                    high = probe;
                }
            }
            left = low;
        } else {
            let key = values[left];
            let (mut low, mut high) = (middle, last);
            while low < high {
                let probe = low + (high - low) / 2;
                if values[probe] < key {
                    low = probe + 1;
                } else {
                    high = probe;
                }
            }
            let mut block_end = low;
            if block_end - middle > block_size {
                block_end = middle + block_size;
            }
            let moved = block_end - middle;
            if moved == 0 {
                left += 1;
            } else {
                rotate_adjacent(values, scratch, left, middle, block_end, cache_size);
                left += moved;
                middle += moved;
            }
        }
    }
}

#[no_mangle]
pub extern "C" fn wikisort(values: *mut i64, scratch: *mut i64, length: usize) {
    if length < 2 || length > MAX_LENGTH {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length) };
    let cache_size = length.min(CACHE_SIZE);
    if length <= 32 {
        insertion_sort(values, 0, length);
        return;
    }
    for start in (0..length).step_by(RUN_SIZE) {
        insertion_sort(values, start, (start + RUN_SIZE).min(length));
    }
    let mut width = RUN_SIZE;
    while width < length {
        let mut first = 0usize;
        while first < length {
            let middle = (first + width).min(length);
            let last = (middle + width).min(length);
            if middle < last && values[middle] < values[middle - 1] {
                if values[last - 1] < values[first] {
                    rotate_adjacent(values, scratch, first, middle, last, cache_size);
                } else if middle - first <= cache_size {
                    merge_from_cache(values, scratch, first, middle, last);
                } else {
                    block_rotation_merge(values, scratch, first, middle, last, cache_size);
                }
            }
            first = last;
        }
        if width > length / 2 {
            break;
        }
        width *= 2;
    }
}
