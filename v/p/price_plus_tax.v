module price_plus_tax

const scale = i64(1_000_000)
const max_price_micro = i64(1_000_000_000_000)
const max_tax_rate_micro = i64(1_000_000)
const max_input_length = usize(3)
const invalid_result = -1.0e300

@[export: 'price_plus_tax']
pub fn price_plus_tax(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 2 || length > max_input_length { return invalid_result }
    price_micro, tax_rate_micro := unsafe { values[0] }, unsafe { values[1] }
    if price_micro < 0 || price_micro > max_price_micro || tax_rate_micro < 0 || tax_rate_micro > max_tax_rate_micro { return invalid_result }
    price := f64(price_micro) / f64(scale)
    tax_rate := f64(tax_rate_micro) / f64(scale)
    return price * (1.0 + tax_rate)
}
