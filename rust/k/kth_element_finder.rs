use std::cmp::Reverse;
use std::collections::BinaryHeap;

const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub extern "C" fn kth_element_finder(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=259).contains(&length) {
        return INVALID_RESULT;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let mode = values[0];
    let n_value = values[1];
    let k_value = values[2];
    if (mode != 0 && mode != 1) || !(1..=256).contains(&n_value) ||
        k_value < 1 || k_value > n_value || length != n_value as usize + 3 {
        return INVALID_RESULT;
    }
    let n = n_value as usize;
    let k = k_value as usize;
    let items = &values[3..];
    if items.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) {
        return INVALID_RESULT;
    }

    if mode == 0 {
        let mut heap = BinaryHeap::<Reverse<i64>>::with_capacity(k);
        for &value in &items[..k] { heap.push(Reverse(value)); }
        for &value in &items[k..n] {
            if value > heap.peek().unwrap().0 {
                heap.pop();
                heap.push(Reverse(value));
            }
        }
        heap.peek().unwrap().0
    } else {
        let mut heap = BinaryHeap::<i64>::with_capacity(k);
        for &value in &items[..k] { heap.push(value); }
        for &value in &items[k..n] {
            if value < *heap.peek().unwrap() {
                heap.pop();
                heap.push(value);
            }
        }
        *heap.peek().unwrap()
    }
}
