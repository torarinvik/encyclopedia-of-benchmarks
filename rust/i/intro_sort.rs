/// Introsort with quicksort partitioning, a heapsort depth fallback, and insertion cutoff.
fn insertion_sort(values: &mut [i64]) {
    for index in 1..values.len() {
        let key = values[index];
        let mut cursor = index;
        while cursor > 0 && values[cursor - 1] > key {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = key;
    }
}

fn sift_down(values: &mut [i64], mut root: usize, count: usize) {
    while root < count / 2 {
        let mut child = root * 2 + 1;
        if child + 1 < count && values[child] < values[child + 1] {
            child += 1;
        }
        if values[root] >= values[child] {
            return;
        }
        values.swap(root, child);
        root = child;
    }
}

fn heap_sort(values: &mut [i64]) {
    let count = values.len();
    for parent in (0..count / 2).rev() {
        sift_down(values, parent, count);
    }
    for ending in (1..count).rev() {
        values.swap(0, ending);
        sift_down(values, 0, ending);
    }
}

fn partition(values: &mut [i64]) -> usize {
    let last = values.len() - 1;
    let pivot_index = values.len() / 2;
    values.swap(pivot_index, last);
    let pivot = values[last];
    let mut boundary = 0;
    for probe in 0..last {
        if values[probe] <= pivot {
            values.swap(boundary, probe);
            boundary += 1;
        }
    }
    values.swap(boundary, last);
    boundary
}

fn intro_sort_range(values: &mut [i64], depth: usize) {
    if values.len() <= 16 {
        insertion_sort(values);
        return;
    }
    if depth == 0 {
        heap_sort(values);
        return;
    }
    let pivot = partition(values);
    let (left, tail) = values.split_at_mut(pivot);
    let (_, right) = tail.split_at_mut(1);
    intro_sort_range(left, depth - 1);
    intro_sort_range(right, depth - 1);
}

fn depth_limit(mut length: usize) -> usize {
    let mut logarithm = 0;
    while length > 1 {
        length >>= 1;
        logarithm += 1;
    }
    logarithm * 2
}

#[no_mangle]
pub extern "C" fn intro_sort(values: *mut i64, length: usize) {
    if length < 2 {
        return;
    }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    intro_sort_range(values, depth_limit(length));
}
