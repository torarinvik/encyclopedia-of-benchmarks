package new_man_shanks_prime

MAX_INDEX :: i64(25)
INT32_MIN_VALUE :: i64(-2_147_483_648)
INT32_MAX_VALUE :: i64(2_147_483_647)

// Compare the source recurrence term a[n] with expected; this is not primality testing.
@(export)
new_man_shanks_prime :: proc "c" (n, expected: i64) -> i64 {
    if n < 1 || n > MAX_INDEX || expected < INT32_MIN_VALUE || expected > INT32_MAX_VALUE do return -1
    previous_previous := i32(1)
    previous := i32(1)
    if n == 1 do return if expected == i64(previous) then 1 else 0
    for index in i64(2)..=n {
        current := 2 * previous + previous_previous
        previous_previous = previous
        previous = current
    }
    return if expected == i64(previous) then 1 else 0
}
