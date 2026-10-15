/// Count a maximum set of non-overlapping half-open activities.
#[no_mangle]
pub extern "C" fn activity_selection(input: *const i64, length: usize) -> i64 {
    if length == 0 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 || input[0] > 64 { return -1; }
    let count = input[0] as usize;
    if length != 1 + 2 * count { return -1; }
    if count == 0 { return 0; }
    let mut starts = [0i64; 64];
    let mut finishes = [0i64; 64];
    for index in 0..count {
        starts[index] = input[1 + 2 * index];
        finishes[index] = input[2 + 2 * index];
        if starts[index] > finishes[index] { return -1; }
    }
    for index in 1..count {
        let start = starts[index];
        let finish = finishes[index];
        let mut position = index;
        while position > 0 && (finishes[position - 1] > finish ||
            (finishes[position - 1] == finish && starts[position - 1] > start)) {
            starts[position] = starts[position - 1];
            finishes[position] = finishes[position - 1];
            position -= 1;
        }
        starts[position] = start;
        finishes[position] = finish;
    }
    let mut selected = 1i64;
    let mut last_finish = finishes[0];
    for index in 1..count {
        if starts[index] >= last_finish {
            selected += 1;
            last_finish = finishes[index];
        }
    }
    selected
}
