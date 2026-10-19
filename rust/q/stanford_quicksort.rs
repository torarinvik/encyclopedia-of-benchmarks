const SORT_ELEMENTS: usize = 5000;
const MAX_PREFIX_COUNT: i64 = 100;
const MAX_OUTPUT_BYTES: usize = 700;

fn source_quicksort(values: &mut [i64; SORT_ELEMENTS + 1], left: i64, right: i64) {
    let mut i = left;
    let mut j = right;
    let pivot = values[((left + right) / 2) as usize];
    loop {
        while values[i as usize] < pivot { i += 1; }
        while pivot < values[j as usize] { j -= 1; }
        if i <= j {
            values.swap(i as usize, j as usize);
            i += 1;
            j -= 1;
        }
        if i > j { break; }
    }
    if left < j { source_quicksort(values, left, j); }
    if i < right { source_quicksort(values, i, right); }
}

fn append_number(buffer: &mut [u8; MAX_OUTPUT_BYTES], mut used: usize, mut value: i64) -> usize {
    let mut reversed = [0_u8; 20];
    let mut count = 0;
    if value < 0 {
        buffer[used] = b'-';
        used += 1;
        value = -value;
    }
    loop {
        reversed[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[used] = reversed[count];
        used += 1;
    }
    buffer[used] = b'\n';
    used + 1
}

#[no_mangle]
pub extern "C" fn stanford_quicksort(prefix_count: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if prefix_count < 1 || prefix_count > MAX_PREFIX_COUNT { return -1; }
    if output.is_null() { return -2; }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut used = 0;
    for run in 0..prefix_count {
        let mut values = [0_i64; SORT_ELEMENTS + 1];
        let mut state = 74755_i64;
        for index in 1..=SORT_ELEMENTS {
            state = (state * 1309 + 13849) & 65535;
            values[index] = state - 50000;
        }
        source_quicksort(&mut values, 1, SORT_ELEMENTS as i64);
        used = append_number(&mut staged, used, values[(run + 1) as usize]);
    }

    if output_capacity < used { return -2; }
    unsafe {
        for index in 0..used { *output.add(index) = staged[index]; }
    }
    used as i64
}
