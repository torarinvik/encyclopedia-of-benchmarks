module find_min_rotated_sorted_array

// Return the minimum in a rotation of a strictly increasing i64 array.
@[export: 'find_min_rotated_sorted_array']
pub fn find_min_rotated_sorted_array(values &i64, length usize) i64 {
    if length < 1 || length > 256 { return -1 }
    unsafe {
        mut low := 0
        mut high := int(length - 1)
        for low < high {
            middle := low + (high - low) / 2
            if values[middle] <= values[high] { high = middle }
            else { low = middle + 1 }
        }
        return values[low]
    }
}
