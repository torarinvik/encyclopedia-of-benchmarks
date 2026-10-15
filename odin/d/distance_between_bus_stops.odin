package distance_between_bus_stops

import "core:c"

// Sum both circular routes and return the shorter one.
@(export)
distance_between_bus_stops :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 3 || length > 66 do return -1
    stop_count := int(length) - 2
    start_value := input[0]
    destination_value := input[1]
    if start_value < 0 || destination_value < 0 || start_value >= i64(stop_count) || destination_value >= i64(stop_count) do return -1

    start := int(start_value)
    destination := int(destination_value)
    low := min(start, destination)
    high := max(start, destination)
    total := i64(0)
    direct := i64(0)
    for index := 0; index < stop_count; index += 1 {
        distance := input[index + 2]
        if distance < 0 || distance > 1_000_000 do return -1
        total += distance
        if index >= low && index < high do direct += distance
    }
    other := total - direct
    return min(direct, other)
}
