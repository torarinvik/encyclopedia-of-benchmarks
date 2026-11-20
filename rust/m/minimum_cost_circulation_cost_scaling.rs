const MAX_N: usize = 8;
const MAX_M: usize = 10;
const MAX_INPUT_LENGTH: usize = 43;
const MAX_ARCS: usize = 2 * MAX_M;
const COST_OFFSET: i64 = 81;

#[derive(Clone, Copy, Default)]
struct ResidualArc {
    from: usize,
    to: usize,
    reverse: usize,
    capacity: i64,
    cost: i64,
}

fn execute(input: &[i64]) -> Option<i64> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return None; }
    let n_value = input[0];
    let m_value = input[1];
    if n_value < 1 || n_value > MAX_N as i64 || m_value < 0 || m_value > MAX_M as i64 { return None; }
    let n = n_value as usize;
    let m = m_value as usize;
    if input.len() != 2 + 4 * m { return None; }

    let mut edges = [ResidualArc::default(); MAX_ARCS];
    let mut max_scaled_cost = 0i64;
    for index in 0..m {
        let offset = 2 + 4 * index;
        let (from_value, to_value) = (input[offset], input[offset + 1]);
        let (capacity, cost) = (input[offset + 2], input[offset + 3]);
        if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value
            || !(0..=2).contains(&capacity) || !(-4..=4).contains(&cost) { return None; }
        let (from, to) = (from_value as usize, to_value as usize);
        let scaled_cost = cost * (n as i64 + 1);
        let forward = 2 * index;
        let reverse = forward + 1;
        edges[forward] = ResidualArc { from, to, reverse, capacity, cost: scaled_cost };
        edges[reverse] = ResidualArc { from: to, to: from, reverse: forward, capacity: 0, cost: -scaled_cost };
        max_scaled_cost = max_scaled_cost.max(scaled_cost.abs());
    }

    let mut epsilon = 1i64;
    while epsilon < max_scaled_cost { epsilon *= 2; }
    let mut price = [0i64; MAX_N];
    let arc_count = 2 * m;
    while epsilon > 1 {
        epsilon /= 2;
        let mut excess = [0i64; MAX_N];

        for edge_index in 0..arc_count {
            if edges[edge_index].capacity <= 0 { continue; }
            let (from, to) = (edges[edge_index].from, edges[edge_index].to);
            let reduced_cost = edges[edge_index].cost + price[from] - price[to];
            if reduced_cost < 0 {
                let amount = edges[edge_index].capacity;
                edges[edge_index].capacity = 0;
                let reverse = edges[edge_index].reverse;
                edges[reverse].capacity += amount;
                excess[from] -= amount;
                excess[to] += amount;
            }
        }

        let mut queue = [0usize; MAX_N];
        let mut queued = [false; MAX_N];
        let (mut head, mut tail, mut queue_count) = (0usize, 0usize, 0usize);
        for vertex in 0..n {
            if excess[vertex] > 0 {
                queue[tail] = vertex;
                tail = (tail + 1) % n;
                queue_count += 1;
                queued[vertex] = true;
            }
        }

        while queue_count > 0 {
            let vertex = queue[head];
            head = (head + 1) % n;
            queue_count -= 1;
            queued[vertex] = false;
            while excess[vertex] > 0 {
                let mut admissible = None;
                for edge_index in 0..arc_count {
                    let edge = edges[edge_index];
                    if edge.from != vertex || edge.to == vertex || edge.capacity <= 0 { continue; }
                    if edge.cost + price[vertex] - price[edge.to] < 0 {
                        admissible = Some(edge_index);
                        break;
                    }
                }

                if let Some(edge_index) = admissible {
                    let to = edges[edge_index].to;
                    let reverse = edges[edge_index].reverse;
                    let amount = excess[vertex].min(edges[edge_index].capacity);
                    edges[edge_index].capacity -= amount;
                    edges[reverse].capacity += amount;
                    let old_excess = excess[to];
                    excess[vertex] -= amount;
                    excess[to] += amount;
                    if old_excess <= 0 && excess[to] > 0 && !queued[to] {
                        queue[tail] = to;
                        tail = (tail + 1) % n;
                        queue_count += 1;
                        queued[to] = true;
                    }
                } else {
                    let mut best_price = None;
                    for edge_index in 0..arc_count {
                        let edge = edges[edge_index];
                        if edge.from != vertex || edge.capacity <= 0 { continue; }
                        let candidate = price[edge.to] - edge.cost - epsilon;
                        if best_price.map_or(true, |best| candidate > best) {
                            best_price = Some(candidate);
                        }
                    }
                    price[vertex] = best_price?;
                }
            }
        }
        if excess[..n].iter().any(|&value| value != 0) { return None; }
    }

    let mut total_cost = 0i64;
    for index in 0..m {
        let capacity = input[2 + 4 * index + 2];
        let cost = input[2 + 4 * index + 3];
        let flow = capacity - edges[2 * index].capacity;
        total_cost += flow * cost;
    }
    Some(total_cost + COST_OFFSET)
}

#[no_mangle]
pub unsafe extern "C" fn minimum_cost_circulation_cost_scaling(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
