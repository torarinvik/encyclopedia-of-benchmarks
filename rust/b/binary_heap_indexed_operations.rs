/// Bounded operation stream for the source MinHeap API.
fn put_i64_le(output: *mut u8, slot: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(slot * 8), 8); }
}
fn sift_down(heap: &mut [i64; 256], size: usize, mut index: usize) {
    loop {
        let left = 2 * index + 1;
        let right = left + 1;
        let mut smallest = index;
        if left < size && heap[left] < heap[smallest] { smallest = left; }
        if right < size && heap[right] < heap[smallest] { smallest = right; }
        if smallest == index { return; }
        heap.swap(index, smallest);
        index = smallest;
    }
}
fn bubble_up(heap: &mut [i64; 256], mut index: usize) {
    while index > 0 {
        let parent = (index - 1) / 2;
        if heap[parent] <= heap[index] { break; }
        heap.swap(parent, index);
        index = parent;
    }
}

#[no_mangle]
pub unsafe extern "C" fn binary_heap_indexed_operations(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let raw_capacity = input[0];
    let raw_count = input[1];
    if !(1..=256).contains(&raw_capacity) || !(0..=512).contains(&raw_count) || length != 2 + raw_count as usize * 3 { return -1; }
    let mut heap = [0_i64; 256];
    let mut size = 0_usize;
    let mut outputs = 0_usize;
    for record in input[2..].chunks_exact(3) {
        let (op, a, b) = (record[0], record[1], record[2]);
        if op == 0 {
            if !(i32::MIN as i64..=i32::MAX as i64).contains(&a) || b != 0 { return -1; }
            if size < raw_capacity as usize { heap[size] = a; bubble_up(&mut heap,size); size += 1; }
        } else if op == 1 || op == 2 {
            if a != 0 || b != 0 || (op == 1 && size == 0) { return -1; }
            if output.is_null() || (outputs + 1) * 8 > capacity { return -2; }
            let result = if size == 0 { i32::MAX as i64 } else { heap[0] };
            if op == 2 && size > 0 { size -= 1; heap[0] = heap[size]; if size > 0 { sift_down(&mut heap,size,0); } }
            put_i64_le(output,outputs,result); outputs += 1;
        } else if op == 3 {
            if a < 0 || a as usize >= size || !(i32::MIN as i64..=i32::MAX as i64).contains(&b) || b > heap[a as usize] { return -1; }
            heap[a as usize] = b; bubble_up(&mut heap,a as usize);
        } else if op == 4 {
            if a < 0 || a as usize >= size || b != 0 { return -1; }
            heap[a as usize] = i32::MIN as i64; bubble_up(&mut heap,a as usize);
            size -= 1; heap[0] = heap[size]; if size > 0 { sift_down(&mut heap,size,0); }
        } else { return -1; }
    }
    (outputs * 8) as i64
}
