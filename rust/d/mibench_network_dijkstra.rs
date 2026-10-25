const MAX_NODES: usize = 6;
const MAX_QUEUE_ITEMS: usize = 1024;
const NONE: i64 = 9999;
#[derive(Clone, Copy, Default)] struct QueueItem { node: usize, distance: i64, previous: i64 }

#[no_mangle]
pub unsafe extern "C" fn mibench_network_dijkstra(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let node_value = *input;
    if !(1..=MAX_NODES as i64).contains(&node_value) { return -1; }
    let nodes = node_value as usize;
    if length != 2 + nodes * nodes { return -1; }
    let source_value = *input.add(1);
    if source_value < 0 || source_value as usize >= nodes { return -1; }
    for index in 0..nodes * nodes {
        let cost = *input.add(2 + index);
        if cost != NONE && !(0..=31).contains(&cost) { return -1; }
    }

    let mut distance = [NONE; MAX_NODES];
    let mut reachable = [false; MAX_NODES];
    let mut queue = [QueueItem::default(); MAX_QUEUE_ITEMS];
    let source = source_value as usize;
    distance[source] = 0;
    reachable[source] = true;
    let (mut head, mut tail) = (0usize, 0usize);
    queue[tail] = QueueItem { node: source, distance: 0, previous: NONE };
    tail += 1;
    while head < tail {
        let item = queue[head];
        head += 1;
        for destination in 0..nodes {
            let cost = *input.add(2 + item.node * nodes + destination);
            if cost == NONE { continue; }
            let candidate = item.distance + cost;
            if !reachable[destination] || distance[destination] > candidate {
                distance[destination] = candidate;
                reachable[destination] = true;
                if tail >= MAX_QUEUE_ITEMS { return -2; }
                queue[tail] = QueueItem { node: destination, distance: candidate, previous: item.node as i64 };
                tail += 1;
            }
        }
    }
    let mut checksum = 0i64;
    let mut mask = 0u64;
    for node in 0..nodes {
        if reachable[node] {
            checksum += (node as i64 + 1) * distance[node];
            mask |= 1u64 << node;
        }
    }
    checksum + mask as i64
}
