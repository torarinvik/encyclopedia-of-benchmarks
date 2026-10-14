module insertion_sort_recursive

fn insertion_sort_prefix(mut values &i64, length usize) {
    if length <= 1 { return }
    insertion_sort_prefix(mut values, length - 1)
    key := unsafe { values[length - 1] }
    mut position := length - 1
    for position > 0 && unsafe { values[position - 1] } > key {
        unsafe { values[position] = values[position - 1] }
        position--
    }
    unsafe { values[position] = key }
}

@[export: 'insertion_sort_recursive']
pub fn insertion_sort_recursive(mut values &i64, length usize) {
    insertion_sort_prefix(mut values, length)
}
