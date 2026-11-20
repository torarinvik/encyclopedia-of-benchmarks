const MAX_OPERATIONS: usize = 64;
const MAX_ITEMS: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 194;

fn rank_of(node: i32, ranks: &[i32; MAX_OPERATIONS]) -> i32 {
    if node < 0 { -1 } else { ranks[node as usize] }
}

fn minimum_root(
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    parents: &[i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
) -> Option<usize> {
    let mut best = None;
    for node in 0..node_count {
        if alive[node] && parents[node] == -1 {
            if let Some(current) = best {
                if (keys[node], items[node], node) < (keys[current], items[current], current) {
                    best = Some(node);
                }
            } else {
                best = Some(node);
            }
        }
    }
    best
}

fn fair_link(
    first: usize,
    second: usize,
    keys: &[i64; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    left: &mut [i32; MAX_OPERATIONS],
    right: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
) {
    let (winner, loser) = if (keys[first], items[first], first) <= (keys[second], items[second], second) {
        (first, second)
    } else {
        (second, first)
    };
    let old_left = left[winner];
    left[winner] = loser as i32;
    parents[loser] = winner as i32;
    right[loser] = old_left;
    if old_left >= 0 {
        parents[old_left as usize] = loser as i32;
    }
    ranks[winner] += 1;
}

fn consolidate_fair_roots(
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    left: &mut [i32; MAX_OPERATIONS],
    right: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
) {
    loop {
        let mut duplicate_rank = None;
        for first in 0..node_count {
            if !alive[first] || parents[first] != -1 {
                continue;
            }
            for second in first + 1..node_count {
                if alive[second]
                    && parents[second] == -1
                    && ranks[second] == ranks[first]
                    && duplicate_rank.map_or(true, |rank| ranks[first] < rank)
                {
                    duplicate_rank = Some(ranks[first]);
                }
            }
        }
        let Some(rank) = duplicate_rank else { break };
        let mut roots = (None, None);
        for node in 0..node_count {
            if alive[node] && parents[node] == -1 && ranks[node] == rank {
                if roots.0.is_none() {
                    roots.0 = Some(node);
                } else {
                    roots.1 = Some(node);
                    break;
                }
            }
        }
        let (Some(first), Some(second)) = roots else { break };
        fair_link(first, second, keys, items, left, right, ranks, parents);
    }
}

#[no_mangle]
pub unsafe extern "C" fn rank_pairing_heap(input: *const i64, length: usize) -> i64 {
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
    let mut items = [-1i32; MAX_OPERATIONS];
    let mut ranks = [0i32; MAX_OPERATIONS];
    let mut left = [-1i32; MAX_OPERATIONS];
    let mut right = [-1i32; MAX_OPERATIONS];
    let mut parents = [-2i32; MAX_OPERATIONS];
    let mut alive = [false; MAX_OPERATIONS];
    let mut item_nodes = [-1i32; MAX_ITEMS];
    let mut active = [false; MAX_ITEMS];
    let mut node_count = 0usize;
    let mut result = 0i64;

    for operation_index in 0..operation_count {
        let offset = 1 + 3 * operation_index;
        let opcode = *input.add(offset);
        let item_value = *input.add(offset + 1);
        let value = *input.add(offset + 2);
        if opcode == 1 {
            if !(0..MAX_ITEMS as i64).contains(&item_value) || !(0..=1_000_000).contains(&value) {
                return -1;
            }
            let item = item_value as usize;
            if active[item] || node_count >= MAX_OPERATIONS {
                return -1;
            }
            let node = node_count;
            node_count += 1;
            keys[node] = value;
            items[node] = item as i32;
            ranks[node] = 0;
            left[node] = -1;
            right[node] = -1;
            parents[node] = -1;
            alive[node] = true;
            item_nodes[item] = node as i32;
            active[item] = true;
        } else if opcode == 2 {
            if !(0..MAX_ITEMS as i64).contains(&item_value) || !(0..=1_000_000).contains(&value) {
                return -1;
            }
            let item = item_value as usize;
            if !active[item] {
                return -1;
            }
            let node = item_nodes[item] as usize;
            if value >= keys[node] {
                return -1;
            }
            keys[node] = value;
            if parents[node] >= 0 {
                let old_parent = parents[node] as usize;
                let next_sibling = right[node];
                if left[old_parent] == node as i32 {
                    left[old_parent] = next_sibling;
                } else {
                    right[old_parent] = next_sibling;
                }
                if next_sibling >= 0 {
                    parents[next_sibling as usize] = old_parent as i32;
                }
                parents[node] = -1;
                right[node] = -1;
                ranks[node] = rank_of(left[node], &ranks) + 1;

                let mut ancestor = old_parent as i32;
                while ancestor >= 0 {
                    let ancestor_index = ancestor as usize;
                    if parents[ancestor_index] < 0 {
                        ranks[ancestor_index] = rank_of(left[ancestor_index], &ranks) + 1;
                        break;
                    }
                    let left_rank = rank_of(left[ancestor_index], &ranks);
                    let right_rank = rank_of(right[ancestor_index], &ranks);
                    let new_rank = if left_rank != right_rank {
                        left_rank.max(right_rank)
                    } else {
                        left_rank + 1
                    };
                    if new_rank >= ranks[ancestor_index] {
                        break;
                    }
                    ranks[ancestor_index] = new_rank;
                    ancestor = parents[ancestor_index];
                }
            }
        } else if opcode == 3 {
            if item_value != 0 || value != 0 {
                return -1;
            }
            let Some(node) = minimum_root(node_count, &keys, &items, &parents, &alive) else {
                return -1;
            };
            let removed_item = items[node] as usize;
            result += (operation_index as i64 + 1) * (keys[node] + 1) + removed_item as i64;
            active[removed_item] = false;
            item_nodes[removed_item] = -1;
            let mut child = left[node];
            while child >= 0 {
                let child_index = child as usize;
                let next_sibling = right[child_index];
                right[child_index] = -1;
                parents[child_index] = -1;
                ranks[child_index] = rank_of(left[child_index], &ranks) + 1;
                child = next_sibling;
            }
            alive[node] = false;
            parents[node] = -2;
            left[node] = -1;
            right[node] = -1;
            items[node] = -1;
            consolidate_fair_roots(
                node_count, &keys, &items, &mut left, &mut right, &mut ranks, &mut parents, &alive,
            );
        } else if opcode == 4 {
            if item_value != 0 || value != 0 {
                return -1;
            }
            let Some(node) = minimum_root(node_count, &keys, &items, &parents, &alive) else {
                return -1;
            };
            result += (operation_index as i64 + 1) * (keys[node] + 1) + items[node] as i64;
        } else {
            return -1;
        }
    }
    result
}
