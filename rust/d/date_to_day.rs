/// Return the English weekday name for a bounded ASCII d/m/yyyy date.
#[no_mangle]
pub unsafe extern "C" fn date_to_day(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(9..=11).contains(&length) || *input.add(length - 1) != 0 { return -1; }
    let date_length = length - 1;
    let mut cursor = 0usize;
    let mut fields = [0i64; 3];
    for field in 0..3 {
        let start = cursor;
        let mut value = 0i64;
        while cursor < date_length {
            let byte = *input.add(cursor);
            if !(48..=57).contains(&byte) { break; }
            value = value * 10 + byte - 48;
            cursor += 1;
        }
        let digits = cursor - start;
        let max_digits = if field == 2 { 4 } else { 2 };
        if digits == 0 || digits > max_digits || (field == 2 && digits != 4) { return -1; }
        fields[field] = value;
        if field < 2 {
            if cursor >= date_length || *input.add(cursor) != 47 { return -1; }
            cursor += 1;
        }
    }
    if cursor != date_length { return -1; }
    let (day, month, year) = (fields[0] as i32, fields[1] as i32, fields[2] as i32);
    if !(1..=9999).contains(&year) || !(1..=12).contains(&month) || day < 1 { return -1; }
    let leap = year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
    let month_days = [31, if leap { 29 } else { 28 }, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if day > month_days[(month - 1) as usize] { return -1; }

    let mut adjusted_year = year;
    let mut adjusted_month = month;
    if adjusted_month < 3 { adjusted_year -= 1; adjusted_month += 12; }
    let year_of_century = adjusted_year % 100;
    let century = adjusted_year / 100;
    let weekday = (day + ((adjusted_month + 1) * 26) / 10 + year_of_century +
                   year_of_century / 4 + century / 4 + 5 * century) % 7;
    let names: [&[u8]; 7] = [b"Saturday", b"Sunday", b"Monday", b"Tuesday", b"Wednesday", b"Thursday", b"Friday"];
    let name = names[weekday as usize];
    if output_capacity < name.len() || output.is_null() { return -2; }
    for index in 0..name.len() { *output.add(index) = name[index]; }
    name.len() as i64
}
