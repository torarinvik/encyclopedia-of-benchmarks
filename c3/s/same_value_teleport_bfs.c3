module same_value_teleport_bfs;

fn long same_value_teleport_bfs(long* input, usz length) @export("same_value_teleport_bfs") {
    if (input == null || length < 2 || length > 65 || input[0] < 1 || input[0] > 64 || length != (usz)input[0] + 1) return -2;
    usz n = (usz)input[0];
    for (usz i = 0; i < n; i++) if (input[i + 1] < -64 || input[i + 1] > 64) return -2;
    if (n == 1) return 0;

    i32[129] first;
    i32[64] next;
    i32[64] queue;
    i32[64] distance;
    for (usz i = 0; i < 129; i++) first[i] = -1;
    for (usz i = 0; i < n; i++) {
        usz slot = (usz)(input[i + 1] + 64);
        next[i] = first[slot];
        first[slot] = (i32)i;
        distance[i] = -1;
    }
    usz front = 0, back = 1;
    queue[0] = 0;
    distance[0] = 0;
    while (front < back) {
        usz index = (usz)queue[front];
        front++;
        if (index == n - 1) return (long)distance[index];
        if (index > 0 && distance[index - 1] < 0) {
            distance[index - 1] = distance[index] + 1;
            queue[back] = (i32)(index - 1);
            back++;
        }
        if (index + 1 < n && distance[index + 1] < 0) {
            distance[index + 1] = distance[index] + 1;
            queue[back] = (i32)(index + 1);
            back++;
        }
        usz slot = (usz)(input[index + 1] + 64);
        i32 member = first[slot];
        if (member >= 0) {
            first[slot] = -1;
            while (member >= 0) {
                usz member_index = (usz)member;
                if (distance[member_index] < 0) {
                    distance[member_index] = distance[index] + 1;
                    queue[back] = member;
                    back++;
                }
                member = next[member_index];
            }
        }
    }
    return (long)distance[n - 1];
}
