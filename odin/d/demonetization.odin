package demonetization

import "core:c"

MAX_AMOUNT :: 30
MAX_DENOMINATIONS :: 4

ways :: proc "contextless" (amount: i64, input: [^]i64, count: i64) -> i64 {
    if amount < 0 || count < 0 do return 0
    if amount == 0 do return 1
    if count == 0 do return 0
    denomination := input[count + 1]
    return ways(amount, input, count - 1) + ways(amount - denomination, input, count)
}

// Count denomination combinations with the source's recursive recurrence.
@(export)
demonetization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_DENOMINATIONS + 2 do return -1
    amount := input[0]
    count := input[1]
    if amount < -MAX_AMOUNT || amount > MAX_AMOUNT || count < 0 || count > MAX_DENOMINATIONS
        || length != c.size_t(count + 2) do return -1
    for index := i64(0); index < count; index += 1 {
        if input[index + 2] < 1 || input[index + 2] > MAX_AMOUNT do return -1
    }
    return ways(amount, input, count)
}
