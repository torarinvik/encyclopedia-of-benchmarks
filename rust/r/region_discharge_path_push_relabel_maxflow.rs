const NMAX: usize = 8;
const MMAX: usize = 12;
const KMAX: usize = 4;
const INPUT_MAX: usize = 50;

fn reaches(n: usize, allowed: &[[bool; NMAX]; NMAX], residual: &[[i64; NMAX]; NMAX],
           start: usize, target: &[bool; NMAX]) -> bool {
    if target[start] { return true; }
    let mut seen = [false; NMAX];
    let mut queue = [0usize; NMAX];
    let mut head = 0usize;
    let mut tail = 0usize;
    seen[start] = true;
    queue[tail] = start;
    tail += 1;
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            if !seen[v] && allowed[u][v] && residual[u][v] > 0 {
                if target[v] { return true; }
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    false
}

fn find_path(n: usize, in_region: &[bool; NMAX], allowed: &[[bool; NMAX]; NMAX],
             residual: &[[i64; NMAX]; NMAX], target: &[bool; NMAX],
             excess: &[i64; NMAX], parent: &mut [isize; NMAX]) -> isize {
    *parent = [-1; NMAX];
    let mut queue = [0usize; NMAX];
    let mut head = 0usize;
    let mut tail = 0usize;
    for v in 0..n {
        if in_region[v] && excess[v] > 0 {
            parent[v] = v as isize;
            queue[tail] = v;
            tail += 1;
        }
    }
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            if parent[v] >= 0 || !allowed[u][v] || residual[u][v] <= 0 { continue; }
            parent[v] = u as isize;
            if target[v] { return v as isize; }
            queue[tail] = v;
            tail += 1;
        }
    }
    -1
}

fn discharge(n: usize, region_id: usize, source: usize, sink: usize,
             boundary_count: usize, regions: &[i64; NMAX],
             residual: &mut [[i64; NMAX]; NMAX], excess: &mut [i64; NMAX],
             labels: &mut [usize; NMAX], mut flow: i64,
             boundary_by_region: &[[bool; NMAX]; KMAX]) -> i64 {
    let mut in_region = [false; NMAX];
    let mut external = [false; NMAX];
    let mut inside_terminal = [false; NMAX];
    for v in 0..n {
        in_region[v] = v != source && v != sink && regions[v] == region_id as i64;
        external[v] = boundary_by_region[region_id][v];
        inside_terminal[v] = in_region[v] || v == source || v == sink;
    }
    let mut allowed = [[false; NMAX]; NMAX];
    let mut local = [[0i64; NMAX]; NMAX];
    for u in 0..n { for v in 0..n {
        allowed[u][v] = (inside_terminal[u] && inside_terminal[v])
            || (in_region[u] && external[v]) || (external[u] && in_region[v]);
        if allowed[u][v] && !(external[u] && in_region[v]) { local[u][v] = residual[u][v]; }
    } }
    for stage in 0..=boundary_count {
        let mut target = [false; NMAX];
        target[sink] = true;
        for v in 0..n { if external[v] && labels[v] < stage { target[v] = true; } }
        loop {
            let mut parent = [-1isize; NMAX];
            let finish_raw = find_path(n, &in_region, &allowed, &local, &target, excess, &mut parent);
            if finish_raw < 0 { break; }
            let finish = finish_raw as usize;
            let mut path = [0usize; NMAX];
            let mut path_len = 0usize;
            let mut v = finish;
            loop {
                path[path_len] = v;
                path_len += 1;
                if parent[v] == v as isize { break; }
                v = parent[v] as usize;
            }
            let start = path[path_len - 1];
            let mut amount = excess[start];
            for i in (1..path_len).rev() {
                let u = path[i]; let v = path[i - 1];
                amount = amount.min(local[u][v]);
            }
            for i in (1..path_len).rev() {
                let u = path[i]; let v = path[i - 1];
                local[u][v] -= amount; local[v][u] += amount;
                residual[u][v] -= amount; residual[v][u] += amount;
            }
            excess[start] -= amount;
            if finish == sink { flow += amount; } else { excess[finish] += amount; }
        }
    }
    for u in 0..n { if in_region[u] {
        let mut next = boundary_count;
        for stage in 0..=boundary_count {
            let mut target = [false; NMAX];
            target[sink] = true;
            for v in 0..n { if external[v] && labels[v] < stage { target[v] = true; } }
            if reaches(n, &allowed, &local, u, &target) { next = stage; break; }
        }
        if next > labels[u] { labels[u] = next; }
    } }
    flow
}

#[no_mangle]
pub unsafe extern "C" fn region_discharge_path_push_relabel_maxflow(input: *const i64,
                                                                      length: usize) -> i64 {
    if input.is_null() || length < 5 || length > INPUT_MAX { return -1; }
    let nv = *input;
    let mv = *input.add(1);
    let kv = *input.add(2);
    let sv = *input.add(3);
    let tv = *input.add(4);
    if nv < 4 || nv > NMAX as i64 || mv < 1 || mv > MMAX as i64 || kv < 2 || kv > KMAX as i64
        || kv > nv - 2 || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv
        || length != 5 + nv as usize + 3 * mv as usize { return -1; }
    let n = nv as usize; let m = mv as usize; let k = kv as usize;
    let source = sv as usize; let sink = tv as usize;
    let mut regions = [-2i64; NMAX];
    let mut seen = [false; KMAX];
    let mut capacity = [[0i64; NMAX]; NMAX];
    let mut boundary_by_region = [[false; NMAX]; KMAX];
    let mut boundary = [false; NMAX];
    for v in 0..n {
        let raw = *input.add(5 + v);
        if v == source || v == sink {
            if raw != -1 { return -1; }
            regions[v] = -1;
        } else {
            if raw < 0 || raw >= kv { return -1; }
            regions[v] = raw;
            seen[raw as usize] = true;
        }
    }
    for b in 0..k { if !seen[b] { return -1; } }
    for e in 0..m {
        let p = 5 + n + 3 * e;
        let u = *input.add(p); let v = *input.add(p + 1); let cap = *input.add(p + 2);
        if u < 0 || u >= nv as i64 || v < 0 || v >= nv as i64 || u == v || v == sv || u == tv
            || cap < 0 || cap > 7 { return -1; }
        let (u, v) = (u as usize, v as usize);
        capacity[u][v] += cap;
        if cap > 0 && regions[u] >= 0 && regions[v] >= 0 && regions[u] != regions[v] {
            boundary[u] = true; boundary[v] = true;
            boundary_by_region[regions[u] as usize][v] = true;
            boundary_by_region[regions[v] as usize][u] = true;
        }
    }
    let boundary_count = boundary[..n].iter().filter(|&&x| x).count();
    if boundary_count < 2 { return -1; }
    let mut residual = capacity;
    let mut excess = [0i64; NMAX];
    let mut labels = [0usize; NMAX];
    let mut flow = 0i64;
    for v in 0..n {
        let amount = residual[source][v];
        if amount > 0 {
            residual[source][v] = 0;
            residual[v][source] += amount;
            if v == sink { flow += amount; } else { excess[v] += amount; }
        }
    }
    labels[source] = boundary_count;
    for _ in 0..(2 * boundary_count * boundary_count + 1) {
        for b in 0..k {
            flow = discharge(n, b, source, sink, boundary_count, &regions,
                             &mut residual, &mut excess, &mut labels, flow,
                             &boundary_by_region);
        }
        let mut active = false;
        for v in 0..n { if v != source && v != sink && excess[v] > 0 && labels[v] < boundary_count { active = true; } }
        if !active { return flow; }
    }
    -1
}
