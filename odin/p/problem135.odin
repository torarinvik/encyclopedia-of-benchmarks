// Count values through limit with exactly ten valid arithmetic-progression solutions.
package problem135

MAX_LIMIT :: i64(1_000_000)

@(export)
problem135 :: proc "c" (limit: i64) -> i64 {
    if limit > MAX_LIMIT do return -1
    if limit < 0 do return 0
    frequency: [1_000_001]u8 = {}
    for first_term := i64(1); first_term <= limit; first_term += 1 {
        for n := first_term; n <= limit; n += first_term {
            common_difference := first_term + n / first_term
            if common_difference % 4 != 0 do continue
            common_difference /= 4
            index := usz(n)
            if first_term > common_difference && first_term < 4 * common_difference && frequency[index] < 11 {
                frequency[index] += 1
            }
        }
    }
    count: i64 = 0
    for n := i64(1); n <= limit; n += 1 {
        if frequency[usz(n)] == 10 { count += 1 }
    }
    return count
}
