const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const ELEMENT_COUNT: usize = 500;
const MAX_OUTPUT_BYTES: usize = 700;

fn build_and_sort_pass(run: usize) -> (i32, bool) {
    let mut sortlist = [0_i32; ELEMENT_COUNT + 1];
    let mut biggest = 0_i32;
    let mut littlest = 0_i32;
    let mut seed = 74755_i64;
    for index in 1..=ELEMENT_COUNT {
        seed = (seed * 1309 + 13849) & 65535;
        let temp = seed;
        sortlist[index] = (temp - (temp / 100000) * 100000 - 50000) as i32;
        if sortlist[index] > biggest { biggest = sortlist[index]; }
        else if sortlist[index] < littlest { littlest = sortlist[index]; }
    }
    let mut top = ELEMENT_COUNT;
    while top > 1 {
        let mut index = 1;
        while index < top {
            if sortlist[index] > sortlist[index + 1] {
                let temp = sortlist[index];
                sortlist[index] = sortlist[index + 1];
                sortlist[index + 1] = temp;
            }
            index += 1;
        }
        top -= 1;
    }
    (sortlist[run + 1], sortlist[1] != littlest || sortlist[ELEMENT_COUNT] != biggest)
}

fn append_text(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, text: &[u8]) {
    for &byte in text { buffer[*used] = byte; *used += 1; }
}

fn append_integer(buffer: &mut [u8; MAX_OUTPUT_BYTES], used: &mut usize, value: i32) {
    let mut remaining = value;
    if remaining < 0 { buffer[*used] = b'-'; *used += 1; remaining = -remaining; }
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
pub unsafe extern "C" fn stanford_bubblesort(runs: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(MIN_RUNS..=MAX_RUNS).contains(&runs) { return -1; }
    if output.is_null() { return -2; }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    for run in 0..runs as usize {
        let (value, endpoint_error) = build_and_sort_pass(run);
        if endpoint_error { append_text(&mut staged, &mut used, b"Error3 in Bubble.\n"); }
        append_integer(&mut staged, &mut used, value);
        append_text(&mut staged, &mut used, b"\n");
    }
    if output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
