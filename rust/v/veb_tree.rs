const MAX_COUNT: usize = 256;
const MAX_INPUT_VALUES: usize = 771;
const MAX_OUTPUT_BYTES: usize = 1024;
const MAX_TREE_NODES: usize = 358;
const MAX_CLUSTERS: usize = 16;

#[derive(Clone, Copy)]
struct VebNode {
    universe: u16,
    low_bits: u8,
    cluster_count: u8,
    minimum: i32,
    maximum: i32,
    summary: i32,
    clusters: [i32; MAX_CLUSTERS],
}

impl VebNode {
    const EMPTY: Self = Self {
        universe: 0,
        low_bits: 0,
        cluster_count: 0,
        minimum: -1,
        maximum: 0,
        summary: -1,
        clusters: [0; MAX_CLUSTERS],
    };
}

fn initialize(nodes: &mut [VebNode; MAX_TREE_NODES], next: &mut usize, universe: u32) -> i32 {
    let id = *next as i32;
    *next += 1;
    nodes[id as usize] = VebNode { universe: universe as u16, ..VebNode::EMPTY };
    if universe > 2 {
        let exponent = 31 - universe.leading_zeros();
        let low_bits = exponent / 2;
        let low_size = 1u32 << low_bits;
        let cluster_count = universe / low_size;
        nodes[id as usize].low_bits = low_bits as u8;
        nodes[id as usize].cluster_count = cluster_count as u8;
        let summary = initialize(nodes, next, cluster_count);
        nodes[id as usize].summary = summary;
        for index in 0..cluster_count {
            let child = initialize(nodes, next, low_size);
            nodes[id as usize].clusters[index as usize] = child;
        }
    }
    id
}

fn contains(nodes: &[VebNode; MAX_TREE_NODES], id: i32, value: u32) -> bool {
    let node = nodes[id as usize];
    if node.minimum < 0 { return false; }
    if node.minimum as u32 == value || node.maximum as u32 == value { return true; }
    if node.universe == 2 { return false; }
    let low_size = 1u32 << node.low_bits;
    let high = value >> node.low_bits;
    let low = value & (low_size - 1);
    contains(nodes, node.clusters[high as usize], low)
}

fn insert(nodes: &mut [VebNode; MAX_TREE_NODES], id: i32, mut value: u32) {
    if contains(nodes, id, value) { return; }
    if nodes[id as usize].minimum < 0 {
        nodes[id as usize].minimum = value as i32;
        nodes[id as usize].maximum = value as i32;
        return;
    }
    if value < nodes[id as usize].minimum as u32 {
        let old_minimum = nodes[id as usize].minimum as u32;
        nodes[id as usize].minimum = value as i32;
        value = old_minimum;
    }
    if nodes[id as usize].universe > 2 {
        let low_bits = nodes[id as usize].low_bits;
        let low_size = 1u32 << low_bits;
        let high = value >> low_bits;
        let low = value & (low_size - 1);
        let summary = nodes[id as usize].summary;
        let cluster = nodes[id as usize].clusters[high as usize];
        if nodes[cluster as usize].minimum < 0 {
            insert(nodes, summary, high);
            nodes[cluster as usize].minimum = low as i32;
            nodes[cluster as usize].maximum = low as i32;
        } else {
            insert(nodes, cluster, low);
        }
    }
    if value > nodes[id as usize].maximum as u32 {
        nodes[id as usize].maximum = value as i32;
    }
}

fn successor(nodes: &[VebNode; MAX_TREE_NODES], id: i32, value: u32) -> i32 {
    let node = nodes[id as usize];
    if node.minimum < 0 { return -1; }
    if value < node.minimum as u32 { return node.minimum; }
    if node.universe == 2 { return if value == 0 && node.maximum == 1 { 1 } else { -1 }; }
    let low_size = 1u32 << node.low_bits;
    let high = value >> node.low_bits;
    let low = value & (low_size - 1);
    let cluster = node.clusters[high as usize];
    if nodes[cluster as usize].minimum >= 0 && low < nodes[cluster as usize].maximum as u32 {
        let next_low = successor(nodes, cluster, low);
        if next_low < 0 { return -1; }
        return (high * low_size) as i32 + next_low;
    }
    let next_cluster = successor(nodes, node.summary, high);
    if next_cluster < 0 { return -1; }
    let next_minimum = nodes[node.clusters[next_cluster as usize] as usize].minimum;
    if next_minimum < 0 { return -1; }
    next_cluster * low_size as i32 + next_minimum
}

fn predecessor(nodes: &[VebNode; MAX_TREE_NODES], id: i32, value: u32) -> i32 {
    let node = nodes[id as usize];
    if node.minimum < 0 || value <= node.minimum as u32 { return -1; }
    if value > node.maximum as u32 { return node.maximum; }
    if node.universe == 2 { return if value == 1 && node.minimum == 0 { 0 } else { -1 }; }
    let low_size = 1u32 << node.low_bits;
    let high = value >> node.low_bits;
    let low = value & (low_size - 1);
    let cluster = node.clusters[high as usize];
    if nodes[cluster as usize].minimum >= 0 && low > nodes[cluster as usize].minimum as u32 {
        let previous_low = predecessor(nodes, cluster, low);
        if previous_low >= 0 { return (high * low_size) as i32 + previous_low; }
    }
    let previous_cluster = predecessor(nodes, node.summary, high);
    if previous_cluster < 0 { return node.minimum; }
    let previous_maximum = nodes[node.clusters[previous_cluster as usize] as usize].maximum;
    if previous_maximum < 0 { return -1; }
    previous_cluster * low_size as i32 + previous_maximum
}

#[no_mangle]
pub unsafe extern "C" fn veb_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES + 1 { return -1; }
    let requested = *input;
    let insert_count = *input.add(1);
    let query_count = *input.add(2);
    if !(2..=256).contains(&requested) || !(0..=MAX_COUNT as i64).contains(&insert_count)
        || !(0..=MAX_COUNT as i64).contains(&query_count) { return -1; }
    let requested = requested as u32;
    let insert_count = insert_count as usize;
    let query_count = query_count as usize;
    if length != 3 + insert_count + 2 * query_count { return -1; }
    for index in 0..insert_count {
        let value = *input.add(3 + index);
        if value < 0 || value >= requested as i64 { return -1; }
    }
    for index in 0..query_count {
        let opcode = *input.add(3 + insert_count + 2 * index);
        let key = *input.add(4 + insert_count + 2 * index);
        if !(0..=4).contains(&opcode) || key < 0 || key >= requested as i64 { return -1; }
    }
    let needed = query_count * 4;
    if needed > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < needed { return -2; }

    let mut rounded = 1u32;
    while rounded < requested { rounded <<= 1; }
    let mut nodes = [VebNode::EMPTY; MAX_TREE_NODES];
    let mut next = 0usize;
    let root = initialize(&mut nodes, &mut next, rounded);
    for index in 0..insert_count { insert(&mut nodes, root, *input.add(3 + index) as u32); }
    let mut result = [0u8; MAX_OUTPUT_BYTES];
    for index in 0..query_count {
        let opcode = *input.add(3 + insert_count + 2 * index);
        let key = *input.add(4 + insert_count + 2 * index) as u32;
        let value = match opcode {
            0 => if contains(&nodes, root, key) { 1 } else { 0 },
            1 => successor(&nodes, root, key),
            2 => predecessor(&nodes, root, key),
            3 => nodes[root as usize].minimum,
            _ => if nodes[root as usize].minimum < 0 { 0 } else { nodes[root as usize].maximum },
        } as u32;
        result[4 * index..4 * index + 4].copy_from_slice(&value.to_le_bytes());
    }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, needed);
    needed as i64
}
