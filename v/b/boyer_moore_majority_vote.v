module boyer_moore_majority_vote

// Return a strict majority element, or -1 if none exists.
@[export: 'boyer_moore_majority_vote']
pub fn boyer_moore_majority_vote(values &i64, length usize) i64 {
    if length < 1 || length > 256 { return -1 }
    unsafe {
        mut candidate := i64(0)
        mut balance := 0
        for index in 0 .. length {
            value := values[index]
            if balance == 0 { candidate = value }
            if value == candidate { balance++ } else { balance-- }
        }
        mut occurrences := 0
        for index in 0 .. length {
            if values[index] == candidate { occurrences++ }
        }
        if occurrences > int(length) / 2 { return candidate }
        return -1
    }
}
