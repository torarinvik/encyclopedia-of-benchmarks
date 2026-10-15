module average_absolute_deviation_rounded
const max_length = 256
const min_value = i64(-2_147_483_648)
const max_value = i64(2_147_483_647)
fn round_ties_even(value f64) f64 {
    lower := math.floor(value)
    fraction := value - lower
    if fraction < 0.5 { return lower }
    if fraction > 0.5 { return lower + 1.0 }
    if i64(lower) % 2 == 0 { return lower }
    return lower + 1.0
}

const invalid_result = -1.0e300
@[export: 'average_absolute_deviation_rounded']
pub fn average_absolute_deviation_rounded(values &i64, length usize) f64 {
    if length == 0 || length > max_length { return invalid_result }
    mut sum := 0.0
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < min_value || value > max_value { return invalid_result }
        sum += f64(value)
    }
    average := sum / f64(length)
    mut deviations := 0.0
    for index in 0 .. length {
        value := f64(unsafe { values[index] })
        deviations += if value >= average { value - average } else { average - value }
    }
    return round_ties_even((deviations / f64(length)) * 100.0) / 100.0
}
