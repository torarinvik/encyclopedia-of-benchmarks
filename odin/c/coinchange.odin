package coinchange

import "core:c"

MAX_AMOUNT :: 30
MAX_COINS :: 8

@(export)
coinchange :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_COINS + 2 do return -1
    amount_value := values[0]
    coin_count_value := values[1]
    if amount_value < 1 || amount_value > MAX_AMOUNT || coin_count_value < 0 || coin_count_value > MAX_COINS do return -1
    amount := int(amount_value)
    coin_count := int(coin_count_value)
    if int(length) != coin_count + 2 do return -1
    for index := 0; index < coin_count; index += 1 {
        if values[index+2] < 1 || values[index+2] > MAX_AMOUNT do return -1
    }

    combinations: [MAX_AMOUNT]i64
    combinations[0] = 1
    for coin_index := 0; coin_index < coin_count; coin_index += 1 {
        coin := int(values[coin_index+2])
        for subtotal := coin; subtotal < amount; subtotal += 1 {
            combinations[subtotal] += combinations[subtotal-coin]
        }
    }
    return combinations[amount-1]
}
