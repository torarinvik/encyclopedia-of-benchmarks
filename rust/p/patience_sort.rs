/// Patience sorting with lower-bound piles and a binary min-heap merge.
const MAX_INPUT_LENGTH: usize = 1024;

fn node_less(keys: &[i64; MAX_INPUT_LENGTH], left: usize, right: usize) -> bool {
    keys[left] < keys[right] || (keys[left] == keys[right] && left < right)
}

fn sift_down(keys: &[i64; MAX_INPUT_LENGTH], heap: &mut [usize; MAX_INPUT_LENGTH],
             heap_length: usize, start_root: usize) {
    let mut root = start_root;
    while root < heap_length / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < heap_length && node_less(keys, heap[child + 1], heap[child]) { child += 1; }
        if !node_less(keys, heap[child], heap[root]) { break; }
        heap.swap(root, child);
        root = child;
    }
}

#[no_mangle]
pub unsafe extern "C" fn patience_sort(values: *mut i64, length: usize) {
    if length < 2 || length > MAX_INPUT_LENGTH { return; }
    let mut keys = [0i64; MAX_INPUT_LENGTH];
    let mut pile_tops = [0usize; MAX_INPUT_LENGTH];
    let mut next_in_pile = [length; MAX_INPUT_LENGTH];
    let mut heap = [0usize; MAX_INPUT_LENGTH];
    let mut pile_count = 0usize;
    for index in 0..length {
        keys[index] = *values.add(index);
        let mut low = 0usize;
        let mut high = pile_count;
        while low < high {
            let middle = low + (high - low) / 2;
            if keys[pile_tops[middle]] >= keys[index] { high = middle; }
            else { low = middle + 1; }
        }
        if low == pile_count {
            pile_tops[pile_count] = index;
            pile_count += 1;
        } else {
            next_in_pile[index] = pile_tops[low];
            pile_tops[low] = index;
        }
    }
    heap[..pile_count].copy_from_slice(&pile_tops[..pile_count]);
    let mut heap_length = pile_count;
    let mut start = heap_length / 2;
    while start > 0 {
        start -= 1;
        sift_down(&keys, &mut heap, heap_length, start);
    }
    let mut output = 0usize;
    while heap_length > 0 {
        let node = heap[0];
        *values.add(output) = keys[node];
        output += 1;
        let successor = next_in_pile[node];
        if successor < length { heap[0] = successor; }
        else {
            heap_length -= 1;
            if heap_length > 0 { heap[0] = heap[heap_length]; }
        }
        if heap_length > 0 { sift_down(&keys, &mut heap, heap_length, 0); }
    }
}
