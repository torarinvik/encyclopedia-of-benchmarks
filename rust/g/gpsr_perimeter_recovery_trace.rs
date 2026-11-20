use std::cmp::Ordering;
use std::slice;

const MAX_N: usize = 8;
const MAX_M: usize = 18;
const MAX_INPUT: usize = 57;
const MAX_OUTPUT: usize = 896;

#[derive(Clone, Copy, PartialEq)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy)]
struct Fraction { num: i64, den: i64 }
struct Frame {
    n: usize, m: usize, source: usize, target: usize,
    points: Vec<Point>, edges: Vec<(usize, usize)>,
    adjacency: Vec<Vec<usize>>, rotation: Vec<Vec<usize>>,
}

fn cross(ax: i64, ay: i64, bx: i64, by: i64) -> i64 { ax * by - ay * bx }
fn orient(a: Point, b: Point, c: Point) -> i64 {
    cross(b.x-a.x, b.y-a.y, c.x-a.x, c.y-a.y)
}
fn half(x: i64, y: i64) -> u8 { if y > 0 || (y == 0 && x >= 0) { 0 } else { 1 } }
fn polar_cmp(a: (i64,i64,usize), b: (i64,i64,usize)) -> Ordering {
    let ha=half(a.0,a.1); let hb=half(b.0,b.1);
    if ha != hb { return ha.cmp(&hb); }
    let turn=cross(a.0,a.1,b.0,b.1);
    if turn != 0 { return if turn > 0 { Ordering::Less } else { Ordering::Greater }; }
    a.2.cmp(&b.2)
}
fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r=a%b; a=b; b=r; }
    a.abs()
}
fn proper_crossing(p: Point,q: Point,a: Point,b: Point) -> Option<Fraction> {
    let rx=q.x-p.x; let ry=q.y-p.y; let sx=b.x-a.x; let sy=b.y-a.y;
    let mut den=cross(rx,ry,sx,sy);
    if den == 0 { return None; }
    let ax=a.x-p.x; let ay=a.y-p.y;
    let mut tn=cross(ax,ay,sx,sy); let mut un=cross(ax,ay,rx,ry);
    if den < 0 { den=-den; tn=-tn; un=-un; }
    if tn <= 0 || tn >= den || un <= 0 || un >= den { return None; }
    let g=gcd(tn,den); Some(Fraction{num:tn/g,den:den/g})
}
fn segments_cross(a: Point,b: Point,c: Point,d: Point) -> bool {
    orient(a,b,c)*orient(a,b,d)<0 && orient(c,d,a)*orient(c,d,b)<0
}
fn decode(input: &[i64]) -> Option<Frame> {
    if input.len()<4 || input.len()>MAX_INPUT { return None; }
    let n=input[0]; let m=input[1]; let s=input[2]; let d=input[3];
    if n<3 || n>MAX_N as i64 || m<n-1 || m>3*n-6 || m>MAX_M as i64 ||
       s<0 || s>=n || d<0 || d>=n || s==d { return None; }
    let (n,m,source,target)=(n as usize,m as usize,s as usize,d as usize);
    if input.len()!=4+2*n+2*m { return None; }
    let mut points=Vec::with_capacity(n);
    for i in 0..n {
        let p=Point{x:input[4+i],y:input[4+n+i]};
        if p.x < -16 || p.x > 16 || p.y < -16 || p.y > 16 || points.contains(&p) { return None; }
        points.push(p);
    }
    for i in 0..n { for j in i+1..n { for k in j+1..n {
        if orient(points[i],points[j],points[k])==0 { return None; }
    }}}
    let base=4+2*n;
    let mut edges=Vec::with_capacity(m);
    let mut adjacency=vec![Vec::new();n];
    for i in 0..m {
        let u=input[base+2*i]; let v=input[base+2*i+1];
        if u<0 || v>=n as i64 || u>=v { return None; }
        let edge=(u as usize,v as usize);
        if edges.last().map_or(false, |last| *last >= edge) { return None; }
        edges.push(edge); adjacency[edge.0].push(edge.1); adjacency[edge.1].push(edge.0);
    }
    let mut reached=vec![false;n]; reached[source]=true;
    let mut queue=vec![source];
    for index in 0..queue.len() {
        let u=queue[index];
        for &v in &adjacency[u] { if !reached[v] { reached[v]=true; queue.push(v); } }
    }
    if queue.len()!=n { return None; }
    for i in 0..m { for j in i+1..m {
        let (a,b)=edges[i]; let (c,d)=edges[j];
        if a!=c && a!=d && b!=c && b!=d && segments_cross(points[a],points[b],points[c],points[d]) { return None; }
    }}
    let distance=|v:usize| { let dx=points[v].x-points[target].x; let dy=points[v].y-points[target].y; dx*dx+dy*dy };
    if adjacency[source].iter().any(|&v| distance(v)<distance(source)) { return None; }
    let mut rotation=adjacency.clone();
    for u in 0..n {
        rotation[u].sort_by(|&a,&b| polar_cmp(
            (points[a].x-points[u].x,points[a].y-points[u].y,a),
            (points[b].x-points[u].x,points[b].y-points[u].y,b)));
    }
    Some(Frame{n,m,source,target,points,edges,adjacency,rotation})
}
fn next_ccw(u:usize,incoming:usize,f:&Frame)->usize {
    let row=&f.rotation[u]; let i=row.iter().position(|&v|v==incoming).unwrap(); row[(i+1)%row.len()]
}
fn first_ccw(u:usize,f:&Frame)->usize {
    let ray=(f.points[f.target].x-f.points[u].x,f.points[f.target].y-f.points[u].y);
    let mut relative:Vec<(i64,i64,usize)>=f.adjacency[u].iter().map(|&v| {
        let dx=f.points[v].x-f.points[u].x; let dy=f.points[v].y-f.points[u].y;
        (ray.0*dx+ray.1*dy,cross(ray.0,ray.1,dx,dy),v)
    }).collect();
    relative.sort_by(|&a,&b|polar_cmp(a,b)); relative[0].2
}
fn edge_id(u:usize,v:usize,f:&Frame)->usize {
    let edge=if u<v {(u,v)} else {(v,u)};
    f.edges.binary_search(&edge).unwrap()
}
fn put64(out:&mut Vec<u8>,word:i64) { out.extend_from_slice(&word.to_le_bytes()); }
fn run(frame:&Frame)->Vec<u8> {
    let mut route=vec![frame.source]; let mut events:Vec<(usize,usize,Fraction)>=Vec::new();
    let (mut current,mut previous)=(frame.source,None); let mut first=None;
    let mut lf=Fraction{num:0,den:1}; let mut status=0i64;
    let dx=frame.points[frame.source].x-frame.points[frame.target].x;
    let dy=frame.points[frame.source].y-frame.points[frame.target].y; let start_dist=dx*dx+dy*dy;
    loop {
        if current==frame.target { status=2; break; }
        let dx=frame.points[current].x-frame.points[frame.target].x;
        let dy=frame.points[current].y-frame.points[frame.target].y;
        if dx*dx+dy*dy<start_dist { status=1; break; }
        if route.len()-1>=2*frame.m { break; }
        let mut candidate=previous.map_or_else(||first_ccw(current,frame),|p|next_ccw(current,p,frame));
        let mut changed=false;
        loop {
            let crossing=proper_crossing(frame.points[frame.source],frame.points[frame.target],frame.points[current],frame.points[candidate]);
            let Some(t)=crossing else { break; };
            if t.num*lf.den<=lf.num*t.den { break; }
            events.push((route.len()-1,edge_id(current,candidate,frame),t)); lf=t; changed=true;
            candidate=next_ccw(current,candidate,frame);
        }
        let dart=(current,candidate);
        if changed || first.is_none() { first=Some(dart); }
        else if first==Some(dart) { break; }
        previous=Some(current); current=candidate; route.push(current);
    }
    let mut out=Vec::new(); put64(&mut out,status); put64(&mut out,(route.len()-1) as i64);
    for v in route { put64(&mut out,v as i64); }
    put64(&mut out,events.len() as i64);
    for (step,edge,t) in events { put64(&mut out,step as i64); put64(&mut out,edge as i64); put64(&mut out,t.num); put64(&mut out,t.den); }
    out
}

#[no_mangle]
pub unsafe extern "C" fn gpsr_perimeter_recovery_trace(input:*const i64,length:usize,
    output:*mut u8,capacity:usize)->i64 {
    if input.is_null() || length<4 || length>MAX_INPUT { return -1; }
    let frame_slice=slice::from_raw_parts(input,length);
    let Some(frame)=decode(frame_slice) else { return -1; };
    if output.is_null() || capacity<MAX_OUTPUT { return -2; }
    let bytes=run(&frame);
    std::ptr::copy_nonoverlapping(bytes.as_ptr(),output,bytes.len());
    bytes.len() as i64
}
