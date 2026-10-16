package categorical_cross_entropy
import "core:c"
import "core:math"
INVALID_RESULT :: f64(-1.0e300)
@(export)
categorical_cross_entropy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 2 || length > c.size_t(2050) do return INVALID_RESULT
    batch_value, classes_value := values[0], values[1]
    if batch_value < 1 || batch_value > 64 || classes_value < 2 || classes_value > 16 do return INVALID_RESULT
    batch, class_count := int(batch_value), int(classes_value)
    cells := batch * class_count
    if length != c.size_t(2 + 2 * cells) do return INVALID_RESULT
    for row := 0; row < batch; row += 1 {
        label_sum, probability_sum := i64(0), i64(0)
        for column := 0; column < class_count; column += 1 {
            index := row * class_count + column
            label := values[2 + index]
            probability := values[2 + cells + index]
            if label != 0 && label != 1 do return INVALID_RESULT
            if probability < 0 || probability > 1_000_000 do return INVALID_RESULT
            label_sum += label
            probability_sum += probability
        }
        if label_sum != 1 || probability_sum != 1_000_000 do return INVALID_RESULT
    }
    total := f64(0.0)
    for row := 0; row < batch; row += 1 {
        row_loss := f64(0.0)
        for column := 0; column < class_count; column += 1 {
            index := row * class_count + column
            label := f64(values[2 + index])
            probability := f64(values[2 + cells + index]) / 1_000_000.0
            p := probability
            if p < 1e-15 do p = 1e-15
            if p > 1.0 do p = 1.0
            row_loss -= label * math.log_f64(p)
        }
        total += row_loss
    }
    return total
}
