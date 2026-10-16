module problem301

@[export: 'problem301']
pub fn problem301(exponent i64) i64 {
    if exponent < 0 || exponent > 30 { return -1 }
    mut previous := i64(0)
    mut current := i64(1)
    for _ in 0 .. int(exponent + 2) {
        next := previous + current
        previous = current
        current = next
    }
    return previous - exponent % 2
}
