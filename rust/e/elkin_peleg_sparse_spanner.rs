use std::cmp::Ordering;
use std::slice;

const MAX_N: usize = 20;
const MAX_M: usize = MAX_N * (MAX_N - 1) / 2;
const MAX_INPUT: usize = 2 + 2 * MAX_M + 1;
const INF: usize = 1_000;

#[derive(Clone, Default)]
struct Cluster {
    center: usize,
    radius: usize,
    members: Vec<usize>,
    tree: Vec<u8>,
}

fn cluster_order(left: &Cluster, right: &Cluster) -> Ordering {
    left.center.cmp(&right.center).then_with(|| left.members.cmp(&right.members))
}

fn bfs_distances(graph: &[Vec<usize>], source: usize) -> Vec<usize> {
    let mut distance = vec![INF; graph.len()];
    let mut queue = Vec::with_capacity(graph.len());
    distance[source] = 0;
    queue.push(source);
    for head in 0..queue.len() {
        let vertex = queue[head];
        for &neighbor in &graph[vertex] {
            if distance[neighbor] == INF {
                distance[neighbor] = distance[vertex] + 1;
                queue.push(neighbor);
            }
        }
    }
    distance
}

fn all_distances(graph: &[Vec<usize>]) -> Vec<Vec<usize>> {
    (0..graph.len()).map(|source| bfs_distances(graph, source)).collect()
}

fn bfs_tree(graph: &[Vec<usize>], edge_index: &[Vec<i32>], allowed: &[u8],
            root: usize, edge_count: usize) -> (Vec<u8>, usize) {
    let mut distance = vec![INF; graph.len()];
    let mut parent = vec![usize::MAX; graph.len()];
    let mut queue = Vec::with_capacity(graph.len());
    distance[root] = 0;
    queue.push(root);
    for head in 0..queue.len() {
        let vertex = queue[head];
        for &neighbor in &graph[vertex] {
            if allowed[neighbor] != 0 && distance[neighbor] == INF {
                distance[neighbor] = distance[vertex] + 1;
                parent[neighbor] = vertex;
                queue.push(neighbor);
            }
        }
    }
    let mut tree = vec![0; edge_count];
    let mut radius = 0;
    for vertex in 0..graph.len() {
        if allowed[vertex] == 0 { continue; }
        radius = radius.max(distance[vertex]);
        if vertex != root {
            let edge = edge_index[vertex][parent[vertex]] as usize;
            tree[edge] = 1;
        }
    }
    (tree, radius)
}

fn set_distance(left: &Cluster, right: &Cluster, distance: &[Vec<usize>]) -> usize {
    let mut best = INF;
    for &u in &left.members {
        for &v in &right.members { best = best.min(distance[u][v]); }
    }
    best
}

fn connector(graph: &[Vec<usize>], edge_index: &[Vec<i32>], left: &Cluster,
             right: &Cluster, edge_count: usize) -> Vec<u8> {
    let mut best_distance = INF;
    let mut best_path: Vec<usize> = Vec::new();
    for &source in &left.members {
        let mut distance = vec![INF; graph.len()];
        let mut parent = vec![usize::MAX; graph.len()];
        let mut queue = Vec::with_capacity(graph.len());
        distance[source] = 0;
        queue.push(source);
        for head in 0..queue.len() {
            let vertex = queue[head];
            for &neighbor in &graph[vertex] {
                if distance[neighbor] == INF {
                    distance[neighbor] = distance[vertex] + 1;
                    parent[neighbor] = vertex;
                    queue.push(neighbor);
                }
            }
        }
        for &target in &right.members {
            if distance[target] > best_distance { continue; }
            let mut path = Vec::new();
            let mut vertex = target;
            loop {
                path.push(vertex);
                if vertex == source { break; }
                if parent[vertex] == usize::MAX { path.clear(); break; }
                vertex = parent[vertex];
            }
            if path.is_empty() { continue; }
            path.reverse();
            if distance[target] < best_distance ||
                (distance[target] == best_distance &&
                 (best_path.is_empty() || path.as_slice() < best_path.as_slice())) {
                best_distance = distance[target];
                best_path = path;
            }
        }
    }
    let mut result = vec![0; edge_count];
    for pair in best_path.windows(2) {
        result[edge_index[pair[0]][pair[1]] as usize] = 1;
    }
    result
}

fn down_part(n: usize, graph: &[Vec<usize>], edge_index: &[Vec<i32>], edge_count: usize)
    -> (Vec<Cluster>, Vec<u8>) {
    let mut uncovered = vec![1u8; n];
    let mut ground = Vec::new();
    let mut chosen = vec![0u8; edge_count];
    loop {
        let Some(root) = uncovered.iter().position(|&value| value != 0) else { break; };
        let mut members = vec![0u8; n];
        members[root] = 1;
        let mut size = 1usize;
        loop {
            let mut shell = members.clone();
            for vertex in 0..n {
                if members[vertex] != 0 {
                    for &neighbor in &graph[vertex] {
                        if uncovered[neighbor] != 0 { shell[neighbor] = 1; }
                    }
                }
            }
            let shell_size = shell.iter().filter(|&&value| value != 0).count();
            if shell_size == size || shell_size.pow(4) < n * size.pow(4) { break; }
            members = shell;
            size = shell_size;
        }
        let mut shell = members.clone();
        for vertex in 0..n {
            if members[vertex] != 0 {
                for &neighbor in &graph[vertex] {
                    if uncovered[neighbor] != 0 { shell[neighbor] = 1; }
                }
            }
        }
        let mut cluster = Cluster { center: root, ..Cluster::default() };
        cluster.members = (0..n).filter(|&v| members[v] != 0).collect();
        let (tree, radius) = bfs_tree(graph, edge_index, &members, root, edge_count);
        cluster.tree = tree;
        cluster.radius = radius;
        let (shell_tree, _) = bfs_tree(graph, edge_index, &shell, root, edge_count);
        for edge in 0..edge_count { chosen[edge] |= shell_tree[edge]; }
        ground.push(cluster);
        for v in 0..n { if members[v] != 0 { uncovered[v] = 0; } }
    }
    (ground, chosen)
}

fn supercluster(graph: &[Vec<usize>], edge_index: &[Vec<i32>], distance: &[Vec<usize>],
                clusters: &[Cluster], sigma: usize, delta: usize, edge_count: usize)
    -> (Vec<Cluster>, Vec<u8>) {
    let mut active = vec![true; clusters.len()];
    let mut merged = Vec::new();
    let mut chosen = vec![0u8; edge_count];
    loop {
        let mut center_id: Option<usize> = None;
        let mut neighborhoods = vec![Vec::<usize>::new(); clusters.len()];
        for candidate in 0..clusters.len() {
            if !active[candidate] { continue; }
            for other in 0..clusters.len() {
                if active[other] && set_distance(&clusters[candidate], &clusters[other], distance) <= delta {
                    neighborhoods[candidate].push(other);
                }
            }
            let improves_center = match center_id {
                None => true,
                Some(current) => cluster_order(&clusters[candidate], &clusters[current]) == Ordering::Less,
            };
            if neighborhoods[candidate].len() >= sigma && improves_center {
                center_id = Some(candidate);
            }
        }
        let Some(center) = center_id else { break; };
        let mut cluster = Cluster { center: clusters[center].center, ..Cluster::default() };
        cluster.tree = vec![0; edge_count];
        let mut members = vec![0u8; graph.len()];
        for &other in &neighborhoods[center] {
            active[other] = false;
            for &vertex in &clusters[other].members { members[vertex] = 1; }
            for edge in 0..edge_count { cluster.tree[edge] |= clusters[other].tree[edge]; }
            if other != center {
                let path = connector(graph, edge_index, &clusters[center], &clusters[other], edge_count);
                for edge in 0..edge_count { cluster.tree[edge] |= path[edge]; }
            }
        }
        cluster.members = (0..graph.len()).filter(|&v| members[v] != 0).collect();
        for edge in 0..edge_count { chosen[edge] |= cluster.tree[edge]; }
        merged.push(cluster);
    }
    let mut remaining: Vec<usize> = (0..clusters.len()).filter(|&i| active[i]).collect();
    remaining.sort_by(|&a, &b| cluster_order(&clusters[a], &clusters[b]));
    for i in 0..remaining.len() {
        for j in i + 1..remaining.len() {
            let left = &clusters[remaining[i]];
            let right = &clusters[remaining[j]];
            if set_distance(left, right, distance) <= delta {
                let path = connector(graph, edge_index, left, right, edge_count);
                for edge in 0..edge_count { chosen[edge] |= path[edge]; }
            }
        }
    }
    (merged, chosen)
}

fn ceil_fourth_root(value: usize) -> usize {
    let mut root = 1;
    while root.pow(4) < value { root += 1; }
    root
}

fn construct(n: usize, edges: &[(usize, usize)], edge_index: &[Vec<i32>]) -> Vec<u8> {
    let mut graph = vec![Vec::new(); n];
    for &(u, v) in edges { graph[u].push(v); graph[v].push(u); }
    for neighbors in &mut graph { neighbors.sort_unstable(); }
    let distance = all_distances(&graph);
    let (ground, mut chosen) = down_part(n, &graph, edge_index, edges.len());
    let level: Vec<Cluster> = ground.iter().filter(|cluster| cluster.radius == 1).cloned().collect();
    let (superclusters, additions) = supercluster(
        &graph, edge_index, &distance, &level, ceil_fourth_root(n), 16, edges.len());
    for edge in 0..edges.len() { chosen[edge] |= additions[edge]; }
    let mut final_clusters = superclusters;
    final_clusters.extend(ground.iter().filter(|cluster| cluster.radius == 2 || cluster.radius == 3).cloned());
    final_clusters.sort_by(cluster_order);
    for i in 0..final_clusters.len() {
        for j in i + 1..final_clusters.len() {
            if set_distance(&final_clusters[i], &final_clusters[j], &distance) <= 128 {
                let path = connector(&graph, edge_index, &final_clusters[i], &final_clusters[j], edges.len());
                for edge in 0..edges.len() { chosen[edge] |= path[edge]; }
            }
        }
    }
    chosen
}

#[no_mangle]
pub unsafe extern "C" fn elkin_peleg_sparse_spanner(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let (n64, m64) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let (n, m) = (n64 as usize, m64 as usize);
    let mut edges = Vec::with_capacity(m);
    let mut index = vec![vec![-1; n]; n];
    for edge in 0..m {
        let (u64, v64) = (values[2 + 2 * edge], values[3 + 2 * edge]);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        if index[u][v] >= 0 { return -1; }
        index[u][v] = edge as i32;
        index[v][u] = edge as i32;
        edges.push((u, v));
    }
    if output.is_null() || capacity < m { return -2; }
    let selected = construct(n, &edges, &index);
    let output_view = slice::from_raw_parts_mut(output, m);
    output_view.copy_from_slice(&selected);
    m as i64
}
