//! Primal-dual weighted matching with odd-cycle contraction.
use std::slice;

const MAX_N: usize = 64;
const IDS: usize = 2 * MAX_N;
const SLOTS: usize = IDS + 1;
const INF: i64 = i64::MAX;

struct Search {
    n: usize,
    nodes: usize,
    epoch: i32,
    weight: [[i64; SLOTS]; SLOTS],
    dual: [i64; SLOTS],
    edge_a: [[i16; SLOTS]; SLOTS],
    edge_b: [[i16; SLOTS]; SLOTS],
    mate: [i16; SLOTS],
    slack_from: [i16; SLOTS],
    top: [i16; SLOTS],
    parent: [i16; SLOTS],
    state: [i16; SLOTS],
    seen: [i32; SLOTS],
    members: [[i16; SLOTS]; SLOTS],
    member_count: [i16; SLOTS],
    child_of: [[i16; MAX_N + 1]; SLOTS],
    queue: [usize; MAX_N],
    queued: [bool; MAX_N + 1],
    head: usize,
    tail: usize,
    count: usize,
}

impl Search {
    fn delta(&self, a: usize, b: usize) -> i64 {
        self.dual[self.edge_a[a][b] as usize] + self.dual[self.edge_b[a][b] as usize]
            - 2 * self.weight[a][b]
    }

    fn enqueue_leaf(&mut self, v: usize) {
        if v == 0 || v > self.n || self.queued[v] { return; }
        self.queue[self.tail] = v;
        self.tail = (self.tail + 1) % self.n;
        self.count += 1;
        self.queued[v] = true;
    }

    fn enqueue_members(&mut self, x: usize) {
        if x <= self.n { self.enqueue_leaf(x); return; }
        for i in 0..self.member_count[x] as usize {
            self.enqueue_members(self.members[x][i] as usize);
        }
    }

    fn set_top(&mut self, x: usize, b: usize) {
        self.top[x] = b as i16;
        if x > self.n {
            for i in 0..self.member_count[x] as usize {
                self.set_top(self.members[x][i] as usize, b);
            }
        }
    }

    fn update_slack(&mut self, u: usize, x: usize) {
        let old = self.slack_from[x] as usize;
        if old == 0 || self.delta(u, x) < self.delta(old, x) {
            self.slack_from[x] = u as i16;
        }
    }

    fn refresh_slack(&mut self, x: usize) {
        self.slack_from[x] = 0;
        for u in 1..=self.n {
            let representative = self.top[u] as usize;
            if self.weight[u][x] > 0 && representative != x && self.state[representative] == 0 {
                self.update_slack(u, x);
            }
        }
    }

    fn cycle_position(&mut self, b: usize, child: usize) -> usize {
        let size = self.member_count[b] as usize;
        let mut pos = 0;
        while pos < size && self.members[b][pos] as usize != child { pos += 1; }
        if pos == size { return 0; }
        if pos % 2 == 1 {
            self.members[b][1..size].reverse();
            pos = size - pos;
        }
        pos
    }

    fn rotate_cycle(&mut self, b: usize, start: usize) {
        let size = self.member_count[b] as usize;
        let mut saved = [0i16; SLOTS];
        for i in 0..size { saved[i] = self.members[b][(i + start) % size]; }
        self.members[b][..size].copy_from_slice(&saved[..size]);
    }

    fn set_pair(&mut self, u: usize, v: usize) {
        self.mate[u] = self.edge_b[u][v];
        if u <= self.n { return; }
        let leaf = self.edge_a[u][v] as usize;
        let entry = self.child_of[u][leaf] as usize;
        let pos = self.cycle_position(u, entry);
        for i in 0..pos { self.set_pair(self.members[u][i] as usize, self.members[u][i ^ 1] as usize); }
        self.set_pair(entry, v);
        self.rotate_cycle(u, pos);
    }

    fn augment(&mut self, mut u: usize, mut v: usize) {
        loop {
            let next = self.top[self.mate[u] as usize] as usize;
            self.set_pair(u, v);
            if next == 0 { return; }
            let prior = self.top[self.parent[next] as usize] as usize;
            self.set_pair(next, prior);
            u = prior;
            v = next;
        }
    }

    fn common_base(&mut self, mut u: usize, mut v: usize) -> usize {
        self.epoch += 1;
        while u != 0 || v != 0 {
            if u != 0 {
                if self.seen[u] == self.epoch { return u; }
                self.seen[u] = self.epoch;
                u = self.top[self.mate[u] as usize] as usize;
                if u != 0 { u = self.top[self.parent[u] as usize] as usize; }
            }
            std::mem::swap(&mut u, &mut v);
        }
        0
    }

    fn add_child(&mut self, b: usize, x: usize) {
        let at = self.member_count[b] as usize;
        self.members[b][at] = x as i16;
        self.member_count[b] += 1;
    }

    fn contract(&mut self, u: usize, base: usize, v: usize) {
        let mut b = self.n + 1;
        while b <= self.nodes && self.top[b] != 0 { b += 1; }
        if b > self.nodes { self.nodes += 1; }
        self.dual[b] = 0;
        self.state[b] = 0;
        self.mate[b] = self.mate[base];
        self.member_count[b] = 0;
        self.add_child(b, base);
        let mut x = u;
        while x != base {
            self.add_child(b, x);
            let y = self.top[self.mate[x] as usize] as usize;
            self.add_child(b, y);
            self.enqueue_members(y);
            x = self.top[self.parent[y] as usize] as usize;
        }
        let end = self.member_count[b] as usize;
        self.members[b][1..end].reverse();
        x = v;
        while x != base {
            self.add_child(b, x);
            let y = self.top[self.mate[x] as usize] as usize;
            self.add_child(b, y);
            self.enqueue_members(y);
            x = self.top[self.parent[y] as usize] as usize;
        }
        self.set_top(b, b);

        for y in 1..=self.nodes {
            self.weight[b][y] = 0;
            self.weight[y][b] = 0;
            self.edge_a[b][y] = 0; self.edge_b[b][y] = 0;
            self.edge_a[y][b] = 0; self.edge_b[y][b] = 0;
        }
        self.child_of[b].fill(0);
        for i in 0..self.member_count[b] as usize {
            let child = self.members[b][i] as usize;
            for y in 1..=self.nodes {
                if self.weight[child][y] == 0 { continue; }
                if self.weight[b][y] == 0 || self.delta(child, y) < self.delta(b, y) {
                    self.weight[b][y] = self.weight[child][y];
                    self.edge_a[b][y] = self.edge_a[child][y];
                    self.edge_b[b][y] = self.edge_b[child][y];
                    self.weight[y][b] = self.weight[y][child];
                    self.edge_a[y][b] = self.edge_a[y][child];
                    self.edge_b[y][b] = self.edge_b[y][child];
                }
            }
            for leaf in 1..=self.n {
                let contains = if child <= self.n { child == leaf } else { self.child_of[child][leaf] != 0 };
                if contains { self.child_of[b][leaf] = child as i16; }
            }
        }
        self.refresh_slack(b);
    }

    fn expand(&mut self, b: usize) {
        for i in 0..self.member_count[b] as usize {
            let child = self.members[b][i] as usize;
            self.set_top(child, child);
        }
        let outside = self.parent[b] as usize;
        let entry_leaf = self.edge_a[b][outside] as usize;
        let entry = self.child_of[b][entry_leaf] as usize;
        let pos = self.cycle_position(b, entry);
        let mut i = 0;
        while i < pos {
            let inner = self.members[b][i] as usize;
            let outer = self.members[b][i + 1] as usize;
            self.parent[inner] = self.edge_a[outer][inner];
            self.state[inner] = 1;
            self.state[outer] = 0;
            self.slack_from[inner] = 0;
            self.refresh_slack(outer);
            self.enqueue_members(outer);
            i += 2;
        }
        self.state[entry] = 1;
        self.parent[entry] = outside as i16;
        for i in pos + 1..self.member_count[b] as usize {
            let child = self.members[b][i] as usize;
            self.state[child] = -1;
            self.refresh_slack(child);
        }
        self.top[b] = 0;
    }

    fn process_edge(&mut self, left: usize, right: usize) -> bool {
        let u = self.top[left] as usize;
        let v = self.top[right] as usize;
        if self.state[v] == -1 {
            self.parent[v] = left as i16;
            self.state[v] = 1;
            let next = self.top[self.mate[v] as usize] as usize;
            self.slack_from[v] = 0;
            self.slack_from[next] = 0;
            self.state[next] = 0;
            self.enqueue_members(next);
        } else if self.state[v] == 0 {
            let base = self.common_base(u, v);
            if base == 0 {
                self.augment(u, v);
                self.augment(v, u);
                return true;
            }
            self.contract(u, base, v);
        }
        false
    }

    fn stage(&mut self) -> bool {
        for x in 0..=self.nodes { self.state[x] = -1; self.slack_from[x] = 0; }
        self.head = 0; self.tail = 0; self.count = 0; self.queued.fill(false);
        for x in 1..=self.nodes {
            if self.top[x] as usize == x && self.mate[x] == 0 {
                self.parent[x] = 0;
                self.state[x] = 0;
                self.enqueue_members(x);
            }
        }
        if self.count == 0 { return false; }

        loop {
            while self.count != 0 {
                let u = self.queue[self.head];
                self.head = (self.head + 1) % self.n;
                self.count -= 1;
                self.queued[u] = false;
                if self.state[self.top[u] as usize] == 1 { continue; }
                for v in 1..=self.n {
                    if self.weight[u][v] == 0 || self.top[u] == self.top[v] { continue; }
                    if self.delta(u, v) == 0 {
                        let left = self.edge_a[u][v] as usize;
                        let right = self.edge_b[u][v] as usize;
                        if self.process_edge(left, right) { return true; }
                    } else {
                        self.update_slack(u, self.top[v] as usize);
                    }
                }
            }

            let mut step = INF;
            for u in 1..=self.n {
                if self.state[self.top[u] as usize] == 0 { step = step.min(self.dual[u]); }
            }
            for b in self.n + 1..=self.nodes {
                if self.top[b] as usize == b && self.state[b] == 1 { step = step.min(self.dual[b] / 2); }
            }
            for x in 1..=self.nodes {
                if self.top[x] as usize != x || self.slack_from[x] == 0 { continue; }
                let slack = self.delta(self.slack_from[x] as usize, x);
                if self.state[x] == -1 { step = step.min(slack); }
                else if self.state[x] == 0 { step = step.min(slack / 2); }
            }
            if step == INF { return false; }

            for u in 1..=self.n {
                match self.state[self.top[u] as usize] {
                    0 => { if self.dual[u] == step { return false; } self.dual[u] -= step; }
                    1 => self.dual[u] += step,
                    _ => (),
                }
            }
            for b in self.n + 1..=self.nodes {
                if self.top[b] as usize != b { continue; }
                if self.state[b] == 0 { self.dual[b] += 2 * step; }
                else if self.state[b] == 1 { self.dual[b] -= 2 * step; }
            }
            for x in 1..=self.nodes {
                if self.top[x] as usize == x && self.slack_from[x] != 0 &&
                    self.top[self.slack_from[x] as usize] as usize != x &&
                    self.delta(self.slack_from[x] as usize, x) == 0 {
                    let source = self.slack_from[x] as usize;
                    let left = self.edge_a[source][x] as usize;
                    let right = self.edge_b[source][x] as usize;
                    if self.process_edge(left, right) { return true; }
                }
            }
            for b in self.n + 1..=self.nodes {
                if self.top[b] as usize == b && self.state[b] == 1 && self.dual[b] == 0 { self.expand(b); }
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn general_weighted_matching_primal_dual_blossom(
    input_ptr: *const i64, length: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > 6051 { return -2; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (nv, mv) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&nv) || mv < 0 || mv > nv * (nv - 1) / 2 { return -2; }
    let (n, edges) = (nv as usize, mv as usize);
    if length != 2 + 3 * edges { return -2; }

    let mut search: Search = std::mem::zeroed();
    search.n = n;
    search.nodes = n;
    let mut largest = 0i64;
    for edge in 0..edges {
        let (u_value, v_value, weight) = (input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]);
        if u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv || u_value == v_value ||
            !(1..=1_000_000).contains(&weight) { return -2; }
        let (u, v) = (u_value as usize + 1, v_value as usize + 1);
        if search.weight[u][v] != 0 { return -2; }
        search.weight[u][v] = weight; search.weight[v][u] = weight;
        search.edge_a[u][v] = u as i16; search.edge_b[u][v] = v as i16;
        search.edge_a[v][u] = v as i16; search.edge_b[v][u] = u as i16;
        largest = largest.max(weight);
    }
    for u in 1..=n {
        search.top[u] = u as i16;
        search.dual[u] = largest;
        search.child_of[u][u] = u as i16;
    }
    while search.stage() {}
    let mut answer = 0i64;
    for u in 1..=n {
        let v = search.mate[u] as usize;
        if v > u { answer += search.weight[u][v]; }
    }
    answer
}
