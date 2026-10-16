// Count values through limit with exactly ten valid arithmetic-progression solutions.
module problem135

const max_limit = i64(1000000)

@[export: 'problem135']
pub fn problem135(limit i64) i64 {
    if limit > max_limit { return -1 }
    if limit < 0 { return 0 }
    mut frequency := [1000001]u8{}
    mut first_term := i64(1)
    for first_term <= limit {
        mut n := first_term
        for n <= limit {
            mut common_difference := first_term + n / first_term
            if common_difference % 4 == 0 {
                common_difference /= 4
                if first_term > common_difference && first_term < 4 * common_difference {
                    index := int(n)
                    if frequency[index] < 11 { frequency[index]++ }
                }
            }
            n += first_term
        }
        first_term++
    }
    mut count := i64(0)
    for n := i64(1); n <= limit; n++ {
        if frequency[int(n)] == 10 { count++ }
    }
    return count
}
