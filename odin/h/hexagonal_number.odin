package hexagonal_number

@(export)
hexagonal_number :: proc "c" (number: i64) -> i64 {
    if number < 1 || number > 67_108_864 do return -1
    return number * (2 * number - 1)
}
