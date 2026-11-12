use std::slice;

const MAX_N: usize = 24;
const MAX_M: usize = 24;
const MAX_Q: usize = 128;
const INPUT_MAX: usize = 483;
const BIT_STRIDE: usize = MAX_M + 1;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Vector { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Query { a: i64, b: i64, c: i64 }

fn half(v: Vector) -> i32 { if v.y < 0 { 0 } else if v.y == 0 && v.x >= 0 { 1 } else { 2 } }
fn angle_less(a: Vector, b: Vector) -> bool {
    let (ha, hb) = (half(a), half(b));
    if ha != hb { return ha < hb; }
    a.x * b.y - a.y * b.x > 0
}
fn direction_less(a: Vector, b: Vector) -> bool {
    if angle_less(a, b) { return true; }
    if angle_less(b, a) { return false; }
    let (ra, rb) = (a.x*a.x+a.y*a.y, b.x*b.x+b.y*b.y);
    if ra != rb { return ra < rb; }
    if a.x != b.x { return a.x < b.x; }
    a.y < b.y
}
fn lower_ray(dirs: &[Vector; MAX_M], count: usize, ray: Vector) -> usize {
    let (mut low, mut high) = (0, count);
    while low < high { let mid = low+(high-low)/2; if angle_less(dirs[mid],ray) { low=mid+1; } else { high=mid; } }
    low
}
fn upper_ray(dirs: &[Vector; MAX_M], count: usize, ray: Vector) -> usize {
    let (mut low, mut high) = (0, count);
    while low < high { let mid = low+(high-low)/2; if !angle_less(ray,dirs[mid]) { low=mid+1; } else { high=mid; } }
    low
}
fn prefix(tree: &[i32; BIT_STRIDE], mut end: usize) -> i32 {
    let mut total = 0;
    while end > 0 { total += tree[end]; end &= end-1; }
    total
}
fn arc_count(dirs: &[Vector; MAX_M], count: usize, tree: &[i32; BIT_STRIDE], start: Vector, end: Vector) -> i32 {
    let left = lower_ray(dirs,count,start);
    let right = upper_ray(dirs,count,end);
    if !angle_less(end,start) { return prefix(tree,right)-prefix(tree,left); }
    prefix(tree,count)-prefix(tree,left)+prefix(tree,right)
}
fn halfplane_count(u: usize, v: usize, a: &[Point; MAX_N], dirs: &[[Vector; MAX_M]; MAX_N],
    counts: &[usize; MAX_N], zeros: &[i32; MAX_N], bit: &[[i32; BIT_STRIDE]; MAX_N]) -> i32 {
    let edge = Vector { x: a[v].x-a[u].x, y: a[v].y-a[u].y };
    zeros[u] + arc_count(&dirs[u],counts[u],&bit[u],Vector{x:-edge.x,y:-edge.y},edge)
}
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output.add(offset+byte).write((bits>>(8*byte)) as u8); }
}

#[no_mangle]
pub unsafe extern "C" fn count_points_in_triangle(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input,length);
    let (nr,mr,qr) = (words[0],words[1],words[2]);
    if nr < 1 || nr > MAX_N as i64 || mr < 1 || mr > MAX_M as i64 || qr < 1 || qr > MAX_Q as i64 { return -1; }
    let (n,m,q) = (nr as usize,mr as usize,qr as usize);
    if length != 3+2*n+2*m+3*q { return -1; }
    let mut a = [Point::default(); MAX_N];
    let mut b = [Point::default(); MAX_M];
    let mut queries = [Query::default(); MAX_Q];
    let mut cursor = 3;
    for p in a.iter_mut().take(n) {
        p.x=words[cursor]; p.y=words[cursor+1]; cursor+=2;
        if !(-1_000_000_000..=1_000_000_000).contains(&p.x) || !(-1_000_000_000..=1_000_000_000).contains(&p.y) { return -1; }
    }
    for p in b.iter_mut().take(m) {
        p.x=words[cursor]; p.y=words[cursor+1]; cursor+=2;
        if !(-1_000_000_000..=1_000_000_000).contains(&p.x) || !(-1_000_000_000..=1_000_000_000).contains(&p.y) { return -1; }
    }
    for query in queries.iter_mut().take(q) {
        let (ia,ib,ic)=(words[cursor],words[cursor+1],words[cursor+2]); cursor+=3;
        if ia<0 || ia>=nr || ib<0 || ib>=nr || ic<0 || ic>=nr { return -1; }
        *query=Query{a:ia,b:ib,c:ic};
    }
    let required=8*q;
    if output.is_null() || capacity<required { return -2; }

    let mut dirs=[[Vector::default();MAX_M];MAX_N];
    let mut counts=[0usize;MAX_N];
    let mut zeros=[0i32;MAX_N];
    let mut bit=[[0i32;BIT_STRIDE];MAX_N];
    for u in 0..n {
        for j in 0..m {
            let ray=Vector{x:b[j].x-a[u].x,y:b[j].y-a[u].y};
            if ray.x==0 && ray.y==0 { zeros[u]+=1; } else { dirs[u][counts[u]]=ray; counts[u]+=1; }
        }
        for i in 1..counts[u] {
            let item=dirs[u][i]; let mut j=i;
            while j>0 && direction_less(item,dirs[u][j-1]) { dirs[u][j]=dirs[u][j-1]; j-=1; }
            dirs[u][j]=item;
        }
        for i in 0..counts[u] {
            let mut at=i+1;
            while at<=counts[u] { bit[u][at]+=1; at+=at&(!at+1); }
        }
    }
    let mut answers=[0i64;MAX_Q];
    for qi in 0..q {
        let (ia,mut ib,mut ic)=(queries[qi].a as usize,queries[qi].b as usize,queries[qi].c as usize);
        let orient=(a[ib].x-a[ia].x)*(a[ic].y-a[ia].y)-(a[ib].y-a[ia].y)*(a[ic].x-a[ia].x);
        if orient==0 { answers[qi]=0; continue; }
        if orient<0 { std::mem::swap(&mut ib,&mut ic); }
        let outside=halfplane_count(ia,ib,&a,&dirs,&counts,&zeros,&bit)+halfplane_count(ib,ic,&a,&dirs,&counts,&zeros,&bit)+halfplane_count(ic,ia,&a,&dirs,&counts,&zeros,&bit);
        let b_start=Vector{x:a[ib].x-a[ic].x,y:a[ib].y-a[ic].y}; let b_end=Vector{x:a[ib].x-a[ia].x,y:a[ib].y-a[ia].y};
        let c_start=Vector{x:a[ic].x-a[ia].x,y:a[ic].y-a[ia].y}; let c_end=Vector{x:a[ic].x-a[ib].x,y:a[ic].y-a[ib].y};
        let a_start=Vector{x:a[ia].x-a[ib].x,y:a[ia].y-a[ib].y}; let a_end=Vector{x:a[ia].x-a[ic].x,y:a[ia].y-a[ic].y};
        let pairs=zeros[ib]+arc_count(&dirs[ib],counts[ib],&bit[ib],b_start,b_end)
          +zeros[ic]+arc_count(&dirs[ic],counts[ic],&bit[ic],c_start,c_end)
          +zeros[ia]+arc_count(&dirs[ia],counts[ia],&bit[ia],a_start,a_end);
        answers[qi]=m as i64-outside as i64+pairs as i64;
    }
    for i in 0..q { store_le(output,8*i,answers[i]); }
    required as i64
}
