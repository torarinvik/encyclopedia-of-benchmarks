module dudeney_number

@[export: 'dudeney_number']
pub fn dudeney_number(number i64) i64 {
    if number <= 0 || number > 2147483647 { return -1 }
    mut low := i64(1)
    mut high := i64(1290)
    mut root := i64(0)
    for low <= high {
        middle := low + (high - low) / 2
        cube := middle * middle * middle
        if cube == number { root = middle; break }
        if cube < number { low = middle + 1 } else { high = middle - 1 }
    }
    if root == 0 { return 0 }
    mut remaining := number
    mut sum := i64(0)
    for remaining > 0 {
        sum += remaining % 10
        remaining /= 10
    }
    if sum == root { return 1 }
    return 0
}
