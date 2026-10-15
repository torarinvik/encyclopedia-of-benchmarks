package dudeney_number

@(export)
dudeney_number :: proc "c" (number: i64) -> i64 {
    if number <= 0 || number > 2_147_483_647 do return -1
    low := i64(1)
    high := i64(1290)
    root := i64(0)
    for low <= high {
        middle := low + (high - low) / 2
        cube := middle * middle * middle
        if cube == number { root = middle; break }
        if cube < number do low = middle + 1
        else do high = middle - 1
    }
    if root == 0 do return 0
    remaining := number
    sum := i64(0)
    for remaining > 0 {
        sum += remaining % 10
        remaining /= 10
    }
    if sum == root do return 1
    return 0
}
