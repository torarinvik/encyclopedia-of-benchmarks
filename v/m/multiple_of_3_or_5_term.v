module multiple_of_3_or_5_term

@[export: 'multiple_of_3_or_5_term']
pub fn multiple_of_3_or_5_term(n i64) i64 {
    if n < 0 || n > 1_000_000_000 { return -1 }
    if n % 3 == 0 || n % 5 == 0 { return n }
    return 0
}
