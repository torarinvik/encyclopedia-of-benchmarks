package problem56

multiply_digits :: proc(digits: ^[512]int, length, factor: int) -> int {
    carry := 0
    count := length
    for i := 0; i < length; i += 1 { value := digits[i]*factor+carry; digits[i] = value%10; carry = value/10 }
    for carry > 0 { digits[count] = carry%10; count += 1; carry /= 10 }
    return count
}

@(export)
problem56 :: proc "c" (a, b: i64) -> i64 {
    if a < 1 || a > 200 || b < 1 || b > 200 do return -1
    best := i64(0)
    for base := 0; base < int(a); base += 1 {
        digits: [512]int
        digits[0] = 1
        length := 1
        for power := 0; power < int(b); power += 1 {
            sum := i64(0)
            for i := 0; i < length; i += 1 { sum += i64(digits[i]) }
            if sum > best do best = sum
            if power + 1 < int(b) do length = multiply_digits(&digits, length, base)
        }
    }
    return best
}
