#[no_mangle]
pub unsafe extern "C" fn same_value_teleport_bfs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=65).contains(&length) {
        return -2;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&values[0]) || length != values[0] as usize + 1 {
        return -2;
    }
    let n = values[0] as usize;
    let items = &values[1..];
    if items.iter().any(|&value| !(-64..=64).contains(&value)) {
        return -2;
    }
    if n == 1 {
        return 0;
    }

    let mut first = [-1_i32; 129];
    let mut next = [-1_i32; 64];
    let mut queue = [0_i32; 64];
    let mut distance = [-1_i32; 64];
    for index in 0..n {
        let slot = (items[index] + 64) as usize;
        next[index] = first[slot];
        first[slot] = index as i32;
    }
    let mut front = 0;
    let mut back = 1;
    queue[0] = 0;
    distance[0] = 0;
    while front < back {
        let index = queue[front] as usize;
        front += 1;
        if index == n - 1 {
            return i64::from(distance[index]);
        }
        if index > 0 && distance[index - 1] < 0 {
            distance[index - 1] = distance[index] + 1;
            queue[back] = (index - 1) as i32;
            back += 1;
        }
        if index + 1 < n && distance[index + 1] < 0 {
            distance[index + 1] = distance[index] + 1;
            queue[back] = (index + 1) as i32;
            back += 1;
        }
        let slot = (items[index] + 64) as usize;
        let mut member = first[slot];
        if member >= 0 {
            first[slot] = -1;
            while member >= 0 {
                let member_index = member as usize;
                if distance[member_index] < 0 {
                    distance[member_index] = distance[index] + 1;
                    queue[back] = member;
                    back += 1;
                }
                member = next[member_index];
            }
        }
    }
    i64::from(distance[n - 1])
}
