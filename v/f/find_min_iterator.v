module find_min_iterator

@[export: 'find_min_iterator']
pub fn find_min_iterator(input &i64, length usize) i64 {
    if length < 1 || length > 129 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 128 || length != usize(input[0]) + 1 { return -1 }
        count := int(input[0])
        if count == 0 { return -1 }
        mut minimum := i64(2147483647)
        for i in 0 .. count {
            value := input[i + 1]
            if value < 0 || value > 2147483647 { return -1 }
            if value < minimum { minimum = value }
        }
        return minimum
    }
}
