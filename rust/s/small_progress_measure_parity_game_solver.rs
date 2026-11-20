const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 20;
const MAX_INPUT: usize = 59;
type Rank = [u8; 3];

fn compare(left: &Rank, left_top: bool, right: &Rank, right_top: bool) -> i32 {
    if left_top != right_top { return if left_top { 1 } else { -1 }; }
    if left_top { return 0; }
    for i in 0..3 {
        if left[i] != right[i] { return if left[i] < right[i] { -1 } else { 1 }; }
    }
    0
}

fn progress(target: Rank, target_top: bool, priority: u8, bounds: Rank) -> (Rank, bool) {
    let mut result = target;
    if target_top { return (result, true); }
    let included = if priority < 1 { 0 } else if priority < 3 { 1 }
        else if priority < 5 { 2 } else { 3 };
    for i in included..3 { result[i] = 0; }
    if priority % 2 == 0 { return (result, false); }
    for i in (0..included).rev() {
        if result[i] < bounds[i] {
            result[i] += 1;
            for suffix in i + 1..included { result[suffix] = 0; }
            return (result, false);
        }
        result[i] = 0;
    }
    ([0; 3], true)
}

#[no_mangle]
pub unsafe extern "C" fn small_progress_measure_parity_game_solver(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    let m_raw = values[1];
    if n_raw < 1 || n_raw > MAX_VERTICES as i64 || m_raw < n_raw || m_raw > MAX_EDGES as i64 {
        return -1;
    }
    let n = n_raw as usize;
    let m = m_raw as usize;
    if length != 2 + 2 * n + 2 * m { return -1; }

    let mut owners = [0u8; MAX_VERTICES];
    let mut priorities = [0u8; MAX_VERTICES];
    let mut adjacency = [0u16; MAX_VERTICES];
    let mut outdegree = [0u8; MAX_VERTICES];
    let mut bounds = [0u8; 3];
    let mut measures = [[0u8; 3]; MAX_VERTICES];
    let mut top = [false; MAX_VERTICES];
    let mut cursor = 2;
    for v in 0..n {
        let owner = values[cursor];
        let priority = values[cursor + 1];
        cursor += 2;
        if !(0..=1).contains(&owner) || !(0..=5).contains(&priority) { return -1; }
        owners[v] = owner as u8;
        priorities[v] = priority as u8;
        if priority == 1 { bounds[0] += 1; }
        if priority == 3 { bounds[1] += 1; }
        if priority == 5 { bounds[2] += 1; }
    }
    for _ in 0..m {
        let source_raw = values[cursor];
        let destination_raw = values[cursor + 1];
        cursor += 2;
        if source_raw < 0 || source_raw >= n_raw || destination_raw < 0 || destination_raw >= n_raw {
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

    loop {
        let mut changed = false;
        for v in 0..n {
            let mut best = [0u8; 3];
            let mut best_top = owners[v] == 1;
            let mut has_best = false;
            for w in 0..n {
                if adjacency[v] & (1u16 << w) == 0 { continue; }
                let (candidate, candidate_top) = progress(measures[w], top[w], priorities[v], bounds);
                let order = compare(&candidate, candidate_top, &best, best_top);
                if !has_best || (if owners[v] == 0 { order < 0 } else { order > 0 }) {
                    best = candidate;
                    best_top = candidate_top;
                    has_best = true;
                }
            }
            if compare(&measures[v], top[v], &best, best_top) < 0 {
                measures[v] = best;
                top[v] = best_top;
                changed = true;
            }
        }
        if !changed { break; }
    }
    let mut winners = 0i64;
    for v in 0..n { if !top[v] { winners |= 1i64 << v; } }
    winners
}
