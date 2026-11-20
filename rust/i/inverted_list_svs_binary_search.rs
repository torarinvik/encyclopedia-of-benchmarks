const MIN_LISTS: usize = 2;
const MAX_LISTS: usize = 8;
const MAX_LIST_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = MAX_LISTS * (MAX_LIST_LENGTH + 1) + 2;
const BYTES_PER_VALUE: usize = 4;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() { *output.add(position + byte) = *octet; }
}

#[no_mangle]
pub extern "C" fn inverted_list_svs_binary_search(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < MIN_LISTS + 1 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    if packed[0] < MIN_LISTS as i64 || packed[0] > MAX_LISTS as i64 { return -1; }
    let count = packed[0] as usize;
    let mut starts = [0usize; MAX_LISTS];
    let mut sizes = [0usize; MAX_LISTS];
    let mut order = [0usize; MAX_LISTS];
    let mut position = 1usize;
    for list in 0..count {
        if position >= length || packed[position] < 0 || packed[position] > MAX_LIST_LENGTH as i64 { return -1; }
        let size = packed[position] as usize; position += 1;
        if size > length - position { return -1; }
        starts[list] = position; sizes[list] = size; order[list] = list;
        for i in 0..size {
            if packed[position + i] < i32::MIN as i64 || packed[position + i] > i32::MAX as i64 { return -1; }
            if i > 0 && packed[position + i - 1] >= packed[position + i] { return -1; }
        }
        position += size;
    }
    if position != length { return -1; }
    for i in 1..count {
        let key = order[i]; let mut j = i;
        while j > 0 && sizes[order[j - 1]] > sizes[key] { order[j] = order[j - 1]; j -= 1; }
        order[j] = key;
    }
    let maximum_result = sizes[order[0]];
    if output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result != 0 && output.is_null()) { return -2; }
    let mut candidates = [0i32; MAX_LIST_LENGTH];
    let mut candidate_count = maximum_result;
    for i in 0..candidate_count { candidates[i] = packed[starts[order[0]] + i] as i32; }
    for rank in 1..count {
        if candidate_count == 0 { break; }
        let list = order[rank]; let start = starts[list]; let size = sizes[list];
        let mut cursor = 0usize; let mut kept = 0usize;
        for i in 0..candidate_count {
            let candidate = candidates[i]; let mut low = cursor; let mut high = size;
            while low < high {
                let middle = low + (high - low) / 2;
                if packed[start + middle] < candidate as i64 { low = middle + 1; } else { high = middle; }
            }
            if low < size && packed[start + low] == candidate as i64 {
                candidates[kept] = candidate; kept += 1; cursor = low + 1;
            } else { cursor = low; }
        }
        candidate_count = kept;
    }
    for i in 0..candidate_count { unsafe { store_i32_le(output, i * BYTES_PER_VALUE, candidates[i]); } }
    candidate_count as i64
}
