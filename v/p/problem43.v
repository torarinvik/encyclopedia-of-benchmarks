module problem43

fn next_permutation(mut digits [10]int) bool {
    mut i := 8
    for i >= 0 && digits[i] >= digits[i+1] { i-- }
    if i < 0 { return false }
    mut j := 9
    for digits[j] <= digits[i] { j-- }
    digits[i], digits[j] = digits[j], digits[i]
    mut left := i+1
    mut right := 9
    for left < right { digits[left], digits[right] = digits[right], digits[left]; left++; right-- }
    return true
}

@[export: 'problem43']
pub fn problem43(n i64) i64 {
    if n != 10 { return -1 }
    mut digits := [10]int{init: 0}
    for i in 0..10 { digits[i] = i }
    divisors := [4]int{7,11,13,17}
    mut total := i64(0)
    mut more := true
    for more {
        if digits[3]%2 == 0 && (digits[2]+digits[3]+digits[4])%3 == 0 && digits[5]%5 == 0 {
            mut valid := true
            for i in 0..4 { if (digits[i+4]*100+digits[i+5]*10+digits[i+6])%divisors[i] != 0 { valid = false } }
            if valid { mut value := i64(0); for digit in digits { value = value*10+i64(digit) }; total += value }
        }
        more = next_permutation(mut digits)
    }
    return total
}
