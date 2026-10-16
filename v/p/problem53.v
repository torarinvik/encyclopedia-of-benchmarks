module problem53

@[export: 'problem53']
pub fn problem53(unused i64) i64 {
    if unused != 0 { return -1 }
    mut total := i64(0)
    for n in 1..101 {
        mut coefficient := i64(1)
        for r in 1..(n/2 + 1) {
            coefficient = coefficient * (n-r+1) / r
            if coefficient > 1000000 { total += n-2*r+1; break }
        }
    }
    return total
}
