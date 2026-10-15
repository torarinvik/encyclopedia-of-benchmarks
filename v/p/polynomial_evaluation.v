module polynomial_evaluation

const invalid_result = i64(-9223372036854775807 - 1)

// Bounded integer port of the pinned floating-point Horner routine.
@[export: 'polynomial_evaluation']
pub fn polynomial_evaluation(values &i64, length usize) i64 {
    if length < 2 || length > 10 { return invalid_result }
    count := unsafe { values[0] }
    x := unsafe { values[1] }
    if count < 0 || count > 8 || length != usize(count + 2) { return invalid_result }
    if x < -10 || x > 10 { return invalid_result }
    for index in 0 .. int(count) {
        coefficient := unsafe { values[index + 2] }
        if coefficient < -1000 || coefficient > 1000 { return invalid_result }
    }
    mut result := i64(0)
    mut index := int(count)
    for index > 0 {
        index--
        result = result * x + unsafe { values[index + 2] }
    }
    return result
}
