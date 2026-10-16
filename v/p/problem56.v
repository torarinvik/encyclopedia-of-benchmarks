module problem56

fn multiply_digits(mut digits [512]int, length int, factor int) int {
    mut carry := 0
    mut count := length
    for i in 0 .. length { value := digits[i]*factor+carry; digits[i] = value%10; carry = value/10 }
    for carry > 0 { digits[count] = carry%10; count++; carry /= 10 }
    return count
}

@[export: 'problem56']
pub fn problem56(a i64, b i64) i64 {
    if a < 1 || a > 200 || b < 1 || b > 200 { return -1 }
    mut best := i64(0)
    for base in 0 .. int(a) {
        mut digits := [512]int{}
        digits[0] = 1
        mut length := 1
        for power in 0 .. int(b) {
            mut sum := i64(0)
            for i in 0 .. length { sum += i64(digits[i]) }
            if sum > best { best = sum }
            if power + 1 < int(b) { length = multiply_digits(mut digits, length, base) }
        }
    }
    return best
}
