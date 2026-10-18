const MAX_OPS: usize = 64;
const MAX_INPUT: usize = 130;
const MAX_OUTPUT: usize = MAX_OPS * 4;

#[no_mangle]
pub unsafe extern "C" fn priority_queue(input: *const i64, input_length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_OPS as i64).contains(&values[0]) { return -1; }
    let op_count = values[0] as usize;
    let mut heap = [0i32; MAX_OPS];
    let mut seen = [0i32; MAX_OPS];
    let mut heap_size = 0usize;
    let mut seen_count = 0usize;
    let mut offset = 1usize;
    let mut staged = [0u8; MAX_OUTPUT];
    let mut output_size = 0usize;
    for _ in 0..op_count {
        if offset >= input_length { return -1; }
        let op = values[offset]; offset += 1;
        if op == 0 {
            if offset >= input_length { return -1; }
            let raw = values[offset]; offset += 1;
            if raw < i32::MIN as i64 || raw > i32::MAX as i64 { return -1; }
            let value = raw as i32;
            if seen[..seen_count].contains(&value) { return -1; }
            seen[seen_count] = value; seen_count += 1;
            let mut i = heap_size; heap_size += 1; heap[i] = value;
            while i != 0 {
                let parent = (i - 1) / 2;
                if heap[parent] <= heap[i] { break; }
                heap.swap(parent, i); i = parent;
            }
        } else if op == 1 || op == 2 {
            if heap_size == 0 { return -1; }
            staged[output_size..output_size + 4].copy_from_slice(&heap[0].to_le_bytes());
            output_size += 4;
            if op == 2 {
                heap_size -= 1; heap[0] = heap[heap_size];
                let mut i = 0usize;
                while i < heap_size {
                    let mut child = 2 * i + 1;
                    if child >= heap_size { break; }
                    if child + 1 < heap_size && heap[child + 1] < heap[child] { child += 1; }
                    if heap[i] <= heap[child] { break; }
                    heap.swap(i, child); i = child;
                }
            }
        } else { return -1; }
    }
    if offset != input_length { return -1; }
    if output.is_null() || capacity < output_size { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_size);
    output_size as i64
}
