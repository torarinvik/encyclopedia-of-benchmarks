const MIN_N: usize = 3;
const MAX_N: usize = 5;
const MAX_LENGTH: usize = 12;
const DP_SIZE: usize = 10;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Score { num: i64, den: i64 }
#[derive(Clone, Copy, Default)]
struct Cell { minimum: Score, count: i32, valid: bool, split: i32 }
#[derive(Clone, Copy, Default)]
struct Triangle { a: usize, b: usize, c: usize }
#[derive(Clone, Copy)]
struct Triangles { items: [Triangle; 3], count: usize }
#[derive(Clone, Copy)]
struct Objective { minimum: Score, count: i32 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r=a%b; a=b; b=r; }
    a
}
fn fraction(num: i64, den: i64) -> Score {
    let d=gcd(num,den); Score { num:num/d, den:den/d }
}
fn compare(a: Score, b: Score) -> i32 {
    let x=a.num*b.den; let y=b.num*a.den;
    if x<y {-1} else if x>y {1} else {0}
}
fn triangle_score(points: &[Point; MAX_N], n: usize, a: usize, b: usize, c: usize) -> Score {
    let p=points[a%n]; let q=points[b%n]; let r=points[c%n];
    let area=orient(p,q,r).abs();
    let lens=[(p.x-q.x).pow(2)+(p.y-q.y).pow(2),
              (q.x-r.x).pow(2)+(q.y-r.y).pow(2),
              (r.x-p.x).pow(2)+(r.y-p.y).pow(2)];
    let mut best=fraction(area*area,lens[0]);
    for den in lens.iter().skip(1) {
        let candidate=fraction(area*area,*den);
        if compare(candidate,best)<0 {best=candidate;}
    }
    best
}
fn join(left: Cell, right: Cell, triangle: Score) -> Objective {
    let mut out=Objective {minimum:triangle,count:1};
    for child in [left,right] {
        if !child.valid {continue;}
        let cmp=compare(child.minimum,out.minimum);
        if cmp<0 {out.minimum=child.minimum;out.count=child.count;}
        else if cmp==0 {out.count+=child.count;}
    }
    out
}
fn better(candidate: Objective, current: Objective) -> bool {
    let cmp=compare(candidate.minimum,current.minimum);
    cmp>0 || (cmp==0 && candidate.count<current.count)
}
fn evaluate(points: &[Point; MAX_N], n: usize, triangles: &Triangles) -> Objective {
    let first=triangles.items[0];
    let mut out=Objective {minimum:triangle_score(points,n,first.a,first.b,first.c),count:1};
    for t in triangles.items.iter().take(triangles.count).skip(1) {
        let score=triangle_score(points,n,t.a,t.b,t.c);
        let cmp=compare(score,out.minimum);
        if cmp<0 {out.minimum=score;out.count=1;}
        else if cmp==0 {out.count+=1;}
    }
    out
}
fn collect(start: usize, end: usize, table: &[Cell; DP_SIZE*DP_SIZE], n: usize,
           out: &mut Triangles) {
    if end-start<2 {return;}
    let middle=table[start*DP_SIZE+end].split as usize;
    out.items[out.count]=Triangle {a:start%n,b:middle%n,c:end%n}; out.count+=1;
    collect(start,middle,table,n,out); collect(middle,end,table,n,out);
}
fn has_edge(triangles: &Triangles, left: usize, right: usize) -> bool {
    for t in triangles.items.iter().take(triangles.count) {
        for (a,b) in [(t.a,t.b),(t.b,t.c),(t.c,t.a)] {
            if a.min(b)==left && a.max(b)==right {return true;}
        }
    }
    false
}
fn solve(points: &[Point; MAX_N], n: usize) -> i64 {
    let mut table=[Cell::default(); DP_SIZE*DP_SIZE];
    for span in 2..=n.saturating_sub(2) {
        for start in 0..n {
            let end=start+span;
            let mut best: Option<Objective>=None; let mut best_middle=0;
            for middle in start+1..end {
                let candidate=join(table[start*DP_SIZE+middle],table[middle*DP_SIZE+end],
                                   triangle_score(points,n,start,middle,end));
                if best.is_none() || better(candidate,best.unwrap()) {
                    best=Some(candidate); best_middle=middle;
                }
            }
            let value=best.unwrap();
            table[start*DP_SIZE+end]=Cell {minimum:value.minimum,count:value.count,valid:true,split:best_middle as i32};
        }
    }
    let mut current=Triangles {items:[Triangle::default();3],count:0};
    for middle in 1..n-1 {current.items[current.count]=Triangle {a:0,b:middle,c:middle+1};current.count+=1;}
    let mut current_value=evaluate(points,n,&current); let mut improvements=0;
    loop {
        let mut changed=false;
        'scan: for left in 0..n {
            for right in left+2..n {
                if left==0 && right==n-1 {continue;}
                if has_edge(&current,left,right) {continue;}
                let mut candidate=Triangles {items:[Triangle::default();3],count:0};
                collect(left,right,&table,n,&mut candidate);
                collect(right,left+n,&table,n,&mut candidate);
                let value=evaluate(points,n,&candidate);
                if better(value,current_value) {
                    current=candidate;current_value=value;improvements+=1;
                    if improvements>30 {return -1;}
                    changed=true;break 'scan;
                }
            }
        }
        if !changed {return current_value.minimum.num*513+current_value.minimum.den;}
    }
}

#[no_mangle]
pub unsafe extern "C" fn max_min_triangle_height_triangulation(input: *const i64, length: usize) -> i64 {
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
    for i in 0..n {let next=(i+1)%n;area2+=points[i].x*points[next].y-points[i].y*points[next].x;}
    if area2<=0 {return -1;}
    for a in 0..n {for b in a+1..n {for c in b+1..n {if orient(points[a],points[b],points[c])==0{return -1;}}}}
    for edge in 0..n {
        let next=(edge+1)%n;
        for vertex in 0..n {if vertex!=edge && vertex!=next && orient(points[edge],points[next],points[vertex])<=0{return -1;}}
    }
    solve(&points,n)
}
