const MAX_NODES: usize = 256;
const DX: [i32; 8] = [-1, -1, -1, 0, 0, 1, 1, 1];
const DY: [i32; 8] = [-1, 0, 1, -1, 1, -1, 0, 1];

#[derive(Clone, Copy)]
struct SearchNode {
    x: i32,
    y: i32,
    g: i32,
    f: i32,
    parent: i32,
}

unsafe fn write_i64(output: *mut u8, offset: usize, value: i64) {
    for (index, byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn astar(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 6 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (rows, cols, sx, sy, gx, gy) =
        (values[0], values[1], values[2], values[3], values[4], values[5]);
    if !(1..=16).contains(&rows)
        || !(1..=16).contains(&cols)
        || sx < 0
        || sx >= rows
        || sy < 0
        || sy >= cols
        || gx < 0
        || gx >= rows
        || gy < 0
        || gy >= cols
    {
        return -1;
    }
    let rows = rows as i32;
    let cols = cols as i32;
    let sx = sx as i32;
    let sy = sy as i32;
    let gx = gx as i32;
    let gy = gy as i32;
    let empty = SearchNode { x: 0, y: 0, g: 0, f: 0, parent: -1 };
    let mut nodes = [empty; MAX_NODES];
    let mut open = [0i32; MAX_NODES];
    let mut node_count = 1usize;
    let mut open_count = 1usize;
    nodes[0] = SearchNode { x: sx, y: sy, g: 0, f: 0, parent: -1 };
    open[0] = 0;
    let mut current = 0i32;
    let mut found = false;
    while open_count > 0 {
        let mut best = 0usize;
        for i in 1..open_count {
            if nodes[open[i] as usize].f < nodes[open[best] as usize].f {
                best = i;
            }
        }
        current = open[best];
        for i in best + 1..open_count {
            open[i - 1] = open[i];
        }
        open_count -= 1;
        let current_node = nodes[current as usize];
        if current_node.x == gx && current_node.y == gy {
            found = true;
            break;
        }
        for neighbor in 0..8 {
            let x = current_node.x + DX[neighbor];
            let y = current_node.y + DY[neighbor];
            if x < 0 || x >= rows || y < 0 || y >= cols {
                continue;
            }
            if node_count >= MAX_NODES || open_count >= MAX_NODES {
                return -1;
            }
            let g = current_node.g + 1;
            let ex = gx - x;
            let ey = gy - y;
            nodes[node_count] = SearchNode { x, y, g, f: g + ex * ex + ey * ey, parent: current };
            open[open_count] = node_count as i32;
            open_count += 1;
            node_count += 1;
        }
    }
    if !found {
        return -1;
    }
    let mut path_count = 0usize;
    let mut cursor = current;
    while cursor >= 0 {
        path_count += 1;
        cursor = nodes[cursor as usize].parent;
    }
    let output_bytes = path_count * 16;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let mut offset = output_bytes;
    cursor = current;
    while cursor >= 0 {
        let node = nodes[cursor as usize];
        offset -= 16;
        write_i64(output, offset, node.x as i64);
        write_i64(output, offset + 8, node.y as i64);
        cursor = node.parent;
    }
    output_bytes as i64
}
