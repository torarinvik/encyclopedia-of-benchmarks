//! Pointer-relinking selection sort modeled with bounded node indices.

const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn selection_sort_links(values: &[i32; MAX_COUNT], next: &mut [i32; MAX_COUNT], head: &mut i32) {
    let mut minimum = *head;
    let mut current = next[minimum as usize];
    let mut previous = minimum;
    let mut sorted_tail = -1i32;
    while next[minimum as usize] != -1 {
        while current != -1 {
            if values[current as usize] < values[minimum as usize] {
                if sorted_tail == -1 {
                    if previous == minimum {
                        *head = current;
                        next[minimum as usize] = next[current as usize];
                        next[current as usize] = previous;
                        minimum = current;
                        current = next[previous as usize];
                    } else {
                        *head = current;
                        next[previous as usize] = next[current as usize];
                        next[current as usize] = minimum;
                        minimum = current;
                        current = next[previous as usize];
                    }
                } else {
                    next[sorted_tail as usize] = current;
                    next[previous as usize] = next[current as usize];
                    next[current as usize] = minimum;
                    minimum = current;
                    current = next[previous as usize];
                }
            } else {
                previous = next[previous as usize];
                current = next[current as usize];
            }
        }
        sorted_tail = minimum;
        minimum = next[minimum as usize];
        previous = minimum;
        current = next[minimum as usize];
    }
}

unsafe fn write_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn selectionsortlinkedlist(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values_input = std::slice::from_raw_parts(input, length);
    let raw_count = values_input[0];
    if raw_count < 1 || raw_count > MAX_COUNT as i64 || length != 1 + raw_count as usize {
        return -1;
    }
    let count = raw_count as usize;
    let mut values = [0i32; MAX_COUNT];
    let mut next = [-1i32; MAX_COUNT];
    for index in 0..count {
        let value = values_input[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return -1;
        }
        values[index] = value as i32;
        next[index] = if index + 1 < count { (index + 1) as i32 } else { -1 };
    }
    let byte_count = 4 * count;
    if output.is_null() || output_capacity < byte_count {
        return -2;
    }

    let mut head = 0i32;
    selection_sort_links(&values, &mut next, &mut head);
    let mut node = head;
    for index in 0..count {
        write_i32_le(output, 4 * index, values[node as usize]);
        node = next[node as usize];
    }
    byte_count as i64
}
