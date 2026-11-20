const MAX_KEYS: usize = 256;
const MAX_QUERIES: usize = 256;
const UNIVERSE_BITS: usize = 16;
const BUCKET_SIZE: usize = 16;
const MAX_BUCKETS: usize = MAX_KEYS / BUCKET_SIZE;
const MAX_TRIE_NODES: usize = 1 + MAX_BUCKETS * UNIVERSE_BITS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 515;

#[derive(Clone, Copy)]
struct TrieNode {
    child: [i32; 2],
    min_rank: i32,
    leaf_rank: i32,
}

impl TrieNode {
    const EMPTY: Self = Self {
        child: [-1, -1],
        min_rank: -1,
        leaf_rank: -1,
    };
}

fn successor_bucket(nodes: &[TrieNode; MAX_TRIE_NODES], bucket_count: usize, query: i64) -> usize {
    let mut node = 0usize;
    let mut best_successor = -1i32;
    let mut path_alive = true;
    for bit in (0..UNIVERSE_BITS).rev() {
        let direction = ((query as u64 >> bit) & 1) as usize;
        if direction == 0 {
            let right = nodes[node].child[1];
            if right >= 0 {
                best_successor = nodes[right as usize].min_rank;
            }
        }
        let next = nodes[node].child[direction];
        if next < 0 {
            path_alive = false;
            break;
        }
        node = next as usize;
    }
    if path_alive && nodes[node].leaf_rank >= 0 {
        return nodes[node].leaf_rank as usize;
    }
    if best_successor >= 0 {
        return best_successor as usize;
    }
    bucket_count - 1
}

#[no_mangle]
pub unsafe extern "C" fn y_fast_trie_static_predecessor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = core::slice::from_raw_parts(input, length);
    let (key_count_value, query_count_value) = (values[0], values[1]);
    if !(0..=MAX_KEYS as i64).contains(&key_count_value)
        || !(0..=MAX_QUERIES as i64).contains(&query_count_value)
    {
        return -1;
    }
    let (key_count, query_count) = (key_count_value as usize, query_count_value as usize);
    if length != 2 + key_count + query_count {
        return -1;
    }

    let mut keys = [0i64; MAX_KEYS];
    for index in 0..key_count {
        keys[index] = values[2 + index];
        if !(0..=65535).contains(&keys[index]) {
            return -1;
        }
    }
    keys[..key_count].sort_unstable();
    for index in 1..key_count {
        if keys[index] == keys[index - 1] {
            return -1;
        }
    }
    for index in 0..query_count {
        let query = values[2 + key_count + index];
        if !(0..=65535).contains(&query) {
            return -1;
        }
    }
    if key_count == 0 || query_count == 0 {
        return 0;
    }

    let bucket_count = (key_count + BUCKET_SIZE - 1) / BUCKET_SIZE;
    let mut nodes = [TrieNode::EMPTY; MAX_TRIE_NODES];
    let mut node_count = 1usize;
    for bucket in 0..bucket_count {
        let bucket_start = bucket * BUCKET_SIZE;
        let bucket_end = (bucket_start + BUCKET_SIZE).min(key_count);
        let separator = keys[bucket_end - 1] as u64;
        let mut node = 0usize;
        if nodes[node].min_rank < 0 {
            nodes[node].min_rank = bucket as i32;
        }
        for bit in (0..UNIVERSE_BITS).rev() {
            let direction = ((separator >> bit) & 1) as usize;
            let mut next = nodes[node].child[direction];
            if next < 0 {
                next = node_count as i32;
                node_count += 1;
                nodes[node].child[direction] = next;
                nodes[next as usize] = TrieNode::EMPTY;
            }
            node = next as usize;
            if nodes[node].min_rank < 0 {
                nodes[node].min_rank = bucket as i32;
            }
        }
        nodes[node].leaf_rank = bucket as i32;
    }

    let mut checksum = 0i64;
    for query_index in 0..query_count {
        let query = values[2 + key_count + query_index];
        let bucket = successor_bucket(&nodes, bucket_count, query);
        let bucket_start = bucket * BUCKET_SIZE;
        let bucket_end = (bucket_start + BUCKET_SIZE).min(key_count);
        let mut low = bucket_start;
        let mut high = bucket_end;
        while low < high {
            let middle = low + (high - low) / 2;
            if keys[middle] < query {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        let lower_bound = low;

        let predecessor = if lower_bound > bucket_start {
            keys[lower_bound - 1]
        } else if bucket > 0 {
            keys[bucket_start - 1]
        } else {
            -1
        };

        let mut successor_index = lower_bound;
        if successor_index < bucket_end && keys[successor_index] == query {
            successor_index += 1;
        }
        let successor = if successor_index < bucket_end {
            keys[successor_index]
        } else if bucket + 1 < bucket_count {
            keys[bucket_end]
        } else {
            -1
        };

        checksum += (query_index as i64 + 1)
            * ((predecessor + 1) + 65_537 * (successor + 1));
    }
    checksum
}
