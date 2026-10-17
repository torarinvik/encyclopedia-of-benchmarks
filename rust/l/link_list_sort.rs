const MAX_ITEMS: usize = 128;

fn merge_sort(items: &mut [i32; MAX_ITEMS], scratch: &mut [i32; MAX_ITEMS], count: usize) {
    let mut width = 1;
    while width < count {
        let mut start = 0;
        while start < count {
            let middle = start + width.min(count - start);
            let end = middle + width.min(count - middle);
            let (mut left, mut right, mut out) = (start, middle, start);
            while left < middle && right < end {
                if items[left] <= items[right] { scratch[out] = items[left]; left += 1; }
                else { scratch[out] = items[right]; right += 1; }
                out += 1;
            }
            while left < middle { scratch[out] = items[left]; left += 1; out += 1; }
            while right < end { scratch[out] = items[right]; right += 1; out += 1; }
            start = end;
        }
        items[..count].copy_from_slice(&scratch[..count]);
        width *= 2;
    }
}

fn insertion_sort(items: &mut [i32; MAX_ITEMS], count: usize) {
    for i in 1..count {
        let value = items[i];
        let mut j = i;
        while j > 0 && items[j - 1] > value { items[j] = items[j - 1]; j -= 1; }
        items[j] = value;
    }
}

fn sift_down(items: &mut [i32; MAX_ITEMS], count: usize, mut root: usize) {
    while root < count / 2 {
        let mut child = 2 * root + 1;
        if child + 1 < count && items[child + 1] > items[child] { child += 1; }
        if items[root] >= items[child] { return; }
        items.swap(root, child);
        root = child;
    }
}

fn heap_sort(items: &mut [i32; MAX_ITEMS], count: usize) {
    for start in (0..count / 2).rev() { sift_down(items, count, start); }
    for end in (1..count).rev() { items.swap(0, end); sift_down(items, end, 0); }
}

#[no_mangle]
pub unsafe extern "C" fn link_list_sort(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + MAX_ITEMS { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let selector = input[0];
    let count_value = input[1];
    if !(1..=3).contains(&selector) || count_value < 0 || count_value > MAX_ITEMS as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + count { return -1; }
    let mut items = [0i32; MAX_ITEMS];
    let mut scratch = [0i32; MAX_ITEMS];
    for i in 0..count {
        if input[2 + i] < i32::MIN as i64 || input[2 + i] > i32::MAX as i64 { return -1; }
        items[i] = input[2 + i] as i32;
    }
    match selector { 1 => merge_sort(&mut items, &mut scratch, count), 2 => insertion_sort(&mut items, count), _ => heap_sort(&mut items, count) }
    let required = 4 * count;
    if output.is_null() || output_capacity < required { return -2; }
    for i in 0..count {
        let bytes = items[i].to_le_bytes();
        for byte in 0..4 { *output.add(4 * i + byte) = bytes[byte]; }
    }
    required as i64
}
