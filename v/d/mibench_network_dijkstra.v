module main

const max_nodes = 6
const max_queue_items = 1024
const none_cost = i64(9999)

struct QueueItem {
    node int
    distance i64
    previous int
}

@[export: 'mibench_network_dijkstra']
pub fn mibench_network_dijkstra(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 3 { return -1 }
    node_value := unsafe { input[0] }
    if node_value < 1 || node_value > max_nodes { return -1 }
    nodes := int(node_value)
    if length != usize(2 + nodes * nodes) { return -1 }
    source_value := unsafe { input[1] }
    if source_value < 0 || source_value >= node_value { return -1 }
    for index in 0 .. nodes * nodes {
        cost := unsafe { input[2 + index] }
        if cost != none_cost && (cost < 0 || cost > 31) { return -1 }
    }

    mut distance := [6]i64{}
    mut reachable := [6]bool{}
    mut queue := [1024]QueueItem{}
    for node in 0 .. nodes { distance[node] = none_cost }
    source := int(source_value)
    distance[source] = 0
    reachable[source] = true
    mut head := 0
    mut tail := 0
    queue[tail] = QueueItem{source, 0, int(none_cost)}
    tail++
    for head < tail {
        item := queue[head]
        head++
        for destination in 0 .. nodes {
            cost := unsafe { input[2 + item.node * nodes + destination] }
            if cost == none_cost { continue }
            candidate := item.distance + cost
            if !reachable[destination] || distance[destination] > candidate {
                distance[destination] = candidate
                reachable[destination] = true
                if tail >= max_queue_items { return -2 }
                queue[tail] = QueueItem{destination, candidate, item.node}
                tail++
            }
        }
    }
    mut checksum := i64(0)
    mut mask := u64(0)
    for node in 0 .. nodes {
        if reachable[node] {
            checksum += i64(node + 1) * distance[node]
            mask |= u64(1) << node
        }
    }
    return checksum + i64(mask)
}
