const INVALID_RESULT: i64 = i64::MIN;
const MAX_VALUES: usize = 1024;

/// Select the kth largest value using a sequentially populated max heap.
#[no_mangle]
pub extern "C" fn find_kth_number(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_VALUES + 1).contains(&length) { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let k = values[0];
    let count = length - 1;
    if k < 1 || k > count as i64 { return INVALID_RESULT; }
    let mut heap = [0_i32; MAX_VALUES];
    for i in 0..count {
        let input = values[i + 1];
        if input < i32::MIN as i64 || input > i32::MAX as i64 { return INVALID_RESULT; }
        let mut index = i;
        heap[index] = input as i32;
        while index > 0 {
            let parent = (index - 1) / 2;
            if heap[parent] >= heap[index] { break; }
            heap.swap(parent, index);
            index = parent;
        }
    }
    let mut heap_size = count;
    for _ in 1..k {
        heap_size -= 1;
        heap[0] = heap[heap_size];
        let mut index = 0;
        while index * 2 + 1 < heap_size {
            let mut child = index * 2 + 1;
            if child + 1 < heap_size && heap[child + 1] > heap[child] { child += 1; }
            if heap[index] >= heap[child] { break; }
            heap.swap(index, child);
            index = child;
        }
    }
    i64::from(heap[0])
}
