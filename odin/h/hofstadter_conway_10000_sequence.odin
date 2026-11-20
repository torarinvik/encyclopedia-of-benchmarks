package hofstadter_conway_10000_sequence

import "core:c"

MAX_INDEX :: i64(8192)
MAX_PARSEABLE_LENGTH :: 2

@(export)
hofstadter_conway_10000_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    if length != 1 || input[0] < 2 || input[0] > MAX_INDEX do return -1

    target := int(input[0])
    a: [8193]i64 = {}
    a[1] = 1
    a[2] = 1
    for n := 3; n <= target; n += 1 {
        previous := a[n - 1]
        other := i64(n) - previous
        if previous < 1 || previous >= i64(n) || other < 1 || other >= i64(n) do return -1
        a[n] = a[int(previous)] + a[int(other)]
    }
    return a[target]
}
