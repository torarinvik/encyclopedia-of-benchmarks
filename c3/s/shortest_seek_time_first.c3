module shortest_seek_time_first;
const usz MAX_REQUESTS = 64;

fn long shortest_seek_time_first(long* values, usz length, char* output, usz output_capacity)
    @export("shortest_seek_time_first") {
    if (values == null || length < 2 || length > 2 + MAX_REQUESTS) return -1;
    long initial_track = values[0];
    long request_count = values[1];
    if (initial_track < 0 || initial_track > 255 || request_count < 0 ||
        request_count > (long)MAX_REQUESTS || length != 2 + (usz)request_count) return -1;
    for (usz i = 0; i < (usz)request_count; i += 1)
        if (values[2 + i] < 0 || values[2 + i] > 255) return -1;
    if (output == null || output_capacity < (usz)request_count) return -2;

    bool[MAX_REQUESTS] serviced = {};
    long current = initial_track;
    for (usz step = 0; step < (usz)request_count; step += 1) {
        usz best = MAX_REQUESTS;
        long best_distance = 256;
        for (usz i = 0; i < (usz)request_count; i += 1) {
            if (serviced[i]) continue;
            long distance = current - values[2 + i];
            if (distance < 0) distance = -distance;
            if (distance < best_distance) { best = i; best_distance = distance; }
        }
        long selected = values[2 + best];
        output[step] = (char)selected;
        serviced[best] = true;
        current = selected;
    }
    return request_count;
}
