/// Ordered candidate-intersection search with a suffix-optimum bound.
const MAX_VERTICES: usize = 24;
const MAX_PARSEABLE_INPUT: usize = 26;

struct CliqueSearch {
    adjacency: [u64; MAX_VERTICES],
    suffix_best: [i64; MAX_VERTICES],
    best: i64,
}

fn search_clique(search: &mut CliqueSearch, candidates: u64, chosen: i64) -> bool {
    if candidates == 0 {
        if chosen > search.best {
            search.best = chosen;
            return true;
        }
        return false;
    }
    let mut remaining = candidates;
    while remaining != 0 {
        if chosen + remaining.count_ones() as i64 <= search.best { return false; }
        let bit = remaining & remaining.wrapping_neg();
        let vertex = bit.trailing_zeros() as usize;
        remaining &= !bit;
        if chosen + search.suffix_best[vertex] <= search.best { return false; }
        if search_clique(search, remaining & search.adjacency[vertex], chosen + 1) {
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn oi_wiki_maximum_clique_branch_bound(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if !(0..=MAX_VERTICES as i64).contains(&n64) || length != 1 + n64 as usize { return -1; }
    let n = n64 as usize;
    let domain = (1u64 << n) - 1;
    let mut search = CliqueSearch {
        adjacency: [0; MAX_VERTICES],
        suffix_best: [0; MAX_VERTICES],
        best: 0,
    };
    for vertex in 0..n {
        let row = values[1 + vertex];
        if row < 0 || (row as u64) & !domain != 0 { return -1; }
        search.adjacency[vertex] = row as u64;
        if search.adjacency[vertex] & (1u64 << vertex) != 0 { return -1; }
    }
    for left in 0..n {
        for right in left + 1..n {
            let forward = search.adjacency[left] & (1u64 << right) != 0;
            let reverse = search.adjacency[right] & (1u64 << left) != 0;
            if forward != reverse { return -1; }
        }
    }
    for root in (0..n).rev() {
        let greater = domain & !((1u64 << (root + 1)) - 1);
        let candidates = search.adjacency[root] & greater;
        search_clique(&mut search, candidates, 1);
        search.suffix_best[root] = search.best;
    }
    search.best
}
