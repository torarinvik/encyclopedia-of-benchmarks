package problem43

next_permutation :: proc(digits: ^[10]int) -> bool {
    i := 8
    for i >= 0 && digits[i] >= digits[i+1] { i -= 1 }
    if i < 0 do return false
    j := 9
    for digits[j] <= digits[i] { j -= 1 }
    digits[i], digits[j] = digits[j], digits[i]
    left, right := i+1, 9
    for left < right { digits[left], digits[right] = digits[right], digits[left]; left += 1; right -= 1 }
    return true
}

@(export)
problem43 :: proc "c" (n: i64) -> i64 {
    if n != 10 do return -1
    digits := [10]int{0,1,2,3,4,5,6,7,8,9}
    divisors := [4]int{7,11,13,17}
    total: i64 = 0
    more := true
    for more {
        if digits[3]%2 == 0 && (digits[2]+digits[3]+digits[4])%3 == 0 && digits[5]%5 == 0 {
            valid := true
            for i in 0..<4 { if (digits[i+4]*100+digits[i+5]*10+digits[i+6])%divisors[i] != 0 do valid = false }
            if valid { value: i64 = 0; for digit in digits { value = value*10+i64(digit) }; total += value }
        }
        more = next_permutation(&digits)
    }
    return total
}
