const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 87;

type Adjacency = [[i64; MAX_VERTICES]; MAX_VERTICES];

fn least_vertex(mask: usize) -> usize {
    for vertex in 0..MAX_VERTICES {
        if mask & (1usize << vertex) != 0 {
            return vertex;
        }
    }
    MAX_VERTICES
}

fn modularity_score(
    adjacency: &Adjacency,
    node_count: usize,
    labels: &[usize; MAX_VERTICES],
) -> i64 {
    let mut degrees = [0i64; MAX_VERTICES];
    let mut community_degrees = [0i64; MAX_VERTICES];
    let mut total_degree = 0i64;
    let mut internal_directed_weight = 0i64;
    for vertex in 0..node_count {
        for other in 0..node_count {
            let weight = adjacency[vertex][other];
            degrees[vertex] += weight;
            if labels[vertex] == labels[other] {
                internal_directed_weight += weight;
            }
        }
        total_degree += degrees[vertex];
        community_degrees[labels[vertex]] += degrees[vertex];
    }
    let squared_community_degrees: i64 = community_degrees
        .iter()
        .map(|degree| degree * degree)
        .sum();
    total_degree * internal_directed_weight - squared_community_degrees
}

fn community_key(
    target: usize,
    node_count: usize,
    labels: &[usize; MAX_VERTICES],
    masks: &[usize; MAX_VERTICES],
) -> usize {
    let mut key = MAX_VERTICES;
    for node in 0..node_count {
        if labels[node] == target {
            key = key.min(least_vertex(masks[node]));
        }
    }
    key
}

#[no_mangle]
pub unsafe extern "C" fn louvain_multilevel_community_detection(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_count_value = values[0];
    let edge_count_value = values[1];
    if !(2..=MAX_VERTICES as i64).contains(&vertex_count_value)
        || !(1..=MAX_EDGES as i64).contains(&edge_count_value)
    {
        return -1;
    }
    let vertex_count = vertex_count_value as usize;
    let edge_count = edge_count_value as usize;
    if edge_count > vertex_count * (vertex_count - 1) / 2
        || length != 2 + 3 * edge_count
    {
        return -1;
    }

    let mut adjacency = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    let mut previous_edge: Option<(usize, usize)> = None;
    for edge in 0..edge_count {
        let offset = 2 + 3 * edge;
        let u_value = values[offset];
        let v_value = values[offset + 1];
        let weight = values[offset + 2];
        if u_value < 0
            || u_value >= vertex_count as i64
            || v_value < 0
            || v_value >= vertex_count as i64
            || u_value >= v_value
            || !(1..=7).contains(&weight)
        {
            return -1;
        }
        let (u, v) = (u_value as usize, v_value as usize);
        if let Some((previous_u, previous_v)) = previous_edge {
            if u < previous_u || (u == previous_u && v <= previous_v) {
                return -1;
            }
        }
        previous_edge = Some((u, v));
        adjacency[u][v] = weight;
        adjacency[v][u] = weight;
    }

    let mut masks = [0usize; MAX_VERTICES];
    let mut node_count = vertex_count;
    for node in 0..node_count {
        masks[node] = 1usize << node;
    }

    let mut final_masks = [0usize; MAX_VERTICES];
    let final_community_count: usize;
    loop {
        let mut labels = [0usize; MAX_VERTICES];
        for node in 0..node_count {
            labels[node] = node;
        }

        let mut any_moves = false;
        loop {
            let mut sweep_moved = false;
            for node in 0..node_count {
                let current_score = modularity_score(&adjacency, node_count, &labels);
                let mut best_score = current_score;
                let mut best_target = None;
                let mut best_target_key = MAX_VERTICES;
                let mut seen_targets = [false; MAX_VERTICES];
                for other in 0..node_count {
                    if other == node || adjacency[node][other] <= 0 {
                        continue;
                    }
                    let target = labels[other];
                    if target == labels[node] || seen_targets[target] {
                        continue;
                    }
                    seen_targets[target] = true;
                    let mut candidate_labels = labels;
                    candidate_labels[node] = target;
                    let candidate_score = modularity_score(&adjacency, node_count, &candidate_labels);
                    if candidate_score <= current_score {
                        continue;
                    }
                    let target_key = community_key(target, node_count, &labels, &masks);
                    if best_target.is_none()
                        || candidate_score > best_score
                        || (candidate_score == best_score && target_key < best_target_key)
                    {
                        best_score = candidate_score;
                        best_target = Some(target);
                        best_target_key = target_key;
                    }
                }
                if let Some(target) = best_target {
                    labels[node] = target;
                    sweep_moved = true;
                    any_moves = true;
                }
            }
            if !sweep_moved {
                break;
            }
        }

        if !any_moves {
            for node in 0..node_count {
                final_masks[node] = masks[node];
            }
            final_community_count = node_count;
            break;
        }

        let mut group_labels = [0usize; MAX_VERTICES];
        let mut group_keys = [0usize; MAX_VERTICES];
        let mut group_count = 0usize;
        for node in 0..node_count {
            let label = labels[node];
            let mut found = false;
            for group in 0..group_count {
                if group_labels[group] == label {
                    found = true;
                    break;
                }
            }
            if !found {
                group_labels[group_count] = label;
                group_keys[group_count] = community_key(label, node_count, &labels, &masks);
                group_count += 1;
            }
        }

        for position in 1..group_count {
            let label = group_labels[position];
            let key = group_keys[position];
            let mut insertion = position;
            while insertion > 0 && key < group_keys[insertion - 1] {
                group_labels[insertion] = group_labels[insertion - 1];
                group_keys[insertion] = group_keys[insertion - 1];
                insertion -= 1;
            }
            group_labels[insertion] = label;
            group_keys[insertion] = key;
        }

        let mut label_to_group = [usize::MAX; MAX_VERTICES];
        for group in 0..group_count {
            label_to_group[group_labels[group]] = group;
        }
        let mut next_masks = [0usize; MAX_VERTICES];
        let mut next_adjacency = [[0i64; MAX_VERTICES]; MAX_VERTICES];
        for node in 0..node_count {
            let group = label_to_group[labels[node]];
            next_masks[group] |= masks[node];
        }
        for left in 0..node_count {
            let left_group = label_to_group[labels[left]];
            for right in 0..node_count {
                let right_group = label_to_group[labels[right]];
                next_adjacency[left_group][right_group] += adjacency[left][right];
            }
        }
        masks = next_masks;
        adjacency = next_adjacency;
        node_count = group_count;
    }

    let mut original_labels = [0usize; MAX_VERTICES];
    for community in 0..final_community_count {
        let label = least_vertex(final_masks[community]);
        for vertex in 0..vertex_count {
            if final_masks[community] & (1usize << vertex) != 0 {
                original_labels[vertex] = label;
            }
        }
    }
    let mut packed = (final_community_count as i64) << 24;
    for vertex in 0..vertex_count {
        packed |= (original_labels[vertex] as i64) << (3 * vertex);
    }
    packed
}
