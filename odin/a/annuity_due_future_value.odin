package annuity_due_future_value

import "core:math"

// Future value of an annuity due using the pinned source formula.
@(export)
annuity_due_future_value :: proc "c" (payment, periods, rate: f64) -> f64 {
    annuity_factor := (math.pow_f64(1.0 + rate, periods) - 1.0) / rate
    return payment * annuity_factor * (1.0 + rate)
}
