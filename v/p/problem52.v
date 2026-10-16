module problem52

fn digit_counts(mut value i64) [10]int {
    mut counts := [10]int{}
    for value > 0 { counts[value % 10]++; value /= 10 }
    return counts
}
fn same_digits(left i64, right i64) bool { return digit_counts(left) == digit_counts(right) }

@[export: 'problem52']
pub fn problem52(unused i64) i64 {
    if unused != 0 { return -1 }
    mut value := i64(1)
    for {
        mut matches := true
        for multiplier in 2..7 { if !same_digits(value, value * multiplier) { matches = false } }
        if matches { return value }
        value++
    }
    return -1
}
