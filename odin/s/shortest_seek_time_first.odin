package shortest_seek_time_first
import "core:c"

MAX_REQUESTS :: 64

@(export)
shortest_seek_time_first :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 2 + MAX_REQUESTS do return -1
    initial_track := values[0]
    request_count := values[1]
    if initial_track < 0 || initial_track > 255 || request_count < 0 || request_count > MAX_REQUESTS do return -1
    if length != c.size_t(2 + request_count) do return -1
    for i in 0..<int(request_count) {
        request := values[2 + i]
        if request < 0 || request > 255 do return -1
    }
    if output == nil || output_capacity < c.size_t(request_count) do return -2

    serviced: [MAX_REQUESTS]bool = {}
    current := initial_track
    for step in 0..<int(request_count) {
        best := MAX_REQUESTS
        best_distance: i64 = 256
        for i in 0..<int(request_count) {
            if serviced[i] do continue
            distance := current - values[2 + i]
            if distance < 0 do distance = -distance
            if distance < best_distance { best = i; best_distance = distance }
        }
        selected := values[2 + best]
        output[step] = u8(selected)
        serviced[best] = true
        current = selected
    }
    return request_count
}
