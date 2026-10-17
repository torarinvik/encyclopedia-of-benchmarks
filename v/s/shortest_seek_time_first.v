const max_requests = 64

@[export: 'shortest_seek_time_first']
pub fn shortest_seek_time_first(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > usize(2 + max_requests) { return -1 }
        initial_track := values[0]
        request_count := values[1]
        if initial_track < 0 || initial_track > 255 || request_count < 0 || request_count > i64(max_requests) ||
            length != usize(2 + request_count) { return -1 }
        for i := 0; i < int(request_count); i++ {
            request := values[2 + i]
            if request < 0 || request > 255 { return -1 }
        }
        if output == nil || output_capacity < usize(request_count) { return -2 }

        mut serviced := [64]bool{}
        mut current := initial_track
        for step := 0; step < int(request_count); step++ {
            mut best := max_requests
            mut best_distance := i64(256)
            for i := 0; i < int(request_count); i++ {
                if serviced[i] { continue }
                mut distance := current - values[2 + i]
                if distance < 0 { distance = -distance }
                if distance < best_distance { best = i; best_distance = distance }
            }
            selected := values[2 + best]
            output[step] = u8(selected)
            serviced[best] = true
            current = selected
        }
        return request_count
    }
}
