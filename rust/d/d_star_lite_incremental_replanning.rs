const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 48;
const MAX_EVENTS: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 199;
const INF: i64 = 1_000_000_000;

#[derive(Clone, Copy)]
struct Key {
    first: i64,
    second: i64,
}

fn manhattan(left: usize, right: usize, width: usize) -> i64 {
    let left_row = left / width;
    let right_row = right / width;
    let left_column = left % width;
    let right_column = right % width;
    let row_distance = if left_row >= right_row {
        left_row - right_row
    } else {
        right_row - left_row
    };
    let column_distance = if left_column >= right_column {
        left_column - right_column
    } else {
        right_column - left_column
    };
    (row_distance + column_distance) as i64
}

fn calculate_key(
    vertex: usize,
    start: usize,
    width: usize,
    km: i64,
    g: &[i64; MAX_VERTICES],
    rhs: &[i64; MAX_VERTICES],
) -> Key {
    let minimum = g[vertex].min(rhs[vertex]);
    Key {
        first: minimum + manhattan(start, vertex, width) + km,
        second: minimum,
    }
}

fn key_less(left: Key, right: Key) -> bool {
    left.first < right.first || (left.first == right.first && left.second < right.second)
}

fn update_vertex(
    vertex: usize,
    goal: usize,
    start: usize,
    width: usize,
    edge_count: usize,
    km: i64,
    tails: &[usize; MAX_EDGES],
    heads: &[usize; MAX_EDGES],
    costs: &[i64; MAX_EDGES],
    g: &[i64; MAX_VERTICES],
    rhs: &mut [i64; MAX_VERTICES],
    in_open: &mut [bool; MAX_VERTICES],
    key_first: &mut [i64; MAX_VERTICES],
    key_second: &mut [i64; MAX_VERTICES],
) {
    if vertex != goal {
        let mut best = INF;
        for edge in 0..edge_count {
            if tails[edge] == vertex {
                let candidate = costs[edge] + g[heads[edge]];
                if candidate < best {
                    best = candidate;
                }
            }
        }
        rhs[vertex] = best;
    }

    in_open[vertex] = false;
    if g[vertex] != rhs[vertex] {
        let key = calculate_key(vertex, start, width, km, g, rhs);
        in_open[vertex] = true;
        key_first[vertex] = key.first;
        key_second[vertex] = key.second;
    }
}

fn compute_shortest_path(
    start: usize,
    goal: usize,
    width: usize,
    vertex_count: usize,
    edge_count: usize,
    km: i64,
    tails: &[usize; MAX_EDGES],
    heads: &[usize; MAX_EDGES],
    costs: &[i64; MAX_EDGES],
    g: &mut [i64; MAX_VERTICES],
    rhs: &mut [i64; MAX_VERTICES],
    in_open: &mut [bool; MAX_VERTICES],
    key_first: &mut [i64; MAX_VERTICES],
    key_second: &mut [i64; MAX_VERTICES],
) {
    loop {
        let mut top = MAX_VERTICES;
        let mut top_key = Key { first: 0, second: 0 };
        for vertex in 0..vertex_count {
            if in_open[vertex] {
                let key = Key {
                    first: key_first[vertex],
                    second: key_second[vertex],
                };
                if top == MAX_VERTICES
                    || key_less(key, top_key)
                    || (key.first == top_key.first
                        && key.second == top_key.second
                        && vertex < top)
                {
                    top = vertex;
                    top_key = key;
                }
            }
        }

        let start_key = calculate_key(start, start, width, km, g, rhs);
        if top == MAX_VERTICES
            || (!key_less(top_key, start_key) && rhs[start] == g[start])
        {
            break;
        }

        let old_key = top_key;
        let new_key = calculate_key(top, start, width, km, g, rhs);
        if key_less(old_key, new_key) {
            key_first[top] = new_key.first;
            key_second[top] = new_key.second;
            continue;
        }

        in_open[top] = false;
        if g[top] > rhs[top] {
            g[top] = rhs[top];
            for edge in 0..edge_count {
                if heads[edge] == top {
                    update_vertex(
                        tails[edge], goal, start, width, edge_count, km,
                        tails, heads, costs, g, rhs, in_open, key_first, key_second,
                    );
                }
            }
        } else {
            g[top] = INF;
            update_vertex(
                top, goal, start, width, edge_count, km,
                tails, heads, costs, g, rhs, in_open, key_first, key_second,
            );
            for edge in 0..edge_count {
                if heads[edge] == top {
                    update_vertex(
                        tails[edge], goal, start, width, edge_count, km,
                        tails, heads, costs, g, rhs, in_open, key_first, key_second,
                    );
                }
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn d_star_lite_incremental_replanning(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(6..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let height_value = values[0];
    let width_value = values[1];
    let edge_count_value = values[2];
    let event_count_value = values[3];
    if !(1..=4).contains(&height_value)
        || !(1..=4).contains(&width_value)
        || edge_count_value < 0
        || !(0..=MAX_EVENTS as i64).contains(&event_count_value)
    {
        return -1;
    }
    let height = height_value as usize;
    let width = width_value as usize;
    let vertex_count = height * width;
    if !(2..=MAX_VERTICES).contains(&vertex_count) {
        return -1;
    }
    let maximum_edges = 2 * (height * (width - 1) + width * (height - 1));
    if edge_count_value as usize > maximum_edges || edge_count_value as usize > MAX_EDGES {
        return -1;
    }
    let edge_count = edge_count_value as usize;
    let event_count = event_count_value as usize;
    let start_value = values[4];
    let goal_value = values[5];
    if start_value < 0
        || start_value as usize >= vertex_count
        || goal_value < 0
        || goal_value as usize >= vertex_count
        || length != 6 + 3 * edge_count + 3 * event_count
    {
        return -1;
    }

    let mut tails = [0usize; MAX_EDGES];
    let mut heads = [0usize; MAX_EDGES];
    let mut costs = [0i64; MAX_EDGES];
    for edge in 0..edge_count {
        let offset = 6 + 3 * edge;
        let tail_value = values[offset];
        let head_value = values[offset + 1];
        let cost = values[offset + 2];
        if tail_value < 0
            || tail_value as usize >= vertex_count
            || head_value < 0
            || head_value as usize >= vertex_count
            || !(1..=9).contains(&cost)
        {
            return -1;
        }
        let tail = tail_value as usize;
        let head = head_value as usize;
        if manhattan(tail, head, width) != 1 {
            return -1;
        }
        for previous in 0..edge {
            if tails[previous] == tail && heads[previous] == head {
                return -1;
            }
        }
        tails[edge] = tail;
        heads[edge] = head;
        costs[edge] = cost;
    }

    let mut event_starts = [0usize; MAX_EVENTS];
    let mut event_edges = [0usize; MAX_EVENTS];
    let mut event_costs = [0i64; MAX_EVENTS];
    for event in 0..event_count {
        let offset = 6 + 3 * edge_count + 3 * event;
        let new_start = values[offset];
        let edge_id = values[offset + 1];
        let new_cost = values[offset + 2];
        if new_start < 0
            || new_start as usize >= vertex_count
            || edge_id < 0
            || edge_id as usize >= edge_count
            || !(1..=9).contains(&new_cost)
        {
            return -1;
        }
        event_starts[event] = new_start as usize;
        event_edges[event] = edge_id as usize;
        event_costs[event] = new_cost;
    }

    let mut g = [INF; MAX_VERTICES];
    let mut rhs = [INF; MAX_VERTICES];
    let mut in_open = [false; MAX_VERTICES];
    let mut key_first = [0i64; MAX_VERTICES];
    let mut key_second = [0i64; MAX_VERTICES];
    let initial_start = start_value as usize;
    let goal = goal_value as usize;
    let mut current_start = initial_start;
    let mut last_start = initial_start;
    let mut km = 0i64;
    rhs[goal] = 0;
    update_vertex(
        goal, goal, current_start, width, edge_count, km,
        &tails, &heads, &costs, &g, &mut rhs, &mut in_open, &mut key_first, &mut key_second,
    );

    let mut checksum = 0i64;
    for event in 0..event_count {
        let new_start = event_starts[event];
        km += manhattan(last_start, new_start, width);
        last_start = new_start;
        current_start = new_start;
        costs[event_edges[event]] = event_costs[event];
        update_vertex(
            tails[event_edges[event]], goal, current_start, width, edge_count, km,
            &tails, &heads, &costs, &g, &mut rhs, &mut in_open, &mut key_first, &mut key_second,
        );
        compute_shortest_path(
            current_start, goal, width, vertex_count, edge_count, km,
            &tails, &heads, &costs, &mut g, &mut rhs, &mut in_open, &mut key_first, &mut key_second,
        );

        let mut distance_code = 136i64;
        let mut next_code = 0i64;
        if g[current_start] < INF {
            distance_code = g[current_start];
            if current_start != goal {
                let mut next_vertex = MAX_VERTICES;
                for edge in 0..edge_count {
                    if tails[edge] == current_start
                        && costs[edge] + g[heads[edge]] == g[current_start]
                        && heads[edge] < next_vertex
                    {
                        next_vertex = heads[edge];
                    }
                }
                if next_vertex < MAX_VERTICES {
                    next_code = (next_vertex + 1) as i64;
                }
            }
        }
        checksum += (event as i64 + 1) * (distance_code + 1) * (next_code + 1);
    }
    checksum
}
