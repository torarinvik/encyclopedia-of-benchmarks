module narcissistic_number

// Enumerate narcissistic numbers below limit, memoizing digit powers.
@[export: 'narcissistic_number']
pub fn narcissistic_number(limit i64, output &u8, output_capacity usize) i64 {
    if limit > 100000 { return -1 }
    if limit <= 0 { return 0 }
    mut numbers := [32]i64{}
    mut powers := [60]i64{}
    mut cached := [60]bool{}
    mut count := usize(0)
    mut number := i64(0)
    for number < limit {
        mut digits := 1
        mut remaining := number
        for remaining >= 10 {
            remaining /= 10
            digits++
        }
        mut sum := i64(0)
        remaining = number
        for remaining > 0 {
            digit := int(remaining % 10)
            key := digits * 10 + digit
            if !cached[key] {
                mut power := i64(1)
                for _ in 0 .. digits { power *= i64(digit) }
                powers[key] = power
                cached[key] = true
            }
            sum += powers[key]
            remaining /= 10
        }
        if sum == number {
            if count == 32 { return -1 }
            numbers[count] = number
            count++
        }
        number++
    }
    required := count * 8
    if required == 0 { return 0 }
    if output_capacity < required { return -2 }
    mut position := usize(0)
    for item in 0 .. count {
        value := u64(numbers[item])
        for byte in 0 .. 8 {
            shift := (7 - byte) * 8
            unsafe { output[position] = u8(value >> shift) }
            position++
        }
    }
    return i64(required)
}
