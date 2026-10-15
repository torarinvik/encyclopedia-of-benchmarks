module minimum_deletions_balanced

// Minimum deletions to leave all a values before all b values.
@[export: 'minimum_deletions_to_make_string_balanced']
pub fn minimum_deletions_to_make_string_balanced(values &i64, length usize) i64 {
    if length > 256 { return -1 }
    if length == 0 { return 0 }
    unsafe {
        mut a_state := i64(0)
        mut b_state := i64(0)
        for index in 0 .. length {
            value := values[index]
            if value < 0 || value > 1 { return -1 }
            next_a := a_state + (if value == 1 { i64(1) } else { i64(0) })
            b_with_a := b_state + (if value == 0 { i64(1) } else { i64(0) })
            mut next_b := a_state
            if b_with_a < next_b { next_b = b_with_a }
            a_state = next_a
            b_state = next_b
        }
        return if a_state < b_state { a_state } else { b_state }
    }
}
