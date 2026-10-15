package maximum_ice_cream_bars

import "core:c"

// Buy the largest affordable prefix after sorting the prices.
@(export)
maximum_ice_cream_bars :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 257 do return -1
    coins := input[0]
    count := int(length - 1)
    if coins < 0 || coins > 1_000_000 do return -1
    costs: [256]i64 = {}
    for index := 0; index < count; index += 1 {
        cost := input[index + 1]
        if cost < 1 || cost > 10_000 do return -1
        position := index
        for position > 0 && costs[position - 1] > cost {
            costs[position] = costs[position - 1]
            position -= 1
        }
        costs[position] = cost
    }
    bought := i64(0)
    remaining := coins
    for index := 0; index < count; index += 1 {
        if costs[index] > remaining do break
        remaining -= costs[index]
        bought += 1
    }
    return bought
}
