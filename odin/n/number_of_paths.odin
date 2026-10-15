package number_of_paths

import "core:c"

// Count vertex-simple directed paths with recursive DFS.
count_from :: proc(values: [^]i64, n, current, destination: u32, visited: u32) -> u32 {
    if current == destination do return 1
    seen := visited | (u32(1) << current)
    count := u32(0)
    for next := u32(0); next < n; next += 1 {
        if values[3 + current * n + next] == 1 && (seen & (u32(1) << next)) == 0 {
            count += count_from(values, n, next, destination, seen)
        }
    }
    return count
}

@(export)
number_of_paths :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || values[0] < 1 || values[0] > 10 do return -1
    n := u32(values[0])
    if length != c.size_t(3 + n * n) do return -1
    if values[1] < 0 || values[1] > i64(max(u32)) || values[2] < 0 || values[2] > i64(max(u32)) do return -1
    for i := c.size_t(3); i < length; i += 1 {
        if values[i] != 0 && values[i] != 1 do return -1
    }
    source, destination := u32(values[1]), u32(values[2])
    if source >= n || destination >= n do return 0
    return i64(count_from(values, n, source, destination, 0))
}
