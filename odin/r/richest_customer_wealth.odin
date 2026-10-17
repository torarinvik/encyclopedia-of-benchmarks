package richest_customer_wealth

import "core:c"

MAX_ROWS :: 32
MAX_COLUMNS :: 32
MAX_INPUT_LENGTH :: 1027
MAX_AMOUNT :: i64(1_000_000)

@(export, link_name="richest_customer_wealth")
richest_customer_wealth :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS do return -1
    rows, columns := int(input[0]), int(input[1])
    if length != c.size_t(2 + rows * columns) do return -1
    richest := i64(0)
    for row := 0; row < rows; row += 1 {
        wealth := i64(0)
        for column := 0; column < columns; column += 1 {
            amount := input[2 + row * columns + column]
            if amount < 0 || amount > MAX_AMOUNT do return -1
            wealth += amount
        }
        if wealth > richest do richest = wealth
    }
    return richest
}
