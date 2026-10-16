package price_plus_tax
import "core:c"

SCALE::i64 = 1_000_000
MAX_PRICE_MICRO::i64 = 1_000_000_000_000
MAX_TAX_RATE_MICRO::i64 = 1_000_000
MAX_INPUT_LENGTH::c.size_t = 3
INVALID_RESULT::f64 = -1e300

@(export)
price_plus_tax::proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
    price_micro, tax_rate_micro := values[0], values[1]
    if price_micro < 0 || price_micro > MAX_PRICE_MICRO || tax_rate_micro < 0 || tax_rate_micro > MAX_TAX_RATE_MICRO do return INVALID_RESULT
    price := f64(price_micro) / f64(SCALE)
    tax_rate := f64(tax_rate_micro) / f64(SCALE)
    return price * (1.0 + tax_rate)
}
