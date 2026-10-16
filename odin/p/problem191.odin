package problem191

@(export)
problem191 :: proc "c" (days: i64) -> i64 {
    if days < 0 || days > 65 do return -1
    ways: [396]i64
    for absent := 0; absent <= 1; absent += 1 {
        for late := 0; late <= 2; late += 1 { ways[absent * 3 + late] = 1 }
    }
    for remaining := i64(1); remaining <= days; remaining += 1 {
        for absent := 0; absent <= 1; absent += 1 {
            for late := 0; late <= 2; late += 1 {
                previous := int((remaining - 1) * 6)
                late_state := i64(0)
                if late < 2 { late_state = ways[previous + absent * 3 + late + 1] }
                absent_state := i64(0)
                if absent == 0 { absent_state = ways[previous + 3] }
                on_time_state := ways[previous + absent * 3]
                ways[int(remaining * 6) + absent * 3 + late] = late_state + absent_state + on_time_state
            }
        }
    }
    return ways[int(days * 6)]
}
