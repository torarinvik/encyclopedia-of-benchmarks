module pairs_with_given_sum

@[export: 'pairs_with_given_sum']
pub fn pairs_with_given_sum(input &i64, length usize) i64 {
    if length == 0 || length > 257 {
        return -2
    }
    unsafe {
        if input == nil {
            return -2
        }
        for index in 0 .. length {
            if input[index] < i64(-2147483647) - 1 || input[index] > i64(2147483647) {
                return -2
            }
        }
        target := input[0]
        value_count := length - 1
        mut pairs := i64(0)
        mut left := usize(0)
        for left < value_count {
            mut right := left + 1
            for right < value_count {
                if input[left + 1] + input[right + 1] == target {
                    pairs++
                }
                right++
            }
            left++
        }
        return pairs
    }
}
