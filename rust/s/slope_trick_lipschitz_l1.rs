// Uncompiled and unexecuted two-heap slope-trick draft.
use std::cmp::Reverse;
use std::collections::BinaryHeap;

#[no_mangle]
pub unsafe extern "C" fn slope_trick_lipschitz_l1(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=130).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&values[0]) || !(0..=100).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    if length != n+2 || values[2..].iter().any(|&x| !(0..=100).contains(&x)) { return -1; }
    let mut left = BinaryHeap::new();
    let mut right = BinaryHeap::new();
    let (mut shift_l, mut shift_r, mut answer) = (0i64, 0i64, 0i64);
    for &x in &values[2..] {
        shift_l -= values[1];
        shift_r += values[1];
        left.push(x-shift_l);
        right.push(Reverse(x-shift_r));
        let l = *left.peek().unwrap()+shift_l;
        let r = right.peek().unwrap().0+shift_r;
        if l > r {
            left.pop(); right.pop();
            answer += l-r;
            left.push(r-shift_l);
            right.push(Reverse(l-shift_r));
        }
    }
    answer
}
