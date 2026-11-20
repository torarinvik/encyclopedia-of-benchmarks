const MAX_N: usize = 32;
const MAX_OPERATIONS: usize = 64;
const MAX_LEVELS: usize = 6;
const MAX_PARSEABLE_LENGTH: usize = 98;

#[derive(Clone, Copy)]
struct Record {
    centroid: usize,
    branch: usize,
    distance: usize,
}

struct Context {
    n: usize,
    adjacency: [[bool; MAX_N]; MAX_N],
    blocked: [bool; MAX_N],
    subtree_size: [usize; MAX_N],
    records: [[Record; MAX_LEVELS]; MAX_N],
    record_count: [usize; MAX_N],
}

impl Context {
    fn component_size(&mut self, vertex: usize, parent: usize) -> usize {
        self.subtree_size[vertex] = 1;
        for neighbor in 0..self.n {
            if self.adjacency[vertex][neighbor]
                && neighbor != parent
                && !self.blocked[neighbor]
            {
                let child_size = self.component_size(neighbor, vertex);
                self.subtree_size[vertex] += child_size;
            }
        }
        self.subtree_size[vertex]
    }

    fn choose_centroid(&self, vertex: usize, parent: usize, total: usize) -> usize {
        for neighbor in 0..self.n {
            if self.adjacency[vertex][neighbor]
                && neighbor != parent
                && !self.blocked[neighbor]
                && self.subtree_size[neighbor] > total / 2
            {
                return self.choose_centroid(neighbor, vertex, total);
            }
        }
        vertex
    }

    fn record_component(
        &mut self,
        centroid: usize,
        vertex: usize,
        parent: usize,
        distance: usize,
        branch: usize,
        level: usize,
    ) {
        if level >= MAX_LEVELS {
            return;
        }
        self.records[vertex][level] = Record {
            centroid,
            branch: if vertex == centroid { self.n } else { branch },
            distance,
        };
        self.record_count[vertex] = level + 1;
        for neighbor in 0..self.n {
            if self.adjacency[vertex][neighbor]
                && neighbor != parent
                && !self.blocked[neighbor]
            {
                let next_branch = if vertex == centroid { neighbor } else { branch };
                self.record_component(
                    centroid,
                    neighbor,
                    vertex,
                    distance + 1,
                    next_branch,
                    level,
                );
            }
        }
    }

    fn build_centroids(&mut self, entry: usize, level: usize) {
        if level >= MAX_LEVELS {
            return;
        }
        let total = self.component_size(entry, MAX_N);
        let centroid = self.choose_centroid(entry, MAX_N, total);
        self.record_component(centroid, centroid, MAX_N, 0, self.n, level);
        self.blocked[centroid] = true;
        for neighbor in 0..self.n {
            if self.adjacency[centroid][neighbor] && !self.blocked[neighbor] {
                self.build_centroids(neighbor, level + 1);
            }
        }
    }
}

fn recompute_branch(
    context: &Context,
    active: &[bool; MAX_N],
    best: &mut [[i32; MAX_N + 1]; MAX_N],
    centroid: usize,
    branch: usize,
) {
    best[centroid][branch] = -1;
    for vertex in 0..context.n {
        if !active[vertex] {
            continue;
        }
        for record in 0..context.record_count[vertex] {
            let entry = context.records[vertex][record];
            if entry.centroid == centroid && entry.branch == branch {
                best[centroid][branch] = best[centroid][branch].max(entry.distance as i32);
            }
        }
    }
}

fn active_diameter(n: usize, best: &[[i32; MAX_N + 1]; MAX_N]) -> i32 {
    let mut answer = 0;
    for centroid in 0..n {
        let (mut first, mut second) = (-1, -1);
        for branch in 0..=n {
            let distance = best[centroid][branch];
            if distance > first {
                second = first;
                first = distance;
            } else if distance > second {
                second = distance;
            }
        }
        if second >= 0 {
            answer = answer.max(first + second);
        }
    }
    answer
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_centroid_active_set_diameter(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let operation_count_value = values[1];
    if n_value < 1
        || n_value > MAX_N as i64
        || operation_count_value < 0
        || operation_count_value > MAX_OPERATIONS as i64
    {
        return -1;
    }
    let n = n_value as usize;
    let operation_count = operation_count_value as usize;
    if length != n + 1 + operation_count {
        return -1;
    }

    let blank_record = Record {
        centroid: 0,
        branch: 0,
        distance: 0,
    };
    let mut context = Context {
        n,
        adjacency: [[false; MAX_N]; MAX_N],
        blocked: [false; MAX_N],
        subtree_size: [0; MAX_N],
        records: [[blank_record; MAX_LEVELS]; MAX_N],
        record_count: [0; MAX_N],
    };
    for vertex in 1..n {
        let parent_value = values[vertex + 1];
        if parent_value < 0 || parent_value >= vertex as i64 {
            return -1;
        }
        let parent = parent_value as usize;
        context.adjacency[parent][vertex] = true;
        context.adjacency[vertex][parent] = true;
    }
    for operation in &values[n + 1..] {
        if *operation != -1 && (*operation < 0 || *operation >= n as i64) {
            return -1;
        }
    }

    context.build_centroids(0, 0);
    let mut best = [[-1i32; MAX_N + 1]; MAX_N];
    let mut active = [false; MAX_N];
    let mut checksum = 0i64;
    let mut query_number = 0i64;
    for operation in &values[n + 1..] {
        if *operation == -1 {
            query_number += 1;
            checksum += query_number * (active_diameter(n, &best) as i64 + 1);
            continue;
        }
        let vertex = *operation as usize;
        active[vertex] = !active[vertex];
        for record in 0..context.record_count[vertex] {
            let entry = context.records[vertex][record];
            if active[vertex] {
                best[entry.centroid][entry.branch] = best[entry.centroid][entry.branch]
                    .max(entry.distance as i32);
            } else if best[entry.centroid][entry.branch] == entry.distance as i32 {
                recompute_branch(&context, &active, &mut best, entry.centroid, entry.branch);
            }
        }
    }
    checksum
}
