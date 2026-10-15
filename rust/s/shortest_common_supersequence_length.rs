/// Return the shortest common supersequence length of two packed ASCII sequences.
#[no_mangle]
pub extern "C" fn shortest_common_supersequence_length(packed: *const i64, length: usize) -> i64 {
    if length < 2 || length > 512 || packed.is_null() {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let left_length = packed[0];
    let right_length = packed[1];
    if !(0..=255).contains(&left_length)
        || !(0..=255).contains(&right_length)
        || length != 2 + left_length as usize + right_length as usize
    {
        return -1;
    }
    let left = &packed[2..2 + left_length as usize];
    let right = &packed[2 + left_length as usize..];
    if left.iter().chain(right.iter()).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let rows = left_length as usize + 1;
    let columns = right_length as usize + 1;
    let mut table = [0i64; 256 * 256];
    for i in 1..rows {
        for j in 1..columns {
            let cell = i * columns + j;
            if left[i - 1] == right[j - 1] {
                table[cell] = table[(i - 1) * columns + j - 1] + 1;
            } else {
                table[cell] = table[(i - 1) * columns + j].max(table[i * columns + j - 1]);
            }
        }
    }
    left_length + right_length - table[(rows - 1) * columns + columns - 1]
}
