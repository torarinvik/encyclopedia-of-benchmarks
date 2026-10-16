/// Return the encoded narrowest interval that covers all sorted input lists.
#[no_mangle]
pub extern "C" fn smallest_range(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || !(2..=273).contains(&length) { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    if !(1..=16).contains(&packed[0]) { return -1; }
    let count = packed[0] as usize;
    let mut values: [Vec<i64>; 16] = std::array::from_fn(|_| Vec::new());
    let mut positions = [0usize; 16];
    let mut heap = [0usize; 16];
    let mut offset = 1usize;
    let mut total = 0usize;
    let mut current_max = -1_000_000_001i64;
    for list in 0..count {
        if offset >= length || !(1..=16).contains(&packed[offset]) { return -1; }
        let list_len = packed[offset] as usize;
        offset += 1;
        if list_len > 256 - total || offset + list_len > length { return -1; }
        total += list_len;
        for j in 0..list_len {
            let value = packed[offset];
            offset += 1;
            if !(-1_000_000_000..=1_000_000_000).contains(&value)
                || (j > 0 && value < values[list][j - 1]) { return -1; }
            values[list].push(value);
        }
        heap[list] = list;
        current_max = current_max.max(values[list][0]);
    }
    if offset != length { return -1; }
    let less = |a: usize, b: usize, pos: &[usize; 16], lists: &[Vec<i64>; 16]| {
        (lists[a][pos[a]], a) < (lists[b][pos[b]], b)
    };
    let mut heap_size = count;
    for start in (0..heap_size / 2).rev() {
        let mut root = start;
        loop {
            let mut child = root * 2 + 1;
            if child >= heap_size { break; }
            if child + 1 < heap_size && less(heap[child + 1], heap[child], &positions, &values) { child += 1; }
            if !less(heap[child], heap[root], &positions, &values) { break; }
            heap.swap(root, child); root = child;
        }
    }
    let (mut best_lo, mut best_hi, mut best_width) = (0i64, 0i64, i64::MAX);
    loop {
        let list = heap[0];
        let lo = values[list][positions[list]];
        let width = current_max - lo;
        if width < best_width { best_width = width; best_lo = lo; best_hi = current_max; }
        positions[list] += 1;
        if positions[list] == values[list].len() { break; }
        current_max = current_max.max(values[list][positions[list]]);
        let mut root = 0usize;
        loop {
            let mut child = root * 2 + 1;
            if child >= heap_size { break; }
            if child + 1 < heap_size && less(heap[child + 1], heap[child], &positions, &values) { child += 1; }
            if !less(heap[child], heap[root], &positions, &values) { break; }
            heap.swap(root, child); root = child;
        }
    }
    (best_lo + 1_000_000_000) * 2_000_000_001 + best_hi + 1_000_000_000
}
