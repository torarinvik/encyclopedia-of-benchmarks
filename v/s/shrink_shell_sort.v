module shrink_shell_sort

// Shell sort using the pinned Python 1.3 gap shrink factor.
@[export: 'shrink_shell_sort']
pub fn shrink_shell_sort(mut values &i64, length usize) {
    mut gap := length
    for gap > 1 {
        gap = usize(f64(gap) / 1.3)
        mut index := gap
        for index < length {
            key := unsafe { values[index] }
            mut position := index
            for position >= gap && unsafe { values[position - gap] } > key {
                unsafe { values[position] = values[position - gap] }
                position -= gap
            }
            unsafe { values[position] = key }
            index++
        }
    }
}
