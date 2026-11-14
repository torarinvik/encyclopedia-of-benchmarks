// Independent event-graph draft; compilation and correctness are unverified.
use std::collections::VecDeque;

struct Graph {
    edges: Vec<Vec<usize>>,
    degree: Vec<usize>,
    first: Vec<bool>,
}

impl Graph {
    fn new() -> Self { Self { edges: Vec::new(), degree: Vec::new(), first: Vec::new() } }
    fn node(&mut self, first: bool) -> usize {
        let id = self.edges.len();
        self.edges.push(Vec::new()); self.degree.push(0); self.first.push(first);
        id
    }
    fn add(&mut self, from: usize, to: usize) {
        self.edges[from].push(to);
        self.degree[to] += 1;
    }
}

struct Trees { down: Vec<usize>, up: Vec<usize>, any: Vec<usize> }

impl Trees {
    fn new(graph: &mut Graph, n: usize) -> Self {
        let mut tree = Self { down: vec![0; 4*n], up: vec![0; 4*n], any: vec![0; 4*n] };
        tree.build(graph, 1, 0, n);
        tree
    }
    fn build(&mut self, graph: &mut Graph, t: usize, l: usize, r: usize) {
        self.down[t]=graph.node(false); self.up[t]=graph.node(false); self.any[t]=graph.node(true);
        if r-l == 1 {
            graph.add(self.down[t], l); graph.add(l, self.up[t]); graph.add(l, self.any[t]);
            return;
        }
        let mid=l+(r-l)/2;
        self.build(graph, 2*t, l, mid); self.build(graph, 2*t+1, mid, r);
        for child in [2*t, 2*t+1] {
            graph.add(self.down[t], self.down[child]);
            graph.add(self.up[child], self.up[t]);
            graph.add(self.any[child], self.any[t]);
        }
    }
    fn connect(&self, graph: &mut Graph, t: usize, l: usize, r: usize,
               ql: usize, qr: usize, kind: i64, target: usize) {
        if ql<=l && r<=qr {
            match kind {
                1 => graph.add(target, self.down[t]),
                2 => graph.add(self.up[t], target),
                _ => graph.add(self.any[t], target),
            }
            return;
        }
        let mid=l+(r-l)/2;
        if ql<mid { self.connect(graph, 2*t, l, mid, ql, qr, kind, target); }
        if qr>mid { self.connect(graph, 2*t+1, mid, r, ql, qr, kind, target); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn range_constraint_topological_feasibility(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values=std::slice::from_raw_parts(input, length);
    if !(1..=4096).contains(&values[0]) || !(0..=8192).contains(&values[1]) { return -1; }
    let n=values[0] as usize; let m=values[1] as usize;
    if length != 2 + 4*m { return -1; }
    for row in values[2..].chunks_exact(4) {
        let (kind,l,r,v)=(row[0],row[1],row[2],row[3]);
        if !(1..=3).contains(&kind) || l<0 || l>=r || r>n as i64 || v<0 || v>=n as i64 || (l<=v && v<r) {
            return -1;
        }
    }
    let mut graph=Graph::new();
    for _ in 0..n { graph.node(false); }
    let trees=Trees::new(&mut graph,n);
    for row in values[2..].chunks_exact(4) {
        let kind=row[0]; let l=row[1] as usize; let r=row[2] as usize; let target=row[3] as usize;
        if kind==3 {
            let gate=graph.node(true);
            trees.connect(&mut graph,1,0,n,l,r,kind,gate);
            graph.add(gate,target);
        } else { trees.connect(&mut graph,1,0,n,l,r,kind,target); }
    }
    for i in 0..graph.degree.len() { if graph.first[i] { graph.degree[i]=1; } }
    let mut ready=VecDeque::new();
    for (i,&degree) in graph.degree.iter().enumerate() { if degree==0 { ready.push_back(i); } }
    let mut emitted=0;
    while let Some(u)=ready.pop_front() {
        if u<n { emitted+=1; }
        for &v in &graph.edges[u] {
            if graph.degree[v]>0 {
                graph.degree[v]-=1;
                if graph.degree[v]==0 { ready.push_back(v); }
            }
        }
    }
    if emitted==n { 1 } else { 0 }
}
