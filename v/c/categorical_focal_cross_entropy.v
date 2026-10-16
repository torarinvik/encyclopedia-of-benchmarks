module categorical_focal_cross_entropy
import math
const invalid_result = -1.0e300
@[export: 'categorical_focal_cross_entropy']
pub fn categorical_focal_cross_entropy(values &i64, length usize) f64 {
    if unsafe { values == nil } || length < 2 || length > 2050 { return invalid_result }
    batch_value := unsafe { values[0] }
    classes_value := unsafe { values[1] }
    if batch_value < 1 || batch_value > 64 || classes_value < 2 || classes_value > 16 { return invalid_result }
    batch, classes := int(batch_value), int(classes_value)
    cells := batch * classes
    if length != 2 + 2 * cells { return invalid_result }
    for row in 0 .. batch {
        mut label_sum := i64(0)
        mut probability_sum := i64(0)
        for column in 0 .. classes {
            index := row * classes + column
            label := unsafe { values[2 + index] }
            probability := unsafe { values[2 + cells + index] }
            if label != 0 && label != 1 { return invalid_result }
            if probability < 0 || probability > 1_000_000 { return invalid_result }
            label_sum += label
            probability_sum += probability
        }
        if label_sum != 1 || probability_sum != 1_000_000 { return invalid_result }
    }
    mut total := 0.0
    for row in 0 .. batch {
        mut row_loss := 0.0
        for column in 0 .. classes {
            index := row * classes + column
            label := f64(unsafe { values[2 + index] })
            mut probability := f64(unsafe { values[2 + cells + index] }) / 1_000_000.0
            if probability < 1e-15 { probability = 1e-15 }
            if probability > 1.0 - 1e-15 { probability = 1.0 - 1e-15 }
            negative_probability := 1.0 - probability
            row_loss -= negative_probability * negative_probability * label * math.log(probability)
        }
        total += row_loss
    }
    return total / f64(batch)
}
