package binary_cross_entropy
import "core:c"
import "core:math"
INVALID_RESULT :: f64(-1.0e300)
@(export)
binary_cross_entropy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 1 || length > c.size_t(513) do return INVALID_RESULT
    count_value := values[0]
    if count_value < 1 || count_value > 256 || length != c.size_t(1 + 2 * count_value) do return INVALID_RESULT
    count := int(count_value)
    for index := 0; index < count; index += 1 {
        label := values[1 + index]
        probability := values[1 + count + index]
        if (label != 0 && label != 1) || probability < 0 || probability > 1_000_000 do return INVALID_RESULT
    }
    total := f64(0.0)
    for index := 0; index < count; index += 1 {
        label := f64(values[1 + index])
        probability := f64(values[1 + count + index]) / 1_000_000.0
        if probability < 1e-15 do probability = 1e-15
        if probability > 1.0 - 1e-15 do probability = 1.0 - 1e-15
        total -= label * math.log_f64(probability) + (1.0 - label) * math.log_f64(1.0 - probability)
    }
    return total / f64(count)
}
