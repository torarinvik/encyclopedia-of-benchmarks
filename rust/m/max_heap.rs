const MAX_OPERATIONS: usize = 512;
const MAX_INSERTIONS: usize = 256;
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) { output[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn max_heap(raw: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if raw.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if input[0] < 0 || input[0] as usize > MAX_OPERATIONS { return -1; }
    let operations = input[0] as usize;
    if length != 1 + operations * 2 { return -1; }
    let (mut inserts, mut words) = (0, 0);
    for i in 0..operations { let (op, value) = (input[1 + 2 * i], input[2 + 2 * i]);
        if !(0..=2).contains(&op) { return -1; }
        if op == 0 { inserts += 1; if inserts > MAX_INSERTIONS || value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; } }
        else { if value != 0 { return -1; } words += 1; }
    }
    if capacity < words * 8 || (words > 0 && output.is_null()) { return -2; }
    let mut heap = [0i64; MAX_INSERTIONS]; let (mut size, mut out) = (0usize, 0usize);
    let bytes = if words == 0 { &mut [] } else { std::slice::from_raw_parts_mut(output, words * 8) };
    for i in 0..operations { let (op, value) = (input[1 + 2 * i], input[2 + 2 * i]);
        if op == 0 { let mut at = size; size += 1; heap[at] = value; while at > 0 { let p = (at - 1) / 2; if heap[p] >= heap[at] { break; } heap.swap(p, at); at = p; } continue; }
        let mut result = i64::MIN;
        if size > 0 { result = heap[0]; if op == 2 { size -= 1; heap[0] = heap[size]; let mut at = 0; while at < size / 2 { let mut child = at * 2 + 1; if child + 1 < size && heap[child + 1] > heap[child] { child += 1; } if heap[at] >= heap[child] { break; } heap.swap(at, child); at = child; } } }
        store_i64_le(bytes, out * 8, result); out += 1;
    }
    words as i64
}
