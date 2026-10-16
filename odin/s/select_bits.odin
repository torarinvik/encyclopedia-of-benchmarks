package select_bits

import "core:c"

@(export)
select_bits :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 3 do return -1

    number := values[0]
    if number < 0 || number > 9007199254740991 do return -1

    first := i64(1)
    last := i64(53)
    if length >= 2 do first = values[1]
    if length >= 3 do last = values[2]
    if first < 1 || first > 53 || last < 1 || last > 53 do return -1

    modulus := i64(1) << u32(last)
    return (number % modulus) >> u32(first - 1)
}
