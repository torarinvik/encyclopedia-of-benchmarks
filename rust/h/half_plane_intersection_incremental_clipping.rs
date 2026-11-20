//! Independently authored draft; not compiled or run.
#[derive(Clone, Copy, Default)]
struct Line { a: i64, b: i64, c: i64 }
#[derive(Clone, Copy, Default)]
struct Vertex { x: i64, y: i64, den: i64, incoming: usize }
fn gcd(mut a: i64, mut b: i64) -> i64 {
    a = a.abs(); b = b.abs();
    while b != 0 { (a,b) = (b,a%b); }
    a
}
fn intersect(a: Line, b: Line) -> Option<Vertex> {
    let mut d = a.a*b.b-b.a*a.b;
    if d == 0 { return None; }
    let mut x = a.c*b.b-a.b*b.c;
    let mut y = a.a*b.c-a.c*b.a;
    if d < 0 { d = -d; x = -x; y = -y; }
    let g = gcd(gcd(x,y),d);
    Some(Vertex{x:x/g, y:y/g, den:d/g, incoming:0})
}
fn side(l: Line, p: Vertex) -> i64 { l.a*p.x+l.b*p.y-l.c*p.den }
fn same(a: Vertex, b: Vertex) -> bool { a.x*b.den == b.x*a.den && a.y*b.den == b.y*a.den }
fn turn(a: Vertex, b: Vertex, c: Vertex) -> i64 {
    let dx1=b.x*a.den-a.x*b.den; let dy1=b.y*a.den-a.y*b.den;
    let dx2=c.x*b.den-b.x*c.den; let dy2=c.y*b.den-b.y*c.den;
    dx1*dy2-dy1*dx2
}
fn append(out: &mut [Vertex;32], used: &mut usize, p: Vertex) {
    if *used == 0 || !same(out[*used-1],p) { out[*used] = p; *used += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn half_plane_intersection_incremental_clipping(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=38).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input,length) };
    if !(0..=12).contains(&values[0]) { return -1; }
    let n=values[0] as usize;
    if length != 1+3*n { return -1; }
    let mut lines=[Line::default();16];
    lines[0]=Line{a:-1,b:0,c:256}; lines[1]=Line{a:0,b:-1,c:256};
    lines[2]=Line{a:1,b:0,c:256}; lines[3]=Line{a:0,b:1,c:256};
    for i in 0..n {
        let (a,b,c)=(values[1+3*i],values[2+3*i],values[3+3*i]);
        if !(-16..=16).contains(&a) || !(-16..=16).contains(&b)
            || !(-128..=128).contains(&c) || (a==0 && b==0) || gcd(a,b)!=1 { return -1; }
        lines[4+i]=Line{a,b,c};
    }
    let mut polygon=[Vertex::default();32];
    polygon[0]=Vertex{x:-256,y:-256,den:1,incoming:0};
    polygon[1]=Vertex{x:256,y:-256,den:1,incoming:1};
    polygon[2]=Vertex{x:256,y:256,den:1,incoming:2};
    polygon[3]=Vertex{x:-256,y:256,den:1,incoming:3};
    let mut count=4;
    for line in 4..4+n {
        if count < 3 { break; }
        let mut next=[Vertex::default();32]; let mut used=0;
        for i in 0..count {
            let s=polygon[(i+count-1)%count]; let e=polygon[i];
            let inside_s=side(lines[line],s)<=0; let inside_e=side(lines[line],e)<=0;
            if inside_s != inside_e {
                let Some(mut crossing)=intersect(lines[e.incoming],lines[line]) else { return -1; };
                crossing.incoming=if inside_s { e.incoming } else { line };
                append(&mut next,&mut used,crossing);
            }
            if inside_e { append(&mut next,&mut used,e); }
        }
        if used>1 && same(next[0],next[used-1]) {
            next[0].incoming=next[used-1].incoming; used-=1;
        }
        count=used; polygon=next;
        let mut noncollinear=false;
        if count>=3 {
            for i in 0..count {
                if turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count])!=0 { noncollinear=true; }
            }
        }
        if !noncollinear { count=0; }
    }
    loop {
        if count<3 { break; }
        let mut removed=false;
        for i in 0..count {
            if turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0 {
                for j in i..count-1 { polygon[j]=polygon[j+1]; }
                count-=1; removed=true; break;
            }
        }
        if !removed { break; }
    }
    if count<3 { count=0; }
    let mut first=0;
    for i in 1..count {
        let yi=polygon[i].y*polygon[first].den; let yf=polygon[first].y*polygon[i].den;
        if yi<yf || (yi==yf && polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den) { first=i; }
    }
    let needed=(1+4*count)*8;
    if output.is_null() || capacity<needed { return -2; }
    let out=unsafe { std::slice::from_raw_parts_mut(output,needed) };
    out[0..8].copy_from_slice(&(count as i64).to_le_bytes());
    for i in 0..count {
        let p=polygon[(first+i)%count];
        let gx=gcd(p.x,p.den); let gy=gcd(p.y,p.den);
        for (j,value) in [p.x/gx,p.den/gx,p.y/gy,p.den/gy].iter().enumerate() {
            let offset=8+32*i+8*j;
            out[offset..offset+8].copy_from_slice(&value.to_le_bytes());
        }
    }
    needed as i64
}
