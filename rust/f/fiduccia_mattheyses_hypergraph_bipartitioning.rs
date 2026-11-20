const MAX_VERTICES: usize = 8;
const MAX_NETS: usize = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 112;

fn count_bits(value: usize) -> usize {
    value.count_ones() as usize
}

fn cut_size(net_masks: &[usize; MAX_NETS], net_sizes: &[usize; MAX_NETS], net_count: usize, partition: usize) -> usize {
    let mut cut = 0;
    for edge in 0..net_count {
        let in_a = count_bits(net_masks[edge] & partition);
        if in_a > 0 && in_a < net_sizes[edge] {
            cut += 1;
        }
    }
    cut
}

fn move_gain(
    vertex: usize,
    partition: usize,
    net_count: usize,
    net_masks: &[usize; MAX_NETS],
    net_sizes: &[usize; MAX_NETS],
) -> i32 {
    let vertex_bit = 1usize << vertex;
    let is_in_a = partition & vertex_bit != 0;
    let mut gain = 0i32;
    for edge in 0..net_count {
        if net_masks[edge] & vertex_bit != 0 {
            let before_a = count_bits(net_masks[edge] & partition);
            let after_a = if is_in_a { before_a - 1 } else { before_a + 1 };
            let before_cut = before_a > 0 && before_a < net_sizes[edge];
            let after_cut = after_a > 0 && after_a < net_sizes[edge];
            gain += before_cut as i32 - after_cut as i32;
        }
    }
    gain
}

#[no_mangle]
pub unsafe extern "C" fn fiduccia_mattheyses_hypergraph_bipartitioning(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_count_value = values[0];
    let net_count_value = values[1];
    let partition_value = values[2];
    if !(4..=MAX_VERTICES as i64).contains(&vertex_count_value)
        || vertex_count_value % 2 != 0
        || !(0..=MAX_NETS as i64).contains(&net_count_value)
    {
        return -1;
    }
    let vertex_count = vertex_count_value as usize;
    let net_count = net_count_value as usize;
    if partition_value < 0 || partition_value as u64 >= (1u64 << vertex_count) {
        return -1;
    }
    let initial_partition = partition_value as usize;
    if count_bits(initial_partition) != vertex_count / 2 {
        return -1;
    }

    let mut net_masks = [0usize; MAX_NETS];
    let mut net_sizes = [0usize; MAX_NETS];
    let mut offset = 3usize;
    for edge in 0..net_count {
        if offset >= length {
            return -1;
        }
        let degree_value = values[offset];
        if degree_value < 2 || degree_value > vertex_count as i64 {
            return -1;
        }
        let degree = degree_value as usize;
        if offset + 1 + degree > length {
            return -1;
        }
        let mut net_mask = 0usize;
        let mut previous_vertex = None;
        for item in 0..degree {
            let vertex_value = values[offset + 1 + item];
            if vertex_value < 0 || vertex_value >= vertex_count as i64 {
                return -1;
            }
            let vertex = vertex_value as usize;
            if let Some(previous) = previous_vertex {
                if vertex <= previous {
                    return -1;
                }
            }
            previous_vertex = Some(vertex);
            net_mask |= 1usize << vertex;
        }
        net_masks[edge] = net_mask;
        net_sizes[edge] = degree;
        offset += 1 + degree;
    }
    if offset != length {
        return -1;
    }

    let mut partition = initial_partition;
    let mut current_cut = cut_size(&net_masks, &net_sizes, net_count, partition);
    for _pass in 0..=net_count {
        let pass_start_cut = current_cut;
        let mut working_partition = partition;
        let mut working_a_size = count_bits(working_partition);
        let mut working_cut = current_cut;
        let mut best_partition = partition;
        let mut best_cut = current_cut;
        let mut locked = [false; MAX_VERTICES];

        for _move in 0..vertex_count {
            let mut bucket_counts = [0usize; 2 * MAX_NETS + 1];
            let mut buckets = [[0usize; MAX_VERTICES]; 2 * MAX_NETS + 1];
            for vertex in 0..vertex_count {
                if locked[vertex] {
                    continue;
                }
                let in_a = working_partition & (1usize << vertex) != 0;
                let resulting_a_size = if in_a { working_a_size - 1 } else { working_a_size + 1 };
                if resulting_a_size < vertex_count / 2 - 1
                    || resulting_a_size > vertex_count / 2 + 1
                {
                    continue;
                }
                let gain = move_gain(vertex, working_partition, net_count, &net_masks, &net_sizes);
                let bucket = (gain + net_count as i32) as usize;
                buckets[bucket][bucket_counts[bucket]] = vertex;
                bucket_counts[bucket] += 1;
            }

            let mut selected_vertex = None;
            let mut selected_balance = usize::MAX;
            for bucket in (0..=2 * net_count).rev() {
                if bucket_counts[bucket] == 0 {
                    continue;
                }
                for position in 0..bucket_counts[bucket] {
                    let vertex = buckets[bucket][position];
                    let in_a = working_partition & (1usize << vertex) != 0;
                    let resulting_a_size = if in_a { working_a_size - 1 } else { working_a_size + 1 };
                    let doubled_size = 2 * resulting_a_size;
                    let balance = if doubled_size >= vertex_count {
                        doubled_size - vertex_count
                    } else {
                        vertex_count - doubled_size
                    };
                    if selected_vertex.is_none()
                        || balance < selected_balance
                        || (balance == selected_balance && Some(vertex) < selected_vertex)
                    {
                        selected_vertex = Some(vertex);
                        selected_balance = balance;
                    }
                }
                if selected_vertex.is_some() {
                    break;
                }
            }
            let vertex = match selected_vertex {
                Some(vertex) => vertex,
                None => break,
            };

            locked[vertex] = true;
            working_partition ^= 1usize << vertex;
            if working_partition & (1usize << vertex) != 0 {
                working_a_size += 1;
            } else {
                working_a_size -= 1;
            }
            working_cut = cut_size(&net_masks, &net_sizes, net_count, working_partition);
            if working_cut < best_cut {
                best_cut = working_cut;
                best_partition = working_partition;
            }
        }

        if best_cut < pass_start_cut {
            partition = best_partition;
            current_cut = best_cut;
        } else {
            break;
        }
    }
    ((current_cut as i64) << 8) | partition as i64
}
