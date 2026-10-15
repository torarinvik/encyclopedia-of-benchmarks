/// Breadth-first search over forward-reachable indices.
const MAX_LENGTH: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn jump_game_ii(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if value < 0 || value > length as i64 { return -1; }
    }
    if length == 1 { return 0; }
    let mut queue = [0usize; MAX_LENGTH];
    let mut distance = [0usize; MAX_LENGTH];
    let mut visited = [false; MAX_LENGTH];
    let (mut head, mut tail) = (0usize, 1usize);
    queue[0] = 0;
    visited[0] = true;
    while head < tail {
        let cell = queue[head];
        head += 1;
        let farthest = cell + *values.add(cell) as usize;
        if farthest >= length - 1 { return distance[cell] as i64 + 1; }
        for next in cell + 1..=farthest {
            if !visited[next] {
                visited[next] = true;
                distance[next] = distance[cell] + 1;
                queue[tail] = next;
                tail += 1;
            }
        }
    }
    -1
}
