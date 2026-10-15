module keys_and_rooms;

const usz MAX_ROOMS = 1000;
const usz MAX_INPUT_LENGTH = 100001;

// Return whether every room is reachable from room zero.
fn long keys_and_rooms(long* values, usz length) @export("keys_and_rooms") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 2 || (usz)values[0] > MAX_ROOMS) return -1;
    usz room_count = (usz)values[0];
    usz[MAX_ROOMS] starts;
    usz[MAX_ROOMS] degrees;
    usz cursor = 1;

    for (usz room = 0; room < room_count; room++) {
        if (cursor >= length) return -1;
        long count_value = values[cursor];
        cursor++;
        if (count_value < 0 || (usz)count_value > room_count) return -1;
        usz degree = (usz)count_value;
        if (degree > length - cursor) return -1;
        starts[room] = cursor;
        degrees[room] = degree;
        for (usz edge = 0; edge < degree; edge++) {
            long key = values[cursor + edge];
            if (key < 0 || (usz)key >= room_count) return -1;
        }
        cursor += degree;
    }
    if (cursor != length) return -1;

    bool[MAX_ROOMS] visited;
    usz[MAX_ROOMS] stack;
    for (usz room = 0; room < room_count; room++) visited[room] = false;
    usz stack_size = 1;
    usz reached = 0;
    stack[0] = 0;
    visited[0] = true;
    while (stack_size > 0) {
        stack_size--;
        usz room = stack[stack_size];
        reached++;
        for (usz edge = 0; edge < degrees[room]; edge++) {
            usz key = (usz)values[starts[room] + edge];
            if (!visited[key]) {
                visited[key] = true;
                stack[stack_size] = key;
                stack_size++;
            }
        }
    }
    return reached == room_count ? 1 : 0;
}
