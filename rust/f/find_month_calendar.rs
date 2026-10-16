const MIN_YEAR: i64 = 1899;
const MAX_YEAR: i64 = 2100;
const MAX_OUTPUT_BYTES: usize = 181;
const HEADER: &[u8] = b"M   T   W   Th  F   S   Su\n";

fn is_leap_year(year: i64) -> bool {
    year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

fn month_length(year: i64, month: i64) -> usize {
    if month == 2 && is_leap_year(year) { return 29; }
    match month {
        2 => 28,
        4 | 6 | 9 | 11 => 30,
        _ => 31,
    }
}

fn start_offset(month: i64, year: i64) -> usize {
    let mut difference = 0i64;
    if year >= 1900 {
        for current_year in 1900..year {
            difference += if is_leap_year(current_year) { 366 } else { 365 };
        }
        for current_month in 1..month {
            difference += month_length(year, current_month) as i64;
        }
        return (difference % 7) as usize;
    }
    for current_year in year..1900 {
        difference += if is_leap_year(current_year) { 366 } else { 365 };
    }
    for current_month in 1..month {
        difference -= month_length(1900, current_month) as i64;
    }
    ((7 - difference % 7) % 7) as usize
}

unsafe fn write_cell(output: *mut u8, position: &mut usize, day: usize) {
    let mut write = |byte: u8| {
        *output.add(*position) = byte;
        *position += 1;
    };
    if day == 0 {
        for _ in 0..4 { write(b' '); }
    } else if day >= 10 {
        write(b'0' + (day / 10) as u8);
        write(b'0' + (day % 10) as u8);
        write(b' ');
        write(b' ');
    } else {
        write(b'0' + day as u8);
        write(b' ');
        write(b' ');
        write(b' ');
    }
}

#[no_mangle]
pub unsafe extern "C" fn find_month_calendar(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let month = *values;
    let year = *values.add(1);
    if !(1..=12).contains(&month) || !(MIN_YEAR..=MAX_YEAR).contains(&year) { return -1; }

    let offset = start_offset(month, year);
    let total_cells = offset + month_length(year, month);
    let required = HEADER.len() + total_cells * 4 + (total_cells + 6) / 7;
    if required > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < required { return -2; }

    std::ptr::copy_nonoverlapping(HEADER.as_ptr(), output, HEADER.len());
    let mut written = HEADER.len();
    let mut cursor = 0usize;
    while cursor < total_cells {
        let cells = (total_cells - cursor).min(7);
        for column in 0..cells {
            let cell = cursor + column;
            let day = if cell < offset { 0 } else { cell - offset + 1 };
            write_cell(output, &mut written, day);
        }
        *output.add(written) = b'\n';
        written += 1;
        cursor += cells;
    }
    written as i64
}
