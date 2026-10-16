package egg_dropping_puzzle

import "core:c"

MAX_EGGS :: 8
MAX_FLOORS :: 32

@(export)
egg_dropping_puzzle :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != c.size_t(2) do return -1
    eggs_value := input[0]
    floors_value := input[1]
    if eggs_value < 1 || eggs_value > MAX_EGGS || floors_value < 1 || floors_value > MAX_FLOORS do return -1

    eggs := int(eggs_value)
    floors := int(floors_value)
    dp: [MAX_EGGS + 1][MAX_FLOORS + 1]i64
    for egg := 1; egg <= eggs; egg += 1 { dp[egg][1] = 1 }
    for floor_count := 1; floor_count <= floors; floor_count += 1 { dp[1][floor_count] = i64(floor_count) }

    for egg := 2; egg <= eggs; egg += 1 {
        for floor_count := 2; floor_count <= floors; floor_count += 1 {
            best := i64(MAX_FLOORS + 1)
            for drop_floor := 1; drop_floor <= floor_count; drop_floor += 1 {
                broken := dp[egg - 1][drop_floor - 1]
                survives := dp[egg][floor_count - drop_floor]
                worst := broken
                if survives > worst { worst = survives }
                candidate := worst + 1
                if candidate < best { best = candidate }
            }
            dp[egg][floor_count] = best
        }
    }
    return dp[eggs][floors]
}
