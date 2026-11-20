const MIN_N: usize = 3;
const MAX_N: usize = 6;
const MAX_LENGTH: usize = 14;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
fn distance_squared(a: Point, b: Point) -> i64 {
    let dx=a.x-b.x;
    let dy=a.y-b.y;
    dx*dx+dy*dy
}
fn diagonal_bit(n: usize, a: usize, b: usize) -> i32 {
    let left=a.min(b);
    let right=a.max(b);
    let mut bit=0;
    for first in 0..n {
        for second in first+2..n {
            if first==0 && second==n-1 {continue;}
            if first==left && second==right {return bit;}
            bit+=1;
        }
    }
    -1
}
fn angle_at_least_sixty(p: Point, q: Point, r: Point) -> bool {
    let ux=p.x-q.x; let uy=p.y-q.y;
    let vx=r.x-q.x; let vy=r.y-q.y;
    let dot=ux*vx+uy*vy;
    if dot<=0 {return true;}
    let norm_u=ux*ux+uy*uy;
    let norm_v=vx*vx+vy*vy;
    4*dot*dot<=norm_u*norm_v
}
fn greedy(points: &[Point; MAX_N], n: usize) -> i64 {
    let mut next=[0usize;MAX_N];
    for i in 0..n {next[i]=(i+1)%n;}
    let mut shortest=513_i64;
    for i in 0..n {shortest=shortest.min(distance_squared(points[i],points[(i+1)%n]));}
    let mut active=n;
    let mut p=0usize;
    let mut q=next[p];
    let mut r=next[q];
    let mut steps=0usize;
    let mut diagonal_mask=0_i64;
    while active>3 {
        steps+=1;
        if steps>4*n {return -1;}
        if angle_at_least_sixty(points[p],points[q],points[r]) {
            shortest=shortest.min(distance_squared(points[p],points[r]));
            let bit=diagonal_bit(n,p,r);
            if bit<0 {return -1;}
            diagonal_mask |= 1_i64 << bit;
            next[p]=r;
            active-=1;
            q=r;
            r=next[r];
        } else {
            p=q;
            q=r;
            r=next[r];
        }
    }
    shortest*512+diagonal_mask
}

#[no_mangle]
pub unsafe extern "C" fn convex_polygon_max_min_length_triangulation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_LENGTH).contains(&length) {return -1;}
    let words=std::slice::from_raw_parts(input,length);
    if words[0]<MIN_N as i64 || words[0]>MAX_N as i64 {return -1;}
    let n=words[0] as usize;
    if length!=1+2*n {return -1;}
    let mut points=[Point::default();MAX_N];
    for i in 0..n {
        points[i]=Point{x:words[1+2*i],y:words[2+2*i]};
        if points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8 {return -1;}
        for j in 0..i {if points[i].x==points[j].x && points[i].y==points[j].y {return -1;}}
    }
    let mut area2=0_i64;
    for i in 0..n {let following=(i+1)%n;area2+=points[i].x*points[following].y-points[i].y*points[following].x;}
    if area2<=0 {return -1;}
    for a in 0..n {for b in a+1..n {for c in b+1..n {if orient(points[a],points[b],points[c])==0{return -1;}}}}
    for edge in 0..n {
        let following=(edge+1)%n;
        for vertex in 0..n {if vertex!=edge && vertex!=following && orient(points[edge],points[following],points[vertex])<=0{return -1;}}
    }
    greedy(&points,n)
}
