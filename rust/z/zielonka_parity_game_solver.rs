const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 20;
const MAX_PARSEABLE_INPUT: usize = 59;

fn zpg_attractor(active: u16, player: i64, target: u16,
                 owners: &[i64; MAX_VERTICES], adjacency: &[u16; MAX_VERTICES], n: usize) -> u16 {
    let mut attracted = target;
    loop {
        let mut additions = 0u16;
        for vertex in 0..n {
            let bit = 1u16 << vertex;
            if active & bit == 0 || attracted & bit != 0 { continue; }
            let successors = adjacency[vertex] & active;
            if owners[vertex] == player {
                if successors & attracted != 0 { additions |= bit; }
            } else if successors != 0 && successors & !attracted == 0 {
                additions |= bit;
            }
        }
        if additions == 0 { return attracted; }
        attracted |= additions;
    }
}

fn zpg_solve(active: u16, owners: &[i64; MAX_VERTICES], priorities: &[i64; MAX_VERTICES],
             adjacency: &[u16; MAX_VERTICES], n: usize) -> u16 {
    if active == 0 { return 0; }
    let mut lowest = 6i64;
    for vertex in 0..n {
        if active & (1u16 << vertex) != 0 && priorities[vertex] < lowest {
            lowest = priorities[vertex];
        }
    }
    let player = lowest & 1;
    let mut target = 0u16;
    for vertex in 0..n {
        if active & (1u16 << vertex) != 0 && priorities[vertex] == lowest {
            target |= 1u16 << vertex;
        }
    }
    let first = zpg_attractor(active, player, target, owners, adjacency, n);
    let remainder = active & !first;
    let even_first = zpg_solve(remainder, owners, priorities, adjacency, n);
    let odd_first = remainder & !even_first;
    let opponent_region = if player == 1 { even_first } else { odd_first };
    if opponent_region == 0 {
        return even_first | (if player == 0 { first } else { 0 });
    }
    let second = zpg_attractor(active, 1 - player, opponent_region, owners, adjacency, n);
    let even_second = zpg_solve(active & !second, owners, priorities, adjacency, n);
    even_second | (if player == 1 { second } else { 0 })
}

#[no_mangle]
pub unsafe extern "C" fn zielonka_parity_game_solver(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_PARSEABLE_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_raw = values[0];
    let edge_raw = values[1];
    if !(1..=MAX_VERTICES as i64).contains(&vertex_raw)
        || edge_raw < vertex_raw || edge_raw > MAX_EDGES as i64 { return -1; }
    let n = vertex_raw as usize;
    let edge_count = edge_raw as usize;
    if length != 2 + 2 * n + 2 * edge_count { return -1; }

    let mut owners = [0i64; MAX_VERTICES];
    let mut priorities = [0i64; MAX_VERTICES];
    let mut adjacency = [0u16; MAX_VERTICES];
    let mut outdegree = [0usize; MAX_VERTICES];
    let mut cursor = 2;
    for vertex in 0..n {
        let owner = values[cursor];
        let priority = values[cursor + 1];
        cursor += 2;
        if !(0..=1).contains(&owner) || !(0..=5).contains(&priority) { return -1; }
        owners[vertex] = owner;
        priorities[vertex] = priority;
    }
    for _ in 0..edge_count {
        let source_raw = values[cursor];
        let destination_raw = values[cursor + 1];
        cursor += 2;
        if source_raw < 0 || source_raw >= vertex_raw || destination_raw < 0 || destination_raw >= vertex_raw {
            return -1;
        }
        let source = source_raw as usize;
        let destination = destination_raw as usize;
        let bit = 1u16 << destination;
        if adjacency[source] & bit != 0 { return -1; }
        adjacency[source] |= bit;
        outdegree[source] += 1;
    }
    if outdegree[..n].contains(&0) { return -1; }
    zpg_solve((1u16 << n) - 1, &owners, &priorities, &adjacency, n) as i64
}
