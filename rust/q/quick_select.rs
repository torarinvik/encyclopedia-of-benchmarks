const MAX_VALUES: usize = 1024;

fn median_of_three(first: i64, middle: i64, last: i64) -> i64 {
    if first < middle {
        if middle < last { return middle; }
        if first < last { return last; }
        return first;
    }
    if first < last { return first; }
    if middle < last { return last; }
    middle
}

#[no_mangle]
pub unsafe extern "C" fn quick_select(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_VALUES { return -1; }
    let mut scratch = [0_i64; MAX_VALUES];
    for index in 0..length { scratch[index] = *values.add(index); }

    let target = length / 2;
    let mut low = 0;
    let mut high = length;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        let pivot = median_of_three(scratch[low], scratch[middle], scratch[high - 1]);
        let mut less = low;
        let mut scan = low;
        let mut greater = high;
        while scan < greater {
            if scratch[scan] < pivot {
                scratch.swap(less, scan);
                less += 1;
                scan += 1;
            } else if scratch[scan] > pivot {
                greater -= 1;
                scratch.swap(scan, greater);
            } else {
                scan += 1;
            }
        }
        if target < less { high = less; }
        else if target >= greater { low = greater; }
        else { return pivot; }
    }
    scratch[target]
}
