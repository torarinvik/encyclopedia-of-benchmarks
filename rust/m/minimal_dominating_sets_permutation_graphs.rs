const MAX_N: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 10;
const MAX_STATES: usize = 59049;

struct Solver {
    n: usize,
    top: [usize; MAX_N],
    top_vertex: [usize; MAX_N],
    adj: [[bool; MAX_N]; MAX_N],
    ways: [i64; MAX_STATES],
}

impl Solver {
    fn case_of(&self, i: usize, j: usize, k: usize) -> usize {
        let (a, b, c) = (self.top[i], self.top[j], self.top[k]);
        if a < b && b < c { 1 }
        else if a < c && c < b { 2 }
        else if b < a && a < c { 3 }
        else if b < c && c < a { 4 }
        else if c < a && a < b { 5 }
        else { 0 }
    }

    fn covered(&self, y: usize, selected: &[usize]) -> bool {
        selected.iter().any(|&x| self.adj[x][y])
    }

    fn irredundant(&self, selected: &[usize]) -> bool {
        selected.iter().enumerate().all(|(xpos, &x)| {
            (0..self.n).any(|y| {
                self.adj[x][y] && selected.iter().enumerate().all(|(zpos, &z)| {
                    zpos == xpos || !self.adj[z][y]
                })
            })
        })
    }

    fn private_min_rank(&self, x: usize, selected: &[usize]) -> Option<usize> {
        (0..self.n)
            .filter(|&y| self.adj[x][y] && selected.iter().all(|&z| z == x || !self.adj[z][y]))
            .min_by_key(|&y| self.top[y])
    }

    fn initial(&self, i: usize, j: usize, k: usize, r: usize, s: usize) -> bool {
        let tri = [i, j, k];
        if r != self.n || !self.irredundant(&tri) { return false; }
        match self.case_of(i, j, k) {
            1 => !(0..self.n).any(|y| y < i && self.top[y] < self.top[i])
                && Some(s) == self.private_min_rank(i, &tri),
            2 => s == self.n && !(0..self.n).any(|y| {
                self.top[y] < self.top[k] && y < j && !self.covered(y, &tri)
            }),
            3 => !(0..self.n).any(|y| self.top[y] < self.top[j] && y < i)
                && Some(s) == self.private_min_rank(j, &tri),
            4 => s == self.n && !(0..self.n).any(|y| {
                self.top[y] < self.top[j] && y < i && !self.covered(y, &tri)
            }),
            5 => !(0..self.n).any(|y| self.top[y] < self.top[k] && y < i)
                && Some(s) == self.private_min_rank(k, &tri),
            _ => false,
        }
    }

    fn regular(&self, i: usize, j: usize, k: usize, r: usize, s: usize) -> bool {
        let tri = [i, j, k];
        if !self.irredundant(&tri) { return false; }
        let kind = self.case_of(i, j, k);
        if (1..=4).contains(&kind) {
            if r >= i { return false; }
        } else if kind == 5 {
            if r != self.n { return false; }
        } else { return false; }
        if kind == 2 || kind == 4 { return s == self.n; }
        if s >= self.n { return false; }
        match kind {
            1 => self.adj[i][s] && !self.adj[r][s] && !self.adj[j][s] && !self.adj[k][s],
            3 => self.adj[j][s] && !self.adj[r][s] && !self.adj[i][s] && !self.adj[k][s],
            _ => self.adj[k][s] && !self.adj[i][s] && !self.adj[j][s],
        }
    }

    fn is_final(&self, i: usize, j: usize, k: usize, r: usize) -> bool {
        let mut selected = [0usize; 4];
        let mut len = 0;
        if r != self.n { selected[len] = r; len += 1; }
        selected[len] = i; len += 1;
        selected[len] = j; len += 1;
        selected[len] = k; len += 1;
        (0..self.n).all(|y| !(i < y && self.top[i] < self.top[y])
            || self.covered(y, &selected[..len]))
    }

    fn index(i: usize, j: usize, k: usize, r: usize, s: usize, base: usize) -> usize {
        ((((i * base + j) * base + k) * base + r) * base + s)
    }

    fn successor(&self, i: usize, j: usize, k: usize, r: usize, s: usize, ell: usize)
        -> Option<(usize, usize)> {
        let kind = self.case_of(j, k, ell);
        if kind == 0 { return None; }
        let mut selected = [0usize; 5];
        let mut len = 0;
        if r != self.n { selected[len] = r; len += 1; }
        for x in [i, j, k, ell] { selected[len] = x; len += 1; }
        let set = &selected[..len];
        if !self.irredundant(set) || (s != self.n && self.top[ell] <= self.top[s]) { return None; }
        if !self.adj[j][k] && (0..self.n).any(|y| {
            i < y && y < j && self.top[i] < self.top[y] && self.top[y] < self.top[j]
                && !self.covered(y, set)
        }) { return None; }
        if self.adj[i][k] && (0..self.n).any(|y| {
            j < y && y < k && self.top[j] < self.top[y] && self.top[y] < self.top[ell]
                && !self.covered(y, set)
        }) { return None; }
        let new_r = if kind == 5 { self.n } else {
            let mut highest = self.top[i];
            if r != self.n && self.top[r] > highest { highest = self.top[r]; }
            self.top_vertex[highest]
        };
        let new_s = if kind == 2 || kind == 4 { self.n } else {
            let old_min = self.top[i].min(self.top[j]).min(self.top[k]);
            let next_min = self.top[j].min(self.top[k]).min(self.top[ell]);
            if s != self.n && old_min == next_min { s }
            else {
                let y = [j, k, ell].into_iter().min_by_key(|&x| self.top[x])?;
                self.private_min_rank(y, set)?
            }
        };
        if self.regular(j, k, ell, new_r, new_s) { Some((new_r, new_s)) } else { None }
    }

    fn dominates(mask: u32, hoods: &[u32; MAX_N], n: usize) -> bool {
        let mut covered = 0u32;
        for x in 0..n { if mask & (1 << x) != 0 { covered |= hoods[x]; } }
        covered == (1u32 << n) - 1
    }

    fn count(&mut self) -> i64 {
        let base = self.n + 1;
        let mut answer = 0i64;
        if self.n >= 3 {
            for i in (0..=self.n - 3).rev() {
                for j in i + 1..self.n - 1 {
                    for k in j + 1..self.n {
                        let tri = [i, j, k];
                        if self.case_of(i, j, k) == 0 || !self.irredundant(&tri) { continue; }
                        for ri in 0..=i {
                            let r = if ri == i { self.n } else { ri };
                            for s in 0..=self.n {
                                if !self.initial(i, j, k, r, s) && !self.regular(i, j, k, r, s) { continue; }
                                let mut paths = self.is_final(i, j, k, r) as i64;
                                for ell in k + 1..self.n {
                                    if let Some((nr, ns)) = self.successor(i, j, k, r, s, ell) {
                                        paths += self.ways[Self::index(j, k, ell, nr, ns, base)];
                                    }
                                }
                                self.ways[Self::index(i, j, k, r, s, base)] = paths;
                                if self.initial(i, j, k, r, s) { answer += paths; }
                            }
                        }
                    }
                }
            }
        }
        let mut hoods = [0u32; MAX_N];
        for x in 0..self.n { for y in 0..self.n { if self.adj[x][y] { hoods[x] |= 1 << y; } } }
        let full = (1u32 << self.n) - 1;
        for mask in 1..=full {
            if mask.count_ones() > 2 || !Self::dominates(mask, &hoods, self.n) { continue; }
            let mut minimal = true;
            for x in 0..self.n {
                let bit = 1u32 << x;
                if mask & bit != 0 && Self::dominates(mask ^ bit, &hoods, self.n) { minimal = false; }
            }
            if minimal { answer += 1; }
        }
        answer
    }
}

fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > MAX_PARSEABLE_LENGTH { return -1; }
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if values.len() != n + 1 { return -1; }
    let mut solver = Solver {
        n, top: [0; MAX_N], top_vertex: [0; MAX_N],
        adj: [[false; MAX_N]; MAX_N], ways: [0; MAX_STATES],
    };
    let mut seen = [false; MAX_N];
    for x in 0..n {
        let rank = values[x + 1];
        if rank < 0 || rank >= n as i64 { return -1; }
        let rank = rank as usize;
        if seen[rank] { return -1; }
        seen[rank] = true;
        solver.top[x] = rank;
        solver.top_vertex[rank] = x;
        solver.adj[x][x] = true;
    }
    for x in 0..n { for y in x + 1..n {
        solver.adj[x][y] = solver.top[x] > solver.top[y];
        solver.adj[y][x] = solver.adj[x][y];
    } }
    solver.count()
}

#[no_mangle]
pub unsafe extern "C" fn minimal_dominating_sets_permutation_graphs(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
