use std::cmp::Ordering;
use std::ptr;

const MAX_V: usize = 6;
const MAX_CROSS: usize = 36;
const MAX_BYTES: usize = 1680;

#[derive(Clone, Copy, Debug)]
struct Rat { n: i64, d: i64 }
#[derive(Clone, Copy, Debug)]
struct Point { x: Rat, y: Rat }
#[derive(Clone, Copy)]
struct Crossing { p: Point, ta: Rat, tb: Rat, ae: bool, ax: bool, be: bool, bx: bool }
#[derive(Clone, Copy)]
struct Node { p: Point, cross: i32 }
#[derive(Clone, Copy)]
struct Event { t: Rat, id: usize }
type IPoint = (i64, i64);
type Ring = Vec<Point>;

fn gcd(mut a: i64, mut b: i64) -> i64 {
    a = a.abs(); b = b.abs();
    while b != 0 { let r = a % b; a = b; b = r; }
    if a == 0 { 1 } else { a }
}
fn rat(n: i64, d: i64) -> Rat {
    let (n, d) = if d < 0 { (-n, -d) } else { (n, d) };
    let g = gcd(n, d); Rat { n: n / g, d: d / g }
}
fn cmp_rat(a: Rat, b: Rat) -> Ordering { (a.n * b.d).cmp(&(b.n * a.d)) }
fn eq_rat(a: Rat, b: Rat) -> bool { a.n == b.n && a.d == b.d }
fn cmp_point(a: Point, b: Point) -> Ordering {
    let x = cmp_rat(a.x, b.x); if x != Ordering::Equal { x } else { cmp_rat(a.y, b.y) }
}
fn eq_point(a: Point, b: Point) -> bool { eq_rat(a.x,b.x) && eq_rat(a.y,b.y) }
fn ip(x: i64, y: i64) -> Point { Point { x: rat(x,1), y: rat(y,1) } }
fn orient(a: IPoint, b: IPoint, c: IPoint) -> i64 {
    (b.0-a.0)*(c.1-a.1) - (b.1-a.1)*(c.0-a.0)
}
fn on_segment(a: IPoint, b: IPoint, p: IPoint) -> bool {
    orient(a,b,p)==0 && p.0>=a.0.min(b.0) && p.0<=a.0.max(b.0)
        && p.1>=a.1.min(b.1) && p.1<=a.1.max(b.1)
}
// 0 disjoint, 1 proper crossing, 2 contact or collinear overlap.
fn relation(a: IPoint,b: IPoint,c: IPoint,d: IPoint)->i32 {
    let (o1,o2,o3,o4)=(orient(a,b,c),orient(a,b,d),orient(c,d,a),orient(c,d,b));
    if ((o1>0&&o2<0)||(o1<0&&o2>0)) && ((o3>0&&o4<0)||(o3<0&&o4>0)) { return 1; }
    if (o1==0&&on_segment(a,b,c)) || (o2==0&&on_segment(a,b,d))
        || (o3==0&&on_segment(c,d,a)) || (o4==0&&on_segment(c,d,b)) { return 2; }
    0
}
fn valid_poly(p: &[IPoint]) -> bool {
    let n=p.len(); let mut area=0i64;
    for i in 0..n {
        let prev=p[(i+n-1)%n]; let here=p[i]; let next=p[(i+1)%n];
        area += here.0*next.1-here.1*next.0;
        if orient(prev,here,next)==0 || p[..i].contains(&here) { return false; }
    }
    if area<=0 { return false; }
    for i in 0..n { for j in i+1..n {
        if j==i+1 || (i==0&&j==n-1) { continue; }
        if relation(p[i],p[(i+1)%n],p[j],p[(j+1)%n])!=0 { return false; }
    }}
    true
}
fn inside(p: IPoint, poly: &[IPoint])->bool {
    let mut winding=0;
    for i in 0..poly.len() {
        let a=poly[i]; let b=poly[(i+1)%poly.len()]; let side=orient(a,b,p);
        if a.1<=p.1 && p.1<b.1 && side>0 { winding+=1; }
        else if b.1<=p.1 && p.1<a.1 && side<0 { winding-=1; }
    }
    winding!=0
}
fn crossing_point(a: IPoint,b: IPoint,c: IPoint,d: IPoint)->(Rat,Rat,Point) {
    let (rx,ry)=(b.0-a.0,b.1-a.1); let (sx,sy)=(d.0-c.0,d.1-c.1);
    let mut den=rx*sy-ry*sx;
    let mut tn=(c.0-a.0)*sy-(c.1-a.1)*sx;
    let mut un=(c.0-a.0)*ry-(c.1-a.1)*rx;
    if den<0 { den=-den; tn=-tn; un=-un; }
    let ta=rat(tn,den); let tb=rat(un,den);
    let x=rat(a.0*den+rx*tn,den); let y=rat(a.1*den+ry*tn,den);
    (ta,tb,Point{x,y})
}
fn make_nodes(poly:&[IPoint], events:&[Vec<Event>], crossings:&[Crossing], is_a:bool,
              positions:&mut [usize])->Vec<Node> {
    let mut nodes=Vec::new();
    for edge in 0..poly.len() {
        nodes.push(Node{p:ip(poly[edge].0,poly[edge].1),cross:-1});
        let mut local=events[edge].clone();
        local.sort_by(|a,b| cmp_rat(a.t,b.t).then(a.id.cmp(&b.id)));
        for e in local {
            positions[e.id]=nodes.len();
            nodes.push(Node{p:crossings[e.id].p,cross:e.id as i32});
        }
    }
    let _ = is_a;
    nodes
}
fn canonicalize(rings:&mut Vec<Ring>) {
    for ring in rings.iter_mut() {
        let pivot=(0..ring.len()).min_by(|&i,&j|cmp_point(ring[i],ring[j])).unwrap_or(0);
        ring.rotate_left(pivot);
    }
    rings.sort_by(|a,b| {
        for (x,y) in a.iter().zip(b.iter()) { let c=cmp_point(*x,*y); if c!=Ordering::Equal{return c;} }
        a.len().cmp(&b.len())
    });
}
fn serialize(rings:&mut Vec<Ring>)->Vec<u8> {
    canonicalize(rings);
    let mut words=Vec::<i64>::new(); words.push(rings.len() as i64);
    for r in rings.iter() { words.push(r.len() as i64); for p in r {
        words.extend([p.x.n,p.x.d,p.y.n,p.y.d]);
    }}
    let mut out=Vec::with_capacity(words.len()*8);
    for w in words { out.extend_from_slice(&w.to_le_bytes()); }
    out
}

#[no_mangle]
pub unsafe extern "C" fn weiler_atherton_polygon_intersection(
    input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null() || length<2 || length>27 { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let na=values[0]; let nb=values[1];
    if !(3..=MAX_V as i64).contains(&na) || !(3..=MAX_V as i64).contains(&nb)
        || length != 2+2*na as usize+2*nb as usize { return -1; }
    let na=na as usize; let nb=nb as usize; let mut at=2;
    let mut a=Vec::with_capacity(na); let mut b=Vec::with_capacity(nb);
    for _ in 0..na { let x=values[at];let y=values[at+1];at+=2;
        if !(-16..=16).contains(&x)||!(-16..=16).contains(&y){return -1;} a.push((x,y)); }
    for _ in 0..nb { let x=values[at];let y=values[at+1];at+=2;
        if !(-16..=16).contains(&x)||!(-16..=16).contains(&y){return -1;} b.push((x,y)); }
    if !valid_poly(&a)||!valid_poly(&b){return -1;}
    let mut crossings=Vec::<Crossing>::new(); let mut ea=vec![Vec::<Event>::new();na];let mut eb=vec![Vec::<Event>::new();nb];
    for i in 0..na { for j in 0..nb {
        let a0=a[i];let a1=a[(i+1)%na];let b0=b[j];let b1=b[(j+1)%nb];let rel=relation(a0,a1,b0,b1);
        if rel==2{return -1;} if rel==1 {
            let (ta,tb,p)=crossing_point(a0,a1,b0,b1);
            let ab=orient(b0,b1,a0);let aa=orient(b0,b1,a1);let bb=orient(a0,a1,b0);let ba=orient(a0,a1,b1);
            let c=Crossing{p,ta,tb,ae:ab<0&&aa>0,ax:ab>0&&aa<0,be:bb<0&&ba>0,bx:bb>0&&ba<0};
            if (!c.ae&&!c.ax)||(!c.be&&!c.bx)||c.ae==c.be{return -1;}
            let id=crossings.len();crossings.push(c);ea[i].push(Event{t:ta,id});eb[j].push(Event{t:tb,id});
        }
    }}
    let mut rings=Vec::<Ring>::new();
    if crossings.is_empty() {
        if inside(a[0],&b){rings.push(a.iter().map(|p|ip(p.0,p.1)).collect());}
        else if inside(b[0],&a){rings.push(b.iter().map(|p|ip(p.0,p.1)).collect());}
    } else {
        let mut pa=vec![0usize;crossings.len()];let mut pb=vec![0usize;crossings.len()];
        let nodes_a=make_nodes(&a,&ea,&crossings,true,&mut pa);let nodes_b=make_nodes(&b,&eb,&crossings,false,&mut pb);
        let mut visited=vec![false;crossings.len()];
        for start in 0..nodes_a.len() {
            let sid=nodes_a[start].cross;if sid<0||!crossings[sid as usize].ae||visited[sid as usize]{continue;}
            let sid=sid as usize;let mut ring=vec![nodes_a[start].p];visited[sid]=true;
            let mut active_a=true;let mut index=start;let mut guard=0usize;
            loop {
                guard+=1;if guard>2*crossings.len()+na+nb+1||ring.len()>=48{return -1;}
                let nodes=if active_a{&nodes_a}else{&nodes_b};let next=(index+1)%nodes.len();let node=nodes[next];ring.push(node.p);
                if node.cross>=0 { let id=node.cross as usize;visited[id]=true;
                    if active_a && id==sid {ring.pop();break;}
                    let exits=if active_a{crossings[id].ax}else{crossings[id].bx};
                    if exits { if id==sid {ring.pop();break;}
                        active_a=!active_a;index=if active_a{pa[id]}else{pb[id]};continue; }
                }
                index=next;
            }
            if ring.len()<3{return -1;}rings.push(ring);
        }
        if visited.iter().any(|v|!*v){return -1;}
    }
    let bytes=serialize(&mut rings);if bytes.len()>MAX_BYTES{return -1;}
    if output.is_null()||capacity<bytes.len(){return -2;}
    ptr::copy_nonoverlapping(bytes.as_ptr(),output,bytes.len());bytes.len() as i64
}
