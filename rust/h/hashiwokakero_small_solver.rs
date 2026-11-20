const MAX_ISLANDS: usize = 6;
const MAX_EDGE_SLOTS: usize = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 20;

struct Solver {
    island_count: usize,
    edge_count: usize,
    x: [i64; MAX_ISLANDS],
    y: [i64; MAX_ISLANDS],
    residual: [i64; MAX_ISLANDS],
    remaining: [usize; MAX_ISLANDS],
    edge_u: [usize; MAX_EDGE_SLOTS],
    edge_v: [usize; MAX_EDGE_SLOTS],
    multiplicity: [u8; MAX_EDGE_SLOTS],
    solution: [u8; MAX_EDGE_SLOTS],
}

impl Solver {
    fn edges_cross(&self, first: usize, second: usize) -> bool {
        let (a, b) = (self.edge_u[first], self.edge_v[first]);
        let (c, d) = (self.edge_u[second], self.edge_v[second]);
        let first_horizontal = self.y[a] == self.y[b];
        let second_horizontal = self.y[c] == self.y[d];
        if first_horizontal == second_horizontal { return false; }
        let (h0, h1, v0, v1) = if first_horizontal { (a, b, c, d) } else { (c, d, a, b) };
        let hx = self.x[v0];
        let hy = self.y[h0];
        let hmin = self.x[h0].min(self.x[h1]);
        let hmax = self.x[h0].max(self.x[h1]);
        let vmin = self.y[v0].min(self.y[v1]);
        let vmax = self.y[v0].max(self.y[v1]);
        hmin < hx && hx < hmax && vmin < hy && hy < vmax
    }

    fn possible_graph_connected(&self, assigned_through: usize) -> bool {
        let mut reached = [false; MAX_ISLANDS];
        let mut stack = [0usize; MAX_ISLANDS];
        let mut top = 1usize;
        reached[0] = true;
        stack[0] = 0;
        while top != 0 {
            top -= 1;
            let island = stack[top];
            for edge in 0..self.edge_count {
                let mut usable = edge <= assigned_through && self.multiplicity[edge] != 0;
                if edge > assigned_through {
                    usable = true;
                    for fixed in 0..=assigned_through {
                        if self.multiplicity[fixed] != 0 && self.edges_cross(fixed, edge) {
                            usable = false;
                            break;
                        }
                    }
                }
                if !usable { continue; }
                let neighbor = if self.edge_u[edge] == island {
                    Some(self.edge_v[edge])
                } else if self.edge_v[edge] == island {
                    Some(self.edge_u[edge])
                } else { None };
                if let Some(neighbor) = neighbor {
                    if !reached[neighbor] {
                        reached[neighbor] = true;
                        stack[top] = neighbor;
                        top += 1;
                    }
                }
            }
        }
        (0..self.island_count).all(|island| reached[island])
    }

    fn residuals_feasible(&self) -> bool {
        (0..self.island_count).all(|island| {
            self.residual[island] >= 0
                && self.residual[island] <= (2 * self.remaining[island]) as i64
        })
    }

    fn search(&mut self, depth: usize) -> bool {
        if depth == self.edge_count {
            if (0..self.island_count).any(|island| self.residual[island] != 0) { return false; }
            if !self.possible_graph_connected(self.edge_count - 1) { return false; }
            self.solution = self.multiplicity;
            return true;
        }
        let (u, v) = (self.edge_u[depth], self.edge_v[depth]);
        self.remaining[u] -= 1;
        self.remaining[v] -= 1;
        for amount in 0u8..=2 {
            if i64::from(amount) > self.residual[u] || i64::from(amount) > self.residual[v] { continue; }
            let conflict = amount != 0 && (0..depth).any(|prior| {
                self.multiplicity[prior] != 0 && self.edges_cross(prior, depth)
            });
            if conflict { continue; }
            self.multiplicity[depth] = amount;
            self.residual[u] -= i64::from(amount);
            self.residual[v] -= i64::from(amount);
            if self.residuals_feasible() && self.possible_graph_connected(depth) && self.search(depth + 1) {
                self.residual[u] += i64::from(amount);
                self.residual[v] += i64::from(amount);
                self.remaining[u] += 1;
                self.remaining[v] += 1;
                return true;
            }
            self.residual[u] += i64::from(amount);
            self.residual[v] += i64::from(amount);
            self.multiplicity[depth] = 0;
        }
        self.remaining[u] += 1;
        self.remaining[v] += 1;
        false
    }
}

#[no_mangle]
pub unsafe extern "C" fn hashiwokakero_small_solver(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if !(2..=MAX_ISLANDS as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 3 * n { return -1; }
    let mut s = Solver {
        island_count: n,
        edge_count: 0,
        x: [0; MAX_ISLANDS],
        y: [0; MAX_ISLANDS],
        residual: [0; MAX_ISLANDS],
        remaining: [0; MAX_ISLANDS],
        edge_u: [0; MAX_EDGE_SLOTS],
        edge_v: [0; MAX_EDGE_SLOTS],
        multiplicity: [0; MAX_EDGE_SLOTS],
        solution: [0; MAX_EDGE_SLOTS],
    };
    for island in 0..n {
        let x = *input.add(1 + 3 * island);
        let y = *input.add(2 + 3 * island);
        let demand = *input.add(3 + 3 * island);
        if !(0..=7).contains(&x) || !(0..=7).contains(&y) || !(1..=8).contains(&demand) { return -1; }
        for prior in 0..island {
            if s.x[prior] == x && s.y[prior] == y { return -1; }
        }
        s.x[island] = x;
        s.y[island] = y;
        s.residual[island] = demand;
    }
    for first in 0..n {
        for second in first + 1..n {
            if s.x[first] != s.x[second] && s.y[first] != s.y[second] { continue; }
            let mut blocked = false;
            for middle in 0..n {
                if middle == first || middle == second { continue; }
                if s.y[first] == s.y[second] && s.y[middle] == s.y[first]
                    && s.x[first].min(s.x[second]) < s.x[middle]
                    && s.x[middle] < s.x[first].max(s.x[second]) { blocked = true; }
                if s.x[first] == s.x[second] && s.x[middle] == s.x[first]
                    && s.y[first].min(s.y[second]) < s.y[middle]
                    && s.y[middle] < s.y[first].max(s.y[second]) { blocked = true; }
            }
            if !blocked {
                if s.edge_count == MAX_EDGE_SLOTS { return -1; }
                let edge = s.edge_count;
                s.edge_count += 1;
                s.edge_u[edge] = first;
                s.edge_v[edge] = second;
                s.remaining[first] += 1;
                s.remaining[second] += 1;
            }
        }
    }
    if !s.search(0) { return -2; }
    let mut result = 1i64 << 32;
    for edge in 0..s.edge_count {
        result |= i64::from(s.solution[edge]) << (2 * edge);
    }
    result
}
