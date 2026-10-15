module jump_game_ii;

const MAX_LENGTH = 1024;

fn long jump_game_ii(long* values, usz length) @export("jump_game_ii") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > (long)length) return -1;
    }
    if (length == 1) return 0;
    usz[MAX_LENGTH] queue;
    usz[MAX_LENGTH] distance;
    bool[MAX_LENGTH] visited;
    for (usz index = 0; index < length; index++) {
        distance[index] = 0;
        visited[index] = false;
    }
    usz head = 0;
    usz tail = 1;
    queue[0] = 0;
    visited[0] = true;
    while (head < tail) {
        usz cell = queue[head++];
        usz farthest = cell + (usz)values[cell];
        if (farthest >= length - 1) return (long)distance[cell] + 1;
        for (usz next = cell + 1; next <= farthest; next++) {
            if (!visited[next]) {
                visited[next] = true;
                distance[next] = distance[cell] + 1;
                queue[tail++] = next;
            }
        }
    }
    return -1;
}
