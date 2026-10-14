const MAX_VALUES: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn bingo_sort(values: *mut i64, length: usize) {
    if length > MAX_VALUES || length < 2 { return }
    let mut bingo = *values;
    for index in 1..length {
        if *values.add(index) < bingo { bingo = *values.add(index); }
    }
    let mut next_position = 0;
    while next_position < length {
        let mut has_next = false;
        let mut next_bingo = 0_i64;
        let mut index = next_position;
        while index < length {
            if *values.add(index) == bingo {
                std::ptr::swap(values.add(index), values.add(next_position));
                next_position += 1;
            } else if !has_next || *values.add(index) < next_bingo {
                next_bingo = *values.add(index);
                has_next = true;
            }
            index += 1;
        }
        if next_position == length { break }
        bingo = next_bingo;
    }
}
