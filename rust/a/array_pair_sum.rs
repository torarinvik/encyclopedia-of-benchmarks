/// Sort signed 32-bit values and sum the first of every adjacent pair.
const MAX_LENGTH: usize = 4096;

fn sift_down(values: &mut [i64; MAX_LENGTH], root_value: usize, count: usize) {
    let mut root = root_value;
    while root * 2 + 1 < count {
        let mut child = root * 2 + 1;
        if child + 1 < count && values[child] < values[child + 1] { child += 1; }
        if values[root] >= values[child] { return; }
        values.swap(root, child);
        root = child;
    }
}

#[no_mangle]
pub extern "C" fn array_pair_sum(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || length % 2 != 0 || (length != 0 && input.is_null()) { return -1; }
    let mut values = [0_i64; MAX_LENGTH];
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if !(-2_147_483_648..=2_147_483_647).contains(&value) { return -1; }
        values[index] = value;
    }
    for start in (1..=length / 2).rev() { sift_down(&mut values, start - 1, length); }
    for end in (2..=length).rev() {
        values.swap(0, end - 1);
        sift_down(&mut values, 0, end - 1);
    }
    let mut total = 0_i64;
    for index in (0..length).step_by(2) { total += values[index]; }
    total
}
