//! Independently authored draft; not compiled or run.
#[derive(Clone, Copy, Default)]
struct Line { a:i64, b:i64, c:i64, norm:i64 }
#[derive(Clone, Copy, Default)]
struct Point { x:i64, y:i64, den:i64 }
fn gcd(mut a:i64,mut b:i64)->i64 {
    a=a.abs(); b=b.abs();
    while b!=0 { (a,b)=(b,a%b); }
    a
}
fn half(l:Line)->u8 { if l.b>0 || (l.b==0 && l.a>=0) {0} else {1} }
fn compare(a:Line,b:Line)->std::cmp::Ordering {
    let h=half(a).cmp(&half(b));
    if h!=std::cmp::Ordering::Equal { return h; }
    let cross=a.a*b.b-a.b*b.a;
    if cross>0 { std::cmp::Ordering::Less }
    else if cross<0 { std::cmp::Ordering::Greater }
    else { a.c.cmp(&b.c) }
}
fn intersect(a:Line,b:Line)->Option<Point> {
    let mut den=a.a*b.b-b.a*a.b;
    if den==0 { return None; }
    let mut x=a.c*b.b-a.b*b.c; let mut y=a.a*b.c-a.c*b.a;
    if den<0 { den=-den; x=-x; y=-y; }
    Some(Point{x,y,den})
}
fn outside(l:Line,p:Point)->bool { l.a*p.x+l.b*p.y>l.c*p.den }
fn feasible(lines:&[Line],radius:i64)->bool {
    let mut queue=[Line::default();16]; let mut head=0usize; let mut tail=0usize;
    for &line in lines {
        let mut h=line; h.c=h.c*32768-(radius*32768-1)*h.norm;
        if tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b {
            if h.c>=queue[tail-1].c { continue; }
            tail-=1;
        }
        while tail-head>1 {
            let Some(p)=intersect(queue[tail-2],queue[tail-1]) else { break; };
            if !outside(h,p) { break; }
            tail-=1;
        }
        while tail-head>1 {
            let Some(p)=intersect(queue[head],queue[head+1]) else { break; };
            if !outside(h,p) { break; }
            head+=1;
        }
        if tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0 { return false; }
        queue[tail]=h; tail+=1;
    }
    while tail-head>2 {
        let Some(p)=intersect(queue[tail-2],queue[tail-1]) else { break; };
        if !outside(queue[head],p) { break; }
        tail-=1;
    }
    while tail-head>2 {
        let Some(p)=intersect(queue[head],queue[head+1]) else { break; };
        if !outside(queue[tail-1],p) { break; }
        head+=1;
    }
    if tail-head<3 { return false; }
    for i in head..tail {
        if intersect(queue[i],queue[if i+1==tail {head} else {i+1}]).is_none() { return false; }
    }
    true
}
#[no_mangle]
pub unsafe extern "C" fn convex_polygon_integer_inradius(input:*const i64,length:usize)->i64 {
    if input.is_null() || !(1..=38).contains(&length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,length) };
    if !(0..=12).contains(&values[0]) { return -1; }
    let n=values[0] as usize;
    if length!=1+3*n { return -1; }
    let mut lines=[Line::default();16];
    for i in 0..n {
        let (a,b,c)=(values[1+3*i],values[2+3*i],values[3+3*i]);
        if !(-15..=15).contains(&a) || !(-15..=15).contains(&b) || !(-128..=128).contains(&c) { return -1; }
        let squared=a*a+b*b; let mut norm=0;
        while norm*norm<squared { norm+=1; }
        if norm==0 || norm*norm!=squared || gcd(a,b)!=1 { return -1; }
        lines[i]=Line{a,b,c,norm};
    }
    lines[n]=Line{a:1,b:0,c:256,norm:1}; lines[n+1]=Line{a:0,b:1,c:256,norm:1};
    lines[n+2]=Line{a:-1,b:0,c:256,norm:1}; lines[n+3]=Line{a:0,b:-1,c:256,norm:1};
    let lines=&mut lines[..n+4]; lines.sort_unstable_by(|a,b| compare(*a,*b));
    if !feasible(lines,0) { return -2; }
    let (mut low,mut high)=(0i64,257i64);
    while high-low>1 {
        let middle=(low+high)/2;
        if feasible(lines,middle) { low=middle; } else { high=middle; }
    }
    low
}
