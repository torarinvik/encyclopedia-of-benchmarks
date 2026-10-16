package partition_problem

import "core:c"

MAX_ITEMS :: 16
MAX_TOTAL :: 1024

@(export)
partition_problem :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 || length > MAX_ITEMS do return -1
    total: i64 = 0
    for index: c.size_t = 0; index < length; index += 1 {
        value := input[index]
        if value < 0 || value > 256 || total > MAX_TOTAL - value do return -1
        total += value
    }
    if (total & 1) != 0 do return 0
    target := int(total / 2)
    reachable: [MAX_TOTAL + 1]bool
    reachable[0] = true
    for index: c.size_t = 0; index < length; index += 1 {
        value := int(input[index])
        if value <= target {
            for sum := target; sum >= value; {
                if reachable[sum - value] do reachable[sum] = true
                if sum == value do break
                sum -= 1
            }
        }
    }
    return i64(reachable[target])
}
