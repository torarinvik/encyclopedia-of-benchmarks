struct Search {
    n: usize,
    goal: usize,
    bound: i32,
    next: i32,
    h: [i32; 12],
    edges: [u16; 12],
}

impl Search {
    fn visit(&mut self, u: usize, depth: i32, path: u16) -> i32 {
        let score = depth + self.h[u];
        if score > self.bound { self.next = self.next.min(score); return -1; }
        if u == self.goal { return depth; }
        for v in 0..self.n {
            let bit = 1u16 << v;
            if self.edges[u] & bit != 0 && path & bit == 0 {
                let result = self.visit(v, depth + 1, path | bit);
                if result >= 0 { return result; }
            }
        }
        -1
    }
}

#[no_mangle]
pub unsafe extern "C" fn ida_star_graph(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(5..=112).contains(&length) { return i64::MIN; }
    let values = std::slice::from_raw_parts(input, length);
    let (n, m, start, goal) = (values[0], values[1], values[2], values[3]);
    if !(1..=12).contains(&n) || !(0..=48).contains(&m) || start < 0 || start >= n ||
        goal < 0 || goal >= n || length != (4 + n + 2*m) as usize { return i64::MIN; }
    let mut search = Search { n: n as usize, goal: goal as usize, bound: 0, next: 0,
                              h: [0; 12], edges: [0; 12] };
    for i in 0..search.n {
        if values[4+i] < 0 || values[4+i] >= n { return i64::MIN; }
        search.h[i] = values[4+i] as i32;
    }
    if search.h[search.goal] != 0 { return i64::MIN; }
    for i in 0..m as usize {
        let u = values[4+search.n+2*i]; let v = values[5+search.n+2*i];
        if u < 0 || u >= n || v < 0 || v >= n || u == v { return i64::MIN; }
        let (u, v) = (u as usize, v as usize);
        let bit = 1u16 << v;
        if search.edges[u] & bit != 0 || search.h[u] > 1 + search.h[v] { return i64::MIN; }
        search.edges[u] |= bit;
    }
    search.bound = search.h[start as usize];
    loop {
        search.next = 1000;
        let result = search.visit(start as usize, 0, 1u16 << start);
        if result >= 0 { return result as i64; }
        if search.next == 1000 { return -1; }
        search.bound = search.next;
    }
}
