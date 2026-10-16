const MAX_TEXT: usize = 256;
const MAX_INPUT: usize = 259;

#[no_mangle]
pub extern "C" fn transposition_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let (mode, key64, n64) = (input[0], input[1], input[2]);
    if (mode != 0 && mode != 1) || n64 < 3 || n64 > MAX_TEXT as i64 || key64 < 2 || key64 >= n64
        || length != 3 + n64 as usize { return -1; }
    let (key, n) = (key64 as usize, n64 as usize);
    if input[3..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }
    if output.is_null() || output_capacity < n { return -2; }

    let mut transformed = [0u8; MAX_TEXT];
    if mode == 0 {
        let mut written = 0;
        for column in 0..key {
            let mut index = column;
            while index < n {
                transformed[written] = input[3 + index] as u8;
                written += 1;
                index += key;
            }
        }
    } else {
        let columns = (n + key - 1) / key;
        let shaded = columns * key - n;
        let final_column_rows = key - shaded;
        let mut offsets = [0usize; MAX_TEXT];
        let mut seen = [0usize; MAX_TEXT];
        let mut total = 0;
        for column in 0..columns {
            offsets[column] = total;
            total += if column + 1 == columns { final_column_rows } else { key };
        }
        let mut row = 0;
        let mut column = 0;
        for i in 0..n {
            transformed[offsets[column] + seen[column]] = input[3 + i] as u8;
            seen[column] += 1;
            column += 1;
            if column == columns || (column == columns - 1 && row >= final_column_rows) {
                column = 0;
                row += 1;
            }
        }
    }
    unsafe { std::ptr::copy_nonoverlapping(transformed.as_ptr(), output, n); }
    n as i64
}
