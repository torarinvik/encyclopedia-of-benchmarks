const MAX_LISTS: usize = 4;
const MAX_INITIAL_LENGTH: usize = 4;
const MAX_ITERATIONS: usize = 16;
const MAX_NODES: usize = 36;

fn store_le_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn llubenchmark_list_traversal_growth(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_LISTS as i64 ||
       values[1] < 1 || values[1] > MAX_INITIAL_LENGTH as i64 ||
       values[2] < 0 || values[2] > MAX_ITERATIONS as i64 { return -1; }
    if output.is_null() || output_capacity < 16 { return -2; }
    let list_count = values[0] as usize;
    let initial_length = values[1] as usize;
    let iterations = values[2] as usize;

    let mut next = [-1i64; MAX_NODES];
    let mut count = [0i64; MAX_NODES];
    let mut head = [-1i64; MAX_LISTS];
    let mut tail = [-1i64; MAX_LISTS];
    let mut allocated = 0usize;
    for _ in 0..initial_length {
        for list in 0..list_count {
            let node = allocated; allocated += 1;
            next[node] = head[list]; head[list] = node as i64;
            if tail[list] == -1 { tail[list] = node as i64; }
        }
    }
    let mut accumulate = 0i64;
    let mut growth_milli = 0i32;
    for _ in 0..iterations {
        for list in 0..list_count {
            let mut node = head[list];
            while node != -1 {
                let index = node as usize;
                accumulate += count[index]; count[index] += 1;
                node = next[index];
            }
        }
        growth_milli += 333;
        let insertions = growth_milli / 1000;
        growth_milli -= insertions * 1000;
        for ordinal in (1..=insertions).rev() {
            for list in 0..list_count {
                let node = allocated; allocated += 1;
                count[node] = (list + ordinal as usize) as i64;
                next[node] = -1;
                next[tail[list] as usize] = node as i64;
                tail[list] = node as i64;
            }
        }
    }
    let result = std::slice::from_raw_parts_mut(output, 16);
    store_le_i64(result, 0, accumulate);
    store_le_i64(result, 8, allocated as i64);
    2
}
