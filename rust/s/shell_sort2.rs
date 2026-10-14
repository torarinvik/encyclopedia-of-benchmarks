/// Shell sort using the Ciura gap sequence.
const CIURA_GAPS: [usize; 8] = [701, 301, 132, 57, 23, 10, 4, 1];

#[no_mangle]
pub unsafe extern "C" fn shell_sort2(values: *mut i64, length: usize) {
    for gap in CIURA_GAPS {
        let mut index = gap;
        while index < length {
            let key = *values.add(index);
            let mut position = index;
            while position >= gap && *values.add(position - gap) > key {
                *values.add(position) = *values.add(position - gap);
                position -= gap;
            }
            *values.add(position) = key;
            index += 1;
        }
    }
}
