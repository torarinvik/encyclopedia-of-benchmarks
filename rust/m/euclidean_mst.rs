const MAX_POINTS: usize = 8;
const MAX_EDGES: usize = MAX_POINTS * (MAX_POINTS - 1) / 2;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_POINTS + 1;
const MAX_OUTPUT_WORDS: usize = 2 * MAX_POINTS - 1;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize, weight: i64 }

fn orientation(a: Point, b: Point, c: Point) -> i64 {
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}
fn incircle(a: Point, b: Point, c: Point, d: Point) -> i64 {
    let (ax, ay, bx, by, cx, cy) = (a.x-d.x, a.y-d.y, b.x-d.x, b.y-d.y, c.x-d.x, c.y-d.y);
    (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx)
        + (cx*cx+cy*cy)*(ax*by-ay*bx)
}
fn general_position(points: &[Point; MAX_POINTS], n: usize) -> bool {
    for a in 0..n { for b in a+1..n {
        if points[a].x == points[b].x && points[a].y == points[b].y { return false; }
    }}
    for a in 0..n { for b in a+1..n { for c in b+1..n {
        if orientation(points[a], points[b], points[c]) == 0 { return false; }
        for d in 0..n { if d != a && d != b && d != c && incircle(points[a], points[b], points[c], points[d]) == 0 { return false; } }
    }}}
    true
}
fn find_root(parent: &mut [usize; MAX_POINTS], mut v: usize) -> usize {
    while parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v]; }
    v
}
fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (value as u64 >> (8 * byte)) as u8; } }
}

fn compute(points: &[Point; MAX_POINTS], n: usize) -> Option<[i64; MAX_OUTPUT_WORDS]> {
    let mut candidates = [[false; MAX_POINTS]; MAX_POINTS];
    if n == 2 { candidates[0][1] = true; candidates[1][0] = true; }
    for a in 0..n { for b in a+1..n { for c in b+1..n {
        let turn = orientation(points[a], points[b], points[c]);
        let mut empty = true;
        for d in 0..n {
            if d == a || d == b || d == c { continue; }
            let determinant = incircle(points[a], points[b], points[c], points[d]);
            if (determinant > 0) == (turn > 0) { empty = false; break; }
        }
        if empty {
            candidates[a][b] = true; candidates[b][a] = true;
            candidates[a][c] = true; candidates[c][a] = true;
            candidates[b][c] = true; candidates[c][b] = true;
        }
    }}}
    let mut edges = [Edge::default(); MAX_EDGES];
    let mut edge_count = 0;
    for u in 0..n { for v in u+1..n { if candidates[u][v] {
        let dx=points[u].x-points[v].x; let dy=points[u].y-points[v].y;
        let edge=Edge{u,v,weight:dx*dx+dy*dy};
        let mut at=edge_count; edge_count+=1;
        while at>0 {
            let previous=edges[at-1];
            if previous.weight<edge.weight || (previous.weight==edge.weight && (previous.u<edge.u || (previous.u==edge.u && previous.v<=edge.v))) { break; }
            edges[at]=previous; at-=1;
        }
        edges[at]=edge;
    }}}
    let mut parent=[0usize;MAX_POINTS]; let mut size=[0usize;MAX_POINTS];
    for i in 0..n { parent[i]=i; size[i]=1; }
    let mut words=[0i64;MAX_OUTPUT_WORDS]; words[0]=(n-1) as i64;
    let mut selected=0;
    for edge in edges.iter().take(edge_count) {
        if selected==n-1 { break; }
        let mut left=find_root(&mut parent,edge.u); let mut right=find_root(&mut parent,edge.v);
        if left==right { continue; }
        if size[left]<size[right] { std::mem::swap(&mut left,&mut right); }
        parent[right]=left; size[left]+=size[right];
        words[1+2*selected]=edge.u as i64; words[2+2*selected]=edge.v as i64; selected+=1;
    }
    if selected != n-1 { return None; }
    Some(words)
}

#[no_mangle]
pub unsafe extern "C" fn euclidean_mst(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let raw_n=values[0];
    if raw_n<1 || raw_n>MAX_POINTS as i64 { return -1; }
    let n=raw_n as usize;
    if length!=1+2*n { return -1; }
    let mut points=[Point::default();MAX_POINTS];
    for i in 0..n {
        points[i]=Point{x:values[1+2*i],y:values[2+2*i]};
        if points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10 { return -1; }
    }
    if !general_position(&points,n) { return -1; }
    let output_words=2*n-1; let output_bytes=8*output_words;
    if output.is_null() || output_capacity<output_bytes { return -2; }
    let Some(words)=compute(&points,n) else { return -1; };
    for word in 0..output_words { store_i64_le(output,8*word,words[word]); }
    output_bytes as i64
}
