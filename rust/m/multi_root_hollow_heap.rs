const MAX_OPERATIONS: usize = 64;
const MAX_ITEMS: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 194;

fn minimum_root(
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    items: &[i32; MAX_OPERATIONS],
    parents: &[i32; MAX_OPERATIONS],
    alive: &[bool; MAX_OPERATIONS],
) -> Option<usize> {
    let mut best: Option<usize> = None;
    for node in 0..node_count {
        if alive[node] && parents[node] == -1 && items[node] >= 0 {
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

fn destroy_hollow_roots_and_consolidate(
    node_count: usize,
    keys: &[i64; MAX_OPERATIONS],
    items: &mut [i32; MAX_OPERATIONS],
    ranks: &mut [i32; MAX_OPERATIONS],
    parents: &mut [i32; MAX_OPERATIONS],
    alive: &mut [bool; MAX_OPERATIONS],
) {
    loop {
        let mut hollow_root = None;
        for node in 0..node_count {
            if alive[node] && parents[node] == -1 && items[node] == -1 {
                hollow_root = Some(node);
                break;
            }
        }
        let Some(root) = hollow_root else { break };
        for child in 0..node_count {
            if alive[child] && parents[child] == root as i32 {
                parents[child] = -1;
            }
        }
        alive[root] = false;
        parents[root] = -2;
    }

    loop {
        let mut duplicate_rank = None;
        for first in 0..node_count {
            if !alive[first] || parents[first] != -1 || items[first] < 0 {
                continue;
            }
            for second in first + 1..node_count {
                if alive[second]
                    && parents[second] == -1
                    && items[second] >= 0
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
            if alive[node] && parents[node] == -1 && items[node] >= 0 && ranks[node] == rank {
                if roots.0.is_none() {
                    roots.0 = Some(node);
                } else {
                    roots.1 = Some(node);
                    break;
                }
            }
        }
        let (Some(first), Some(second)) = roots else { break };
        let (winner, loser) = if (keys[first], items[first], first) <= (keys[second], items[second], second) {
            (first, second)
        } else {
            (second, first)
        };
        parents[loser] = winner as i32;
        ranks[winner] += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn multi_root_hollow_heap(input: *const i64, length: usize) -> i64 {
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
            parents[node] = -1;
            alive[node] = true;
            item_nodes[item] = node as i32;
            active[item] = true;
        } else if opcode == 2 {
            if !(0..MAX_ITEMS as i64).contains(&item_value) || !(0..=1_000_000).contains(&value) {
                return -1;
            }
            let item = item_value as usize;
            if !active[item] || node_count >= MAX_OPERATIONS {
                return -1;
            }
            let old_node = item_nodes[item] as usize;
            if value >= keys[old_node] {
                return -1;
            }
            let new_rank = (ranks[old_node] - 2).max(0);
            items[old_node] = -1;
            let new_node = node_count;
            node_count += 1;
            keys[new_node] = value;
            items[new_node] = item as i32;
            ranks[new_node] = new_rank;
            parents[new_node] = -1;
            alive[new_node] = true;
            for child in 0..new_node {
                if alive[child] && parents[child] == old_node as i32 && ranks[child] < new_rank {
                    parents[child] = new_node as i32;
                }
            }
            item_nodes[item] = new_node as i32;
        } else if opcode == 3 {
            if item_value != 0 || value != 0 {
                return -1;
            }
            let Some(node) = minimum_root(node_count, &keys, &items, &parents, &alive) else {
                return -1;
            };
            let item = items[node] as usize;
            active[item] = false;
            item_nodes[item] = -1;
            items[node] = -1;
            result += (operation_index as i64 + 1) * (keys[node] + 1) + item as i64;
            destroy_hollow_roots_and_consolidate(
                node_count, &keys, &mut items, &mut ranks, &mut parents, &mut alive,
            );
        } else if opcode == 4 {
            if item_value != 0 || value != 0 {
                return -1;
            }
            let Some(node) = minimum_root(node_count, &keys, &items, &parents, &alive) else {
                return -1;
            };
            result += (operation_index as i64 + 1) * (keys[node] + 1) + items[node] as i64;
        } else if opcode == 5 {
            if !(0..MAX_ITEMS as i64).contains(&item_value) || value != 0 {
                return -1;
            }
            let item = item_value as usize;
            if !active[item] {
                return -1;
            }
            let node = item_nodes[item] as usize;
            let was_minimum = minimum_root(node_count, &keys, &items, &parents, &alive) == Some(node);
            active[item] = false;
            item_nodes[item] = -1;
            items[node] = -1;
            if was_minimum {
                destroy_hollow_roots_and_consolidate(
                    node_count, &keys, &mut items, &mut ranks, &mut parents, &mut alive,
                );
            }
        } else {
            return -1;
        }
    }
    result
}
