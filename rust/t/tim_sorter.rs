const MAX_ITEMS: usize = 512;
const MIN_MERGE: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1_026;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

#[derive(Clone, Copy, Default)]
struct Item { key: i64, id: i64 }

fn binary_sort(items: &mut [Item; MAX_ITEMS], start: usize, end: usize, mut first: usize) {
    if first >= end || first <= start { first = start + 1; }
    while first < end {
        let target = items[first];
        let mut left = start;
        let mut right = first;
        while left < right {
            let middle = (left + right) >> 1;
            if target.key < items[middle].key { right = middle; } else { left = middle + 1; }
        }
        let mut cursor = first;
        while cursor > left { items[cursor] = items[cursor - 1]; cursor -= 1; }
        items[left] = target;
        first += 1;
    }
}

fn count_run_and_make_ascending(items: &mut [Item; MAX_ITEMS], start: usize, length: usize) -> usize {
    let mut end = start + 1;
    if end == length { return 1; }
    if items[end].key < items[start].key {
        end += 1;
        while end < length && items[end].key < items[end - 1].key { end += 1; }
        items[start..end].reverse();
    } else {
        end += 1;
        while end < length && items[end].key >= items[end - 1].key { end += 1; }
    }
    end - start
}

fn min_run_length(mut total: usize) -> usize {
    let mut remainder = 0;
    while total >= MIN_MERGE { remainder |= total & 1; total >>= 1; }
    total + remainder
}

fn merge_at(items: &mut [Item; MAX_ITEMS], run_base: &mut [usize; 85],
            run_length: &mut [usize; 85], stack_size: &mut usize, index: usize,
            temp: &mut [Item; MAX_ITEMS]) {
    let base_a = run_base[index];
    let len_a = run_length[index];
    let base_b = run_base[index + 1];
    let len_b = run_length[index + 1];
    run_length[index] = len_a + len_b;
    if index == *stack_size - 3 {
        run_base[index + 1] = run_base[index + 2];
        run_length[index + 1] = run_length[index + 2];
    }
    *stack_size -= 1;
    temp[..len_a].copy_from_slice(&items[base_a..base_a + len_a]);
    let (mut left, mut right, mut dest) = (0, base_b, base_a);
    let end_b = base_b + len_b;
    while left < len_a && right < end_b {
        if items[right].key < temp[left].key { items[dest] = items[right]; right += 1; }
        else { items[dest] = temp[left]; left += 1; }
        dest += 1;
    }
    while left < len_a { items[dest] = temp[left]; left += 1; dest += 1; }
}

fn merge_collapse(items: &mut [Item; MAX_ITEMS], run_base: &mut [usize; 85],
                  run_length: &mut [usize; 85], stack_size: &mut usize,
                  temp: &mut [Item; MAX_ITEMS]) {
    while *stack_size > 1 {
        let mut n = *stack_size - 2;
        if n > 0 && run_length[n - 1] <= run_length[n] + run_length[n + 1] {
            if run_length[n - 1] < run_length[n + 1] { n -= 1; }
            merge_at(items, run_base, run_length, stack_size, n, temp);
        } else if run_length[n] <= run_length[n + 1] {
            merge_at(items, run_base, run_length, stack_size, n, temp);
        } else { break; }
    }
}

fn tim_sort(items: &mut [Item; MAX_ITEMS], length: usize) {
    if length < MIN_MERGE {
        binary_sort(items, 0, length, 0);
        return;
    }
    let min_run = min_run_length(length);
    let mut run_base = [0_usize; 85];
    let mut run_length = [0_usize; 85];
    let mut stack_size = 0;
    let mut temp = [Item::default(); MAX_ITEMS];
    let mut start = 0;
    let mut remaining = length;
    while remaining > 0 {
        let mut current_run = count_run_and_make_ascending(items, start, length);
        if current_run < min_run {
            let force = min_run.min(remaining);
            binary_sort(items, start, start + force, start + current_run);
            current_run = force;
        }
        run_base[stack_size] = start;
        run_length[stack_size] = current_run;
        stack_size += 1;
        merge_collapse(items, &mut run_base, &mut run_length, &mut stack_size, &mut temp);
        start += current_run;
        remaining -= current_run;
    }
    while stack_size > 1 {
        let mut n = stack_size - 2;
        if n > 0 && run_length[n - 1] < run_length[n + 1] { n -= 1; }
        merge_at(items, &mut run_base, &mut run_length, &mut stack_size, n, &mut temp);
    }
}

#[no_mangle]
pub unsafe extern "C" fn tim_sorter_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ITEMS as i64 { return -1; }
    let count = values[0] as usize;
    if length != 1 + 2 * count { return -1; }
    let mut items = [Item::default(); MAX_ITEMS];
    let mut seen = [false; MAX_ITEMS];
    for index in 0..count {
        let key = values[1 + 2 * index];
        let id = values[2 + 2 * index];
        if !(-1_000..=1_000).contains(&key) || id < 0 || id >= count as i64 || seen[id as usize] { return -1; }
        seen[id as usize] = true;
        items[index] = Item { key, id };
    }
    tim_sort(&mut items, count);
    let mut checksum = 0_i64;
    for item in &items[..count] {
        let token = (item.key + 1_000) * 513 + item.id + 1;
        checksum = (checksum * HASH_MULTIPLIER + token) % HASH_MODULUS;
    }
    checksum
}
