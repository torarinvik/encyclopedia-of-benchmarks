package same_value_teleport_bfs

import "core:c"

@(export)
same_value_teleport_bfs :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 65 do return -2
    if input[0] < 1 || input[0] > 64 || int(length) != int(input[0]) + 1 do return -2
    n := int(input[0])
    for i := 0; i < n; i += 1 {
        if input[i + 1] < -64 || input[i + 1] > 64 do return -2
    }
    if n == 1 do return 0

    first: [129]int
    next: [64]int
    queue: [64]int
    distance: [64]int
    for i := 0; i < 129; i += 1 do first[i] = -1
    for i := 0; i < n; i += 1 {
        slot := int(input[i + 1] + 64)
        next[i] = first[slot]
        first[slot] = i
        distance[i] = -1
    }
    front := 0
    back := 1
    queue[0] = 0
    distance[0] = 0
    for front < back {
        index := queue[front]
        front += 1
        if index == n - 1 do return i64(distance[index])
        if index > 0 && distance[index - 1] < 0 {
            distance[index - 1] = distance[index] + 1
            queue[back] = index - 1
            back += 1
        }
        if index + 1 < n && distance[index + 1] < 0 {
            distance[index + 1] = distance[index] + 1
            queue[back] = index + 1
            back += 1
        }
        slot := int(input[index + 1] + 64)
        member := first[slot]
        if member >= 0 {
            first[slot] = -1
            for member >= 0 {
                if distance[member] < 0 {
                    distance[member] = distance[index] + 1
                    queue[back] = member
                    back += 1
                }
                member = next[member]
            }
        }
    }
    return i64(distance[n - 1])
}
