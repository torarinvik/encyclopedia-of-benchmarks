const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 24;
const MAX_INPUT_VALUES: usize = 4 + 3 * MAX_EDGES + 1;
const FLOW_INFINITY: i64 = 2401;

fn push_forward(vertex: usize, sink: usize, amount: i64, n: usize,
    residual: &mut [[i64; MAX_VERTICES]; MAX_VERTICES],
    active: &mut [[bool; MAX_VERTICES]; MAX_VERTICES],
    incoming: &mut [i64; MAX_VERTICES], outgoing: &mut [i64; MAX_VERTICES]) -> i64 {
    if vertex == sink { return amount; }
    let mut remaining = amount;
    for next in 0..n {
        if remaining == 0 || !active[vertex][next] || residual[vertex][next] == 0 { continue; }
        let limit = remaining.min(residual[vertex][next]);
        let pushed = push_forward(next, sink, limit, n, residual, active, incoming, outgoing);
        if pushed == 0 { continue; }
        residual[vertex][next] -= pushed;
        residual[next][vertex] += pushed;
        outgoing[vertex] -= pushed;
        incoming[next] -= pushed;
        remaining -= pushed;
        if residual[vertex][next] == 0 { active[vertex][next] = false; }
    }
    amount - remaining
}

fn push_backward(vertex: usize, source: usize, amount: i64, n: usize,
    residual: &mut [[i64; MAX_VERTICES]; MAX_VERTICES],
    active: &mut [[bool; MAX_VERTICES]; MAX_VERTICES],
    incoming: &mut [i64; MAX_VERTICES], outgoing: &mut [i64; MAX_VERTICES]) -> i64 {
    if vertex == source { return amount; }
    let mut remaining = amount;
    for previous in 0..n {
        if remaining == 0 || !active[previous][vertex] || residual[previous][vertex] == 0 { continue; }
        let limit = remaining.min(residual[previous][vertex]);
        let pushed = push_backward(previous, source, limit, n, residual, active, incoming, outgoing);
        if pushed == 0 { continue; }
        residual[previous][vertex] -= pushed;
        residual[vertex][previous] += pushed;
        incoming[vertex] -= pushed;
        outgoing[previous] -= pushed;
        remaining -= pushed;
        if residual[previous][vertex] == 0 { active[previous][vertex] = false; }
    }
    amount - remaining
}

fn remove_vertex(vertex: usize, n: usize,
    residual: &[[i64; MAX_VERTICES]; MAX_VERTICES],
    active: &mut [[bool; MAX_VERTICES]; MAX_VERTICES],
    incoming: &mut [i64; MAX_VERTICES], outgoing: &mut [i64; MAX_VERTICES],
    alive: &mut [bool; MAX_VERTICES]) {
    for other in 0..n {
        if active[other][vertex] {
            let capacity = residual[other][vertex];
            outgoing[other] -= capacity;
            incoming[vertex] -= capacity;
            active[other][vertex] = false;
        }
        if active[vertex][other] {
            let capacity = residual[vertex][other];
            outgoing[vertex] -= capacity;
            incoming[other] -= capacity;
            active[vertex][other] = false;
        }
    }
    alive[vertex] = false;
}

#[no_mangle]
pub unsafe extern "C" fn mpm_maxflow(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_VALUES { return -1; }
    let n_value = *input;
    let edge_count_value = *input.add(1);
    let source_value = *input.add(2);
    let sink_value = *input.add(3);
    if !(2..=MAX_VERTICES as i64).contains(&n_value) ||
        !(0..=MAX_EDGES as i64).contains(&edge_count_value) ||
        source_value < 1 || source_value > n_value || sink_value < 1 ||
        sink_value > n_value || source_value == sink_value { return -1; }
    let n = n_value as usize;
    let edge_count = edge_count_value as usize;
    let source = (source_value - 1) as usize;
    let sink = (sink_value - 1) as usize;
    if length != 4 + 3 * edge_count { return -1; }

    let mut residual = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..edge_count {
        let from_value = *input.add(4 + 3 * edge);
        let to_value = *input.add(5 + 3 * edge);
        let capacity = *input.add(6 + 3 * edge);
        if from_value < 1 || from_value > n_value || to_value < 1 || to_value > n_value ||
            from_value == to_value || !(0..=100).contains(&capacity) { return -1; }
        residual[(from_value - 1) as usize][(to_value - 1) as usize] += capacity;
    }

    let mut total_flow = 0i64;
    loop {
        let mut level = [-1i32; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        let (mut head, mut tail) = (0usize, 0usize);
        level[source] = 0;
        queue[tail] = source;
        tail += 1;
        while head < tail {
            let vertex = queue[head];
            head += 1;
            for next in 0..n {
                if residual[vertex][next] > 0 && level[next] < 0 {
                    level[next] = level[vertex] + 1;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        if level[sink] < 0 { break; }

        let mut incoming = [0i64; MAX_VERTICES];
        let mut outgoing = [0i64; MAX_VERTICES];
        let mut active = [[false; MAX_VERTICES]; MAX_VERTICES];
        let mut alive = [false; MAX_VERTICES];
        for vertex in 0..n { alive[vertex] = level[vertex] >= 0 && level[vertex] <= level[sink]; }
        for from in 0..n {
            for to in 0..n {
                if level[from] >= 0 && level[from] < level[sink] &&
                    level[to] == level[from] + 1 && residual[from][to] > 0 {
                    active[from][to] = true;
                    outgoing[from] += residual[from][to];
                    incoming[to] += residual[from][to];
                }
            }
        }
        incoming[source] = FLOW_INFINITY;
        outgoing[sink] = FLOW_INFINITY;

        loop {
            let mut reference = None;
            let mut least_potential = FLOW_INFINITY + 1;
            for vertex in 0..n {
                if !alive[vertex] { continue; }
                let potential = incoming[vertex].min(outgoing[vertex]);
                if potential < least_potential {
                    least_potential = potential;
                    reference = Some(vertex);
                }
            }
            let Some(vertex) = reference else { break; };
            if least_potential > 0 {
                total_flow += least_potential;
                let _ = push_backward(vertex, source, least_potential, n,
                    &mut residual, &mut active, &mut incoming, &mut outgoing);
                let _ = push_forward(vertex, sink, least_potential, n,
                    &mut residual, &mut active, &mut incoming, &mut outgoing);
            }
            remove_vertex(vertex, n, &residual, &mut active,
                &mut incoming, &mut outgoing, &mut alive);
        }
    }
    total_flow
}
