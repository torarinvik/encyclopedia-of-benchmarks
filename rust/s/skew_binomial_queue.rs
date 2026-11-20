const MAX_OPERATIONS: usize = 64;
const MAX_ITEMS: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 194;
const MAX_RANK_BUCKETS: usize = MAX_OPERATIONS + 1;

fn less_node(
    first: usize,
    second: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
) -> bool {
    (keys[first], serials[first], items[first], first)
        < (keys[second], serials[second], items[second], second)
}

fn roots_before(
    first: usize,
    second: usize,
    ranks: &[i32; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
) -> bool {
    (ranks[first], serials[first], first) < (ranks[second], serials[second], second)
}

fn collect_roots(
    node_count: usize,
    ranks: &[i32; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    parents: &[i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
    roots: &mut [usize; MAX_OPERATIONS],
) -> usize {
    let mut count = 0;
    for node in 0..node_count {
        if alive[node] && parents[node] == -1 {
            roots[count] = node;
            count += 1;
        }
    }
    for i in 1..count {
        let key = roots[i];
        let mut j = i;
        while j > 0 && roots_before(key, roots[j - 1], ranks, serials) {
            roots[j] = roots[j - 1];
            j -= 1;
        }
        roots[j] = key;
    }
    count
}

fn simple_link(
    first: usize,
    second: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    first_child: &mut [i32; MAX_OPERATIONS],
    next_sibling: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
) -> usize {
    let (winner, loser) = if less_node(first, second, keys, serials, items) {
        (first, second)
    } else {
        (second, first)
    };
    next_sibling[loser] = first_child[winner];
    first_child[winner] = loser as i32;
    parents[loser] = winner as i32;
    ranks[winner] += 1;
    winner
}

fn skew_link(
    singleton: usize,
    first: usize,
    second: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    first_child: &mut [i32; MAX_OPERATIONS],
    next_sibling: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
) -> usize {
    let result_rank = ranks[first] + 1;
    let winner;
    if less_node(singleton, first, keys, serials, items)
        && less_node(singleton, second, keys, serials, items)
    {
        winner = singleton;
        first_child[winner] = first as i32;
        next_sibling[first] = second as i32;
        next_sibling[second] = -1;
        parents[first] = winner as i32;
        parents[second] = winner as i32;
    } else {
        winner = if less_node(first, second, keys, serials, items) { first } else { second };
        let loser = if winner == first { second } else { first };
        let old_children = first_child[winner];
        first_child[winner] = singleton as i32;
        next_sibling[singleton] = loser as i32;
        next_sibling[loser] = old_children;
        parents[singleton] = winner as i32;
        parents[loser] = winner as i32;
    }
    parents[winner] = -1;
    ranks[winner] = result_rank;
    winner
}

fn insert_singleton(
    node: usize,
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
    first_child: &mut [i32; MAX_OPERATIONS],
    next_sibling: &mut [i32; MAX_OPERATIONS],
) {
    parents[node] = -2;
    let mut roots = [0usize; MAX_OPERATIONS];
    let root_count = collect_roots(node_count, ranks, serials, parents, alive, &mut roots);
    if root_count >= 2 && ranks[roots[0]] == ranks[roots[1]] {
        skew_link(
            node,
            roots[0],
            roots[1],
            keys,
            serials,
            items,
            first_child,
            next_sibling,
            ranks,
            parents,
        );
    } else {
        parents[node] = -1;
    }
}

fn normalize_equal_ranks(
    input_roots: &[usize; MAX_OPERATIONS],
    root_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    first_child: &mut [i32; MAX_OPERATIONS],
    next_sibling: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
) {
    let mut ordered_roots = *input_roots;
    for i in 1..root_count {
        let key = ordered_roots[i];
        let mut j = i;
        while j > 0 && roots_before(key, ordered_roots[j - 1], ranks, serials) {
            ordered_roots[j] = ordered_roots[j - 1];
            j -= 1;
        }
        ordered_roots[j] = key;
    }
    let mut buckets = [-1i32; MAX_RANK_BUCKETS];
    for &root in ordered_roots[..root_count].iter() {
        let mut current = root;
        loop {
            let rank = ranks[current];
            if rank < 0 || rank as usize >= MAX_RANK_BUCKETS {
                return;
            }
            if buckets[rank as usize] < 0 {
                buckets[rank as usize] = current as i32;
                break;
            }
            let previous = buckets[rank as usize] as usize;
            buckets[rank as usize] = -1;
            current = simple_link(
                previous,
                current,
                keys,
                serials,
                items,
                first_child,
                next_sibling,
                ranks,
                parents,
            );
        }
    }
}

fn minimum_root(
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    serials: &[usize; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    parents: &[i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
) -> Option<usize> {
    let mut best = None;
    for node in 0..node_count {
        if alive[node] && parents[node] == -1 {
            if best.map_or(true, |current| less_node(node, current, keys, serials, items)) {
                best = Some(node);
            }
        }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn skew_binomial_queue(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let operation_count_value = *input;
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count_value) {
        return -1;
    }
    let operation_count = operation_count_value as usize;
    if length != 1 + 3 * operation_count {
        return -1;
    }

    let mut keys = [0i64; MAX_OPERATIONS];
    let mut serials = [0usize; MAX_OPERATIONS];
    let mut items = [-1i32; MAX_OPERATIONS];
    let mut ranks = [0i32; MAX_OPERATIONS];
    let mut first_child = [-1i32; MAX_OPERATIONS];
    let mut next_sibling = [-1i32; MAX_OPERATIONS];
    let mut parents = [-2i32; MAX_OPERATIONS];
    let mut alive = [false; MAX_OPERATIONS];
    let mut item_nodes = [-1i32; MAX_ITEMS];
    let mut active = [false; MAX_ITEMS];
    let mut node_count = 0usize;
    let mut insertion_serial = 0usize;
    let mut result = 0i64;

    for operation_index in 0..operation_count {
        let offset = 1 + 3 * operation_index;
        let opcode = *input.add(offset);
        let item_value = *input.add(offset + 1);
        let key = *input.add(offset + 2);
        if opcode == 1 {
            if !(0..MAX_ITEMS as i64).contains(&item_value) || !(0..=1_000_000).contains(&key) {
                return -1;
            }
            let item = item_value as usize;
            if active[item] || node_count >= MAX_OPERATIONS {
                return -1;
            }
            let node = node_count;
            node_count += 1;
            keys[node] = key;
            serials[node] = insertion_serial;
            insertion_serial += 1;
            items[node] = item as i32;
            ranks[node] = 0;
            first_child[node] = -1;
            next_sibling[node] = -1;
            parents[node] = -1;
            alive[node] = true;
            item_nodes[item] = node as i32;
            active[item] = true;
            insert_singleton(
                node,
                node_count,
                &keys,
                &serials,
                &items,
                &mut ranks,
                &mut parents,
                &alive,
                &mut first_child,
                &mut next_sibling,
            );
        } else if opcode == 2 || opcode == 3 {
            if item_value != 0 || key != 0 {
                return -1;
            }
            let Some(node) = minimum_root(node_count, &keys, &serials, &items, &parents, &alive) else {
                return -1;
            };
            let item = items[node] as usize;
            result += (operation_index as i64 + 1) * (keys[node] + 1) + item as i64;
            if opcode == 2 {
                continue;
            }

            active[item] = false;
            item_nodes[item] = -1;
            let mut children = [0usize; MAX_OPERATIONS];
            let mut child_count = 0usize;
            let mut child = first_child[node];
            while child >= 0 {
                let child_index = child as usize;
                let following = next_sibling[child_index];
                parents[child_index] = -1;
                next_sibling[child_index] = -1;
                children[child_count] = child_index;
                child_count += 1;
                child = following;
            }
            alive[node] = false;
            parents[node] = -2;
            items[node] = -1;
            first_child[node] = -1;
            next_sibling[node] = -1;

            let mut child_membership = [false; MAX_OPERATIONS];
            let mut zero_children = [0usize; MAX_OPERATIONS];
            let mut zero_count = 0usize;
            let mut positive_children = [0usize; MAX_OPERATIONS];
            let mut positive_count = 0usize;
            for &descendant in children[..child_count].iter() {
                child_membership[descendant] = true;
                if ranks[descendant] == 0 {
                    zero_children[zero_count] = descendant;
                    zero_count += 1;
                } else {
                    positive_children[positive_count] = descendant;
                    positive_count += 1;
                }
            }
            zero_children[..zero_count].sort_by_key(|&descendant| (serials[descendant], descendant));

            let mut roots = [0usize; MAX_OPERATIONS];
            let mut root_count = 0usize;
            for candidate in 0..node_count {
                if alive[candidate] && parents[candidate] == -1 && !child_membership[candidate] {
                    roots[root_count] = candidate;
                    root_count += 1;
                }
            }
            for &descendant in positive_children[..positive_count].iter() {
                roots[root_count] = descendant;
                root_count += 1;
            }
            normalize_equal_ranks(
                &roots,
                root_count,
                &keys,
                &serials,
                &items,
                &mut first_child,
                &mut next_sibling,
                &mut ranks,
                &mut parents,
            );
            for &singleton in zero_children[..zero_count].iter() {
                insert_singleton(
                    singleton,
                    node_count,
                    &keys,
                    &serials,
                    &items,
                    &mut ranks,
                    &mut parents,
                    &alive,
                    &mut first_child,
                    &mut next_sibling,
                );
            }
        } else {
            return -1;
        }
    }
    result
}
