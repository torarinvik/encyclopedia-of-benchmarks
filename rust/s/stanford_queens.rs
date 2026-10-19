const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const SOLVE_REPETITIONS: usize = 50;
const MAX_OUTPUT_BYTES: usize = 292;

fn try_queens(
    row: usize,
    columns: &mut [bool; 9],
    diagonal_sum: &mut [bool; 17],
    diagonal_diff: &mut [bool; 15],
    positions: &mut [usize; 9],
) -> bool {
    let mut j = 0;
    let mut found = false;
    while !found && j != 8 {
        j += 1;
        found = false;
        if columns[j] && diagonal_sum[row + j] && diagonal_diff[row + 7 - j] {
            positions[row] = j;
            columns[j] = false;
            diagonal_sum[row + j] = false;
            diagonal_diff[row + 7 - j] = false;
            if row < 8 {
                found = try_queens(row + 1, columns, diagonal_sum, diagonal_diff, positions);
                if !found {
                    columns[j] = true;
                    diagonal_sum[row + j] = true;
                    diagonal_diff[row + 7 - j] = true;
                }
            } else {
                found = true;
            }
        }
    }
    found
}

fn doit() -> bool {
    let mut a = [false; 9];
    let mut b = [false; 17];
    let mut c = [false; 15];
    let mut x = [0_usize; 9];
    for i in -7_i32..=16 {
        if (1..=8).contains(&i) { a[i as usize] = true; }
        if i >= 2 { b[i as usize] = true; }
        if i <= 7 { c[(i + 7) as usize] = true; }
    }
    try_queens(1, &mut a, &mut b, &mut c, &mut x)
}

fn append_text(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, text: &[u8]) {
    for &byte in text { buffer[*used] = byte; *used += 1; }
}

fn append_integer(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, value: i32) {
    let mut remaining = value;
    let mut reverse = [0_u8; 12];
    let mut count = 0;
    loop {
        reverse[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 { count -= 1; buffer[*used] = reverse[count]; *used += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn stanford_queens(runs: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_RUNS..=MAX_RUNS).contains(&runs) { return -1; }
    if output.is_null() { return -2; }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    for run in 0..runs as usize {
        for _ in 0..SOLVE_REPETITIONS {
            if !doit() { append_text(&mut staged, &mut used, b" Error in Queens.\n"); }
        }
        append_integer(&mut staged, &mut used, (run + 1) as i32);
        append_text(&mut staged, &mut used, b"\n");
    }
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
