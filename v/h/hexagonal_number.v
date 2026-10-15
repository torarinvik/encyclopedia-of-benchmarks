module hexagonal_number

@[export: 'hexagonal_number']
pub fn hexagonal_number(number i64) i64 {
    if number < 1 || number > 67_108_864 { return -1 }
    return number * (2 * number - 1)
}
