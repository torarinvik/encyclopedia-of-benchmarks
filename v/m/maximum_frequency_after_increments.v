module maximum_frequency_after_increments

// Sort values and grow the longest affordable window.
@[export: 'maximum_frequency_after_increments']
pub fn maximum_frequency_after_increments(input &i64, length usize) i64 {
    if length < 1 || length > 257 { return -1 }
    unsafe {
        budget := input[0]
        count := int(length - 1)
        if budget < 0 || budget > 1_000_000 { return -1 }
        mut values := [256]i64{}
        for index in 0 .. count {
            value := input[index + 1]
            if value < 1 || value > 10_000 { return -1 }
            mut position := index
            for position > 0 && values[position - 1] > value {
                values[position] = values[position - 1]
                position--
            }
            values[position] = value
        }
        mut left := 0
        mut window_sum := i64(0)
        mut best := 0
        for right in 0 .. count {
            window_sum += values[right]
            for values[right] * i64(right - left + 1) - window_sum > budget {
                window_sum -= values[left]
                left++
            }
            window_length := right - left + 1
            if window_length > best { best = window_length }
        }
        return i64(best)
    }
}
