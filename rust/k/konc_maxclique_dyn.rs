/// Clean-room bounded MaxCliqueDyn-style colored branch and bound.
const MAX_VERTICES: usize = 24;
const MAX_PARSEABLE_INPUT: usize = 26;

#[derive(Clone, Copy, Default)]
struct Candidate { vertex: usize, bound: usize }

struct Search {
    adjacency: [u64; MAX_VERTICES],
    chosen: [usize; MAX_VERTICES],
    chosen_count: usize,
    best: usize,
    steps: [usize; MAX_VERTICES + 2],
    prior_child_steps: [usize; MAX_VERTICES + 2],
    total_color_calls: usize,
}

fn degree_order(search: &Search, vertices: &[usize]) -> [Candidate; MAX_VERTICES] {
    let mut ids = [0usize; MAX_VERTICES];
    let mut degrees = [0usize; MAX_VERTICES];
    let mut maximum_degree = 0usize;
    for (i, &vertex) in vertices.iter().enumerate() {
        ids[i] = vertex;
        let degree = vertices.iter().filter(|&&other|
            search.adjacency[vertex] & (1u64 << other) != 0).count();
        degrees[i] = degree;
        maximum_degree = maximum_degree.max(degree);
    }
    for i in 1..vertices.len() {
        let id = ids[i];
        let degree = degrees[i];
        let mut j = i;
        while j > 0 && (degrees[j - 1] < degree
            || (degrees[j - 1] == degree && ids[j - 1] > id)) {
            ids[j] = ids[j - 1];
            degrees[j] = degrees[j - 1];
            j -= 1;
        }
        ids[j] = id;
        degrees[j] = degree;
    }
    let mut ordered = [Candidate::default(); MAX_VERTICES];
    for i in 0..vertices.len() {
        ordered[i] = Candidate { vertex: ids[i], bound: i.min(maximum_degree) + 1 };
    }
    ordered
}

fn expand(search: &mut Search, candidates: &[Candidate], level: usize) {
    let parent_steps = search.steps[level - 1];
    search.steps[level] += parent_steps - search.prior_child_steps[level];
    search.prior_child_steps[level] = parent_steps;
    let mut count = candidates.len();
    while count > 0 {
        if search.chosen_count + candidates[count - 1].bound <= search.best { return; }
        let vertex = candidates[count - 1].vertex;
        search.chosen[search.chosen_count] = vertex;
        search.chosen_count += 1;

        let mut neighbors = [0usize; MAX_VERTICES];
        let mut neighbor_count = 0usize;
        for candidate in &candidates[..count - 1] {
            if search.adjacency[vertex] & (1u64 << candidate.vertex) != 0 {
                neighbors[neighbor_count] = candidate.vertex;
                neighbor_count += 1;
            }
        }
        if neighbor_count > 0 {
            let prior_steps = search.steps[level];
            search.steps[level] += 1;
            search.total_color_calls += 1;
            if (prior_steps as u64) * 1000 < (search.total_color_calls as u64) * 25 {
                let reordered = degree_order(search, &neighbors[..neighbor_count]);
                for i in 0..neighbor_count { neighbors[i] = reordered[i].vertex; }
            }

            let mut class_masks = [0u64; MAX_VERTICES];
            let mut colors = [0usize; MAX_VERTICES];
            let mut class_count = 0usize;
            for i in 0..neighbor_count {
                let mut color = 0usize;
                while color < class_count
                    && class_masks[color] & search.adjacency[neighbors[i]] != 0 { color += 1; }
                if color == class_count { class_count += 1; }
                colors[i] = color + 1;
                class_masks[color] |= 1u64 << neighbors[i];
            }

            let minimum_color = search.best.saturating_sub(search.chosen_count) + 1;
            let minimum_color = minimum_color.max(1);
            let mut child = [Candidate::default(); MAX_VERTICES];
            let mut child_count = 0usize;
            for color in minimum_color..=class_count {
                for i in 0..neighbor_count {
                    if colors[i] == color {
                        child[child_count] = Candidate { vertex: neighbors[i], bound: color };
                        child_count += 1;
                    }
                }
            }
            expand(search, &child[..child_count], level + 1);
        } else if search.chosen_count > search.best {
            search.best = search.chosen_count;
        }

        search.chosen_count -= 1;
        count -= 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn konc_maxclique_dyn(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_INPUT).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if !(0..=MAX_VERTICES as i64).contains(&n64) || length != n64 as usize + 1 { return -1; }
    let n = n64 as usize;
    let domain = (1u64 << n) - 1;
    let mut search = Search {
        adjacency: [0; MAX_VERTICES], chosen: [0; MAX_VERTICES], chosen_count: 0,
        best: 0, steps: [0; MAX_VERTICES + 2],
        prior_child_steps: [0; MAX_VERTICES + 2], total_color_calls: 0,
    };
    for vertex in 0..n {
        let row = values[1 + vertex];
        if row < 0 || (row as u64) & !domain != 0 { return -1; }
        search.adjacency[vertex] = row as u64;
        if search.adjacency[vertex] & (1u64 << vertex) != 0 { return -1; }
    }
    for left in 0..n {
        for right in left + 1..n {
            if ((search.adjacency[left] >> right) & 1) != ((search.adjacency[right] >> left) & 1) {
                return -1;
            }
        }
    }
    if n == 0 { return 0; }
    let vertices: Vec<usize> = (0..n).collect();
    let roots = degree_order(&search, &vertices);
    expand(&mut search, &roots[..n], 1);
    search.best as i64
}
