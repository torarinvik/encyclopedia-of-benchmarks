package present_value_rust

import "core:c"
import "core:math"

MAX_CASH_FLOWS::i64 = 8
MAX_RATE_PPM::i64 = 1_000_000
MAX_CASH_FLOW_MILLI::i64 = 1_000_000
MAX_INPUT_LENGTH::c.size_t = 11
INVALID_RESULT::f64 = -1e300

@(export)
present_value_rust::proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
    count, rate_ppm := values[0], values[1]
    if count < 1 || count > MAX_CASH_FLOWS || length != c.size_t(count + 2) ||
        (rate_ppm != 0 && rate_ppm != MAX_RATE_PPM) do return INVALID_RESULT

    discount_rate := f64(rate_ppm) / 1_000_000.0
    present_value := 0.0
    for index in 0..<count {
        cash_flow_milli := values[c.size_t(index + 2)]
        if cash_flow_milli < -MAX_CASH_FLOW_MILLI || cash_flow_milli > MAX_CASH_FLOW_MILLI || cash_flow_milli % 125 != 0 do return INVALID_RESULT
        cash_flow := f64(cash_flow_milli) / 1_000.0
        present_value += cash_flow / math.pow_f64(1.0 + discount_rate, f64(index))
    }
    return math.round(present_value * 100.0) / 100.0
}
