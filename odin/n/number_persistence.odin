package number_persistence

// Multiplicative persistence for nonnegative Java int inputs.
@(export)
number_persistence :: proc "c" (input_value: i64) -> i64 {
    if input_value < 0 || input_value > 2_147_483_647 do return -1
    input := input_value
    steps := i64(0)
    for input >= 10 {
        product := i64(1)
        remaining := input
        for remaining > 0 {
            product *= remaining % 10
            remaining /= 10
        }
        input = product
        steps += 1
    }
    return steps
}
