const MAX_ITEMS: usize = 1024;
const NONE: u32 = MAX_ITEMS as u32;
type NodeTable = [u32; MAX_ITEMS];

fn pile_less(values: &[i64], pile_front: &NodeTable, left: u32, right: u32) -> bool {
    let left_node = pile_front[left as usize] as usize;
    let right_node = pile_front[right as usize] as usize;
    if values[left_node] != values[right_node] {
        values[left_node] < values[right_node]
    } else {
        left < right
    }
}

fn sift_down(values: &[i64], pile_front: &NodeTable, heap: &mut NodeTable,
             heap_size: u32, mut position: u32) {
    while position * 2 + 1 < heap_size {
        let mut child = position * 2 + 1;
        if child + 1 < heap_size
            && pile_less(values, pile_front, heap[(child + 1) as usize], heap[child as usize])
        {
            child += 1;
        }
        if !pile_less(values, pile_front, heap[child as usize], heap[position as usize]) {
            break;
        }
        heap.swap(position as usize, child as usize);
        position = child;
    }
}

fn sort_values(values: &mut [i64], scratch: &mut [i64]) {
    if values.len() < 2 || values.len() > MAX_ITEMS { return; }
    let mut previous: NodeTable = [0; MAX_ITEMS];
    let mut next: NodeTable = [0; MAX_ITEMS];
    let mut pile_front: NodeTable = [0; MAX_ITEMS];
    let mut pile_back: NodeTable = [0; MAX_ITEMS];
    let mut heap: NodeTable = [0; MAX_ITEMS];
    let mut pile_count = 0_u32;

    for node in 0..values.len() {
        previous[node] = NONE;
        next[node] = NONE;
        let mut pile = 0_u32;
        while pile < pile_count {
            let front = pile_front[pile as usize] as usize;
            let back = pile_back[pile as usize] as usize;
            if values[node] <= values[front] {
                next[node] = pile_front[pile as usize];
                previous[front] = node as u32;
                pile_front[pile as usize] = node as u32;
                break;
            }
            if values[node] >= values[back] {
                previous[node] = pile_back[pile as usize];
                next[back] = node as u32;
                pile_back[pile as usize] = node as u32;
                break;
            }
            pile += 1;
        }
        if pile == pile_count {
            pile_front[pile_count as usize] = node as u32;
            pile_back[pile_count as usize] = node as u32;
            pile_count += 1;
        }
    }

    let mut heap_size = 0_u32;
    for pile in 0..pile_count {
        let mut position = heap_size;
        heap[position as usize] = pile;
        heap_size += 1;
        while position > 0 {
            let parent = (position - 1) / 2;
            if !pile_less(values, &pile_front, heap[position as usize], heap[parent as usize]) {
                break;
            }
            heap.swap(position as usize, parent as usize);
            position = parent;
        }
    }

    let mut output = 0;
    while heap_size > 0 {
        let pile = heap[0] as usize;
        let node = pile_front[pile] as usize;
        scratch[output] = values[node];
        output += 1;
        let successor = next[node];
        if successor != NONE {
            previous[successor as usize] = NONE;
            next[node] = NONE;
            pile_front[pile] = successor;
        } else {
            pile_front[pile] = NONE;
            pile_back[pile] = NONE;
            heap_size -= 1;
            if heap_size > 0 { heap[0] = heap[heap_size as usize]; }
        }
        if heap_size > 0 { sift_down(values, &pile_front, &mut heap, heap_size, 0); }
    }
    let length = values.len();
    values.copy_from_slice(&scratch[..length]);
}

#[no_mangle]
pub unsafe extern "C" fn unshuffle_sort(values: *mut i64, scratch: *mut i64, length: usize) {
    if values.is_null() || scratch.is_null() || length < 2 || length > MAX_ITEMS { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let scratch = unsafe { std::slice::from_raw_parts_mut(scratch, length) };
    sort_values(values, scratch);
}
