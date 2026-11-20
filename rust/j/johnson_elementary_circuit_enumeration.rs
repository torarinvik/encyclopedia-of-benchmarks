const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 24;
const MAX_INPUT_LENGTH: usize = 51;
const COUNT_SCALE: i64 = 1_000_000_000_000;

type Graph = [[bool; MAX_VERTICES]; MAX_VERTICES];

struct SccState {
    graph: Graph,
    n: usize,
    lower_bound: usize,
    next_index: usize,
    component_count: usize,
    stack_length: usize,
    index: [i32; MAX_VERTICES],
    low_link: [usize; MAX_VERTICES],
    component_id: [i32; MAX_VERTICES],
    on_stack: [bool; MAX_VERTICES],
    stack: [usize; MAX_VERTICES],
    component_size: [usize; MAX_VERTICES],
    component_minimum: [usize; MAX_VERTICES],
}

struct CircuitState {
    graph: Graph,
    n: usize,
    start: usize,
    selected_component: i32,
    depth: usize,
    component_id: [i32; MAX_VERTICES],
    blocked: [bool; MAX_VERTICES],
    dependencies: [[bool; MAX_VERTICES]; MAX_VERTICES],
    path: [usize; MAX_VERTICES],
    count: i64,
    code_sum: i64,
}

fn strong_connect(vertex: usize, state: &mut SccState) {
    state.index[vertex] = state.next_index as i32;
    state.low_link[vertex] = state.next_index;
    state.next_index += 1;
    state.stack[state.stack_length] = vertex;
    state.stack_length += 1;
    state.on_stack[vertex] = true;

    for neighbor in state.lower_bound..state.n {
        if !state.graph[vertex][neighbor] { continue; }
        if state.index[neighbor] < 0 {
            strong_connect(neighbor, state);
            state.low_link[vertex] = state.low_link[vertex].min(state.low_link[neighbor]);
        } else if state.on_stack[neighbor] {
            state.low_link[vertex] = state.low_link[vertex].min(state.index[neighbor] as usize);
        }
    }

    if state.low_link[vertex] == state.index[vertex] as usize {
        let component = state.component_count;
        let mut size = 0usize;
        let mut minimum = state.n;
        loop {
            state.stack_length -= 1;
            let member = state.stack[state.stack_length];
            state.on_stack[member] = false;
            state.component_id[member] = component as i32;
            size += 1;
            minimum = minimum.min(member);
            if member == vertex { break; }
        }
        state.component_size[component] = size;
        state.component_minimum[component] = minimum;
        state.component_count += 1;
    }
}

fn find_selected_component(
    n: usize,
    lower_bound: usize,
    graph: Graph,
    component_id: &mut [i32; MAX_VERTICES],
) -> (usize, i32) {
    let mut state = SccState {
        graph,
        n,
        lower_bound,
        next_index: 0,
        component_count: 0,
        stack_length: 0,
        index: [-1; MAX_VERTICES],
        low_link: [0; MAX_VERTICES],
        component_id: [-1; MAX_VERTICES],
        on_stack: [false; MAX_VERTICES],
        stack: [0; MAX_VERTICES],
        component_size: [0; MAX_VERTICES],
        component_minimum: [n; MAX_VERTICES],
    };
    for vertex in lower_bound..n {
        if state.index[vertex] < 0 { strong_connect(vertex, &mut state); }
    }
    *component_id = state.component_id;
    let mut start = n;
    let mut selected_component = -1i32;
    for component in 0..state.component_count {
        if state.component_size[component] > 1 && state.component_minimum[component] < start {
            start = state.component_minimum[component];
            selected_component = component as i32;
        }
    }
    (start, selected_component)
}

fn unblock(vertex: usize, state: &mut CircuitState) {
    if !state.blocked[vertex] { return; }
    state.blocked[vertex] = false;
    for dependent in 0..state.n {
        if state.dependencies[vertex][dependent] {
            state.dependencies[vertex][dependent] = false;
            if state.blocked[dependent] { unblock(dependent, state); }
        }
    }
}

fn record_cycle(state: &mut CircuitState) {
    let mut code = 0i64;
    let mut place = 1i64;
    for index in 0..state.depth {
        code += (state.path[index] as i64 + 1) * place;
        place *= 9;
    }
    state.count += 1;
    state.code_sum += code;
}

fn circuit(vertex: usize, state: &mut CircuitState) -> bool {
    state.path[state.depth] = vertex;
    state.depth += 1;
    state.blocked[vertex] = true;
    let mut found = false;
    for neighbor in 0..state.n {
        if !state.graph[vertex][neighbor] || state.component_id[neighbor] != state.selected_component {
            continue;
        }
        if neighbor == state.start {
            record_cycle(state);
            found = true;
        } else if !state.blocked[neighbor] && circuit(neighbor, state) {
            found = true;
        }
    }
    if found {
        unblock(vertex, state);
    } else {
        for neighbor in 0..state.n {
            if state.graph[vertex][neighbor] && state.component_id[neighbor] == state.selected_component {
                state.dependencies[neighbor][vertex] = true;
            }
        }
    }
    state.depth -= 1;
    found
}

#[no_mangle]
pub unsafe extern "C" fn johnson_elementary_circuit_enumeration(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    if !(1..=8).contains(&n_value) || !(0..=24).contains(&m_value) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }

    let mut graph = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge_index in 0..m {
        let from_value = values[2 + 2 * edge_index];
        let to_value = values[3 + 2 * edge_index];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64
            || from_value == to_value {
            return -1;
        }
        let from = from_value as usize;
        let to = to_value as usize;
        if graph[from][to] { return -1; }
        graph[from][to] = true;
    }

    let mut lower_bound = 0usize;
    let mut total_count = 0i64;
    let mut total_code_sum = 0i64;
    while lower_bound < n {
        let mut component_id = [-1i32; MAX_VERTICES];
        let (start, selected_component) = find_selected_component(n, lower_bound, graph, &mut component_id);
        if selected_component < 0 { break; }
        let mut state = CircuitState {
            graph,
            n,
            start,
            selected_component,
            depth: 0,
            component_id,
            blocked: [false; MAX_VERTICES],
            dependencies: [[false; MAX_VERTICES]; MAX_VERTICES],
            path: [0; MAX_VERTICES],
            count: 0,
            code_sum: 0,
        };
        let _ = circuit(start, &mut state);
        total_count += state.count;
        total_code_sum += state.code_sum;
        lower_bound = start + 1;
    }
    total_count * COUNT_SCALE + total_code_sum
}
