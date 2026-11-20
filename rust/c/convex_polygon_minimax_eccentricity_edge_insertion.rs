const MIN_N: usize = 3;
const MAX_N: usize = 6;
const MAX_LEN: usize = 14;
const MAX_TRI: usize = 4;
const MAX_ALL: usize = 14;
const MAX_DIAG: usize = 9;
const MAX_TRIPLES: usize = 20;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy, Default)]
struct Triangle { a: usize, b: usize, c: usize }
#[derive(Clone, Copy, Default)]
struct Triangulation { triangles: [Triangle; MAX_TRI], count: usize, edges: u64 }
#[derive(Clone, Copy, Default)]
struct Fraction { num: i64, den: i64 }
#[derive(Clone, Copy, Default)]
struct Metrics { maximum: Fraction, worst: u64 }

fn orient(a: Point, b: Point, c: Point) -> i64 {
    (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
fn gcd64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r=a%b; a=b; b=r; }
    a
}
fn fraction(num: i64, den: i64) -> Fraction {
    let g=gcd64(num,den); Fraction{num:num/g,den:den/g}
}
fn compare(a: Fraction, b: Fraction) -> i32 {
    let left=a.num*b.den; let right=b.num*a.den;
    if left<right {-1} else if left>right {1} else {0}
}
fn edge_bit(a: usize,b: usize) -> u64 {
    let lo=a.min(b); let hi=a.max(b); 1_u64 << (lo*MAX_N+hi)
}
fn proper_cross(p: &[Point;MAX_N],a:usize,b:usize,c:usize,d:usize)->bool {
    orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0 && orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0
}
fn inside_triangle(p:&[Point;MAX_N],t:Triangle,v:usize)->bool {
    let direction=orient(p[t.a],p[t.b],p[t.c]);
    orient(p[t.a],p[t.b],p[v])*direction>0 && orient(p[t.b],p[t.c],p[v])*direction>0 && orient(p[t.c],p[t.a],p[v])*direction>0
}
fn triangle_score(p:&[Point;MAX_N],t:Triangle,sides:&mut [i64;3])->Fraction {
    let a=p[t.a];let b=p[t.b];let c=p[t.c];
    sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y);
    sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y);
    sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y);
    let mut k=0;if sides[1]>sides[k]{k=1;}if sides[2]>sides[k]{k=2;}
    let other=sides[0]+sides[1]+sides[2]-sides[k];
    if sides[k]<=other{return Fraction{num:0,den:1};}
    let area=orient(a,b,c).abs();let difference=sides[k]-other;
    fraction(sides[k]*difference*difference,16*area*area)
}
fn triangle_id(a:usize,b:usize,c:usize,n:usize)->usize {
    let mut id=0;for x in 0..n{for y in x+1..n{for z in y+1..n{if x==a&&y==b&&z==c{return id;}id+=1;}}}0
}
fn evaluate(p:&[Point;MAX_N],n:usize,t:Triangulation)->Metrics {
    let mut m=Metrics{maximum:Fraction{num:0,den:1},worst:0};
    for i in 0..t.count {let mut sides=[0_i64;3];let s=triangle_score(p,t.triangles[i],&mut sides);let c=compare(s,m.maximum);let bit=1_u64<<triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n);
        if c>0{m.maximum=s;m.worst=bit;}else if c==0{m.worst|=bit;}}
    m
}
fn improves(a:Metrics,b:Metrics)->bool {
    let c=compare(a.maximum,b.maximum);c<0||(c==0&&a.worst!=b.worst&&(a.worst&b.worst)==a.worst)
}
fn preferable(a:Metrics,b:Metrics)->bool {
    let c=compare(a.maximum,b.maximum);if c!=0{return c<0;}
    let x=a.worst.count_ones();let y=b.worst.count_ones();x<y||(x==y&&a.worst<b.worst)
}
fn enumerate(p:&[Point;MAX_N],n:usize,out:&mut [Triangulation;MAX_ALL])->usize {
    let mut da=[0_usize;MAX_DIAG];let mut db=[0_usize;MAX_DIAG];let mut m=0;
    for a in 0..n{for b in a+2..n{if a==0&&b==n-1{continue;}da[m]=a;db[m]=b;m+=1;}}
    let mut boundary=0_u64;for a in 0..n{boundary|=edge_bit(a,(a+1)%n);}
    let mut total=0;
    for mask in 0..(1_usize<<m){let count=(0..m).filter(|i|((mask>>i)&1)!=0).count();if count!=n-3{continue;}
        let mut crossing=false;for i in 0..m{if crossing{break;}if ((mask>>i)&1)==0{continue;}for j in i+1..m{if ((mask>>j)&1)!=0&&proper_cross(p,da[i],db[i],da[j],db[j]){crossing=true;break;}}}if crossing{continue;}
        let mut edges=boundary;for i in 0..m{if ((mask>>i)&1)!=0{edges|=edge_bit(da[i],db[i]);}}
        let mut faces=[Triangle::default();MAX_TRI];let mut face_count=0;
        for a in 0..n{for b in a+1..n{for c in b+1..n{if edges&edge_bit(a,b)==0||edges&edge_bit(b,c)==0||edges&edge_bit(c,a)==0{continue;}
            let t=Triangle{a,b,c};let contains=(0..n).any(|v|v!=a&&v!=b&&v!=c&&inside_triangle(p,t,v));
            if !contains&&face_count<MAX_TRI{faces[face_count]=t;face_count+=1;}
        }}}
        if face_count==n-2&&total<MAX_ALL{out[total]=Triangulation{triangles:faces,count:face_count,edges};total+=1;}
    }
    total
}
fn rank_score(p:&[Point;MAX_N],n:usize,target:Fraction)->i64 {
    let mut seen=[Fraction::default();MAX_TRIPLES];let mut count=0;
    for a in 0..n{for b in a+1..n{for c in b+1..n{let mut sides=[0_i64;3];let s=triangle_score(p,Triangle{a,b,c},&mut sides);if compare(s,target)>=0{continue;}if !(0..count).any(|i|compare(s,seen[i])==0){seen[count]=s;count+=1;}}}}
    (count+1) as i64
}
fn solve(p:&[Point;MAX_N],n:usize)->i64 {
    let mut all=[Triangulation::default();MAX_ALL];let total=enumerate(p,n,&mut all);let mut fan=Triangulation::default();
    for k in 1..n-1{fan.triangles[fan.count]=Triangle{a:0,b:k,c:k+1};fan.count+=1;}
    for a in 0..n{fan.edges|=edge_bit(a,(a+1)%n);}for k in 2..n-1{fan.edges|=edge_bit(0,k);}
    let Some(mut current_index)=(0..total).find(|&i|all[i].edges==fan.edges) else{return -1;};
    let mut current=all[current_index];let mut cm=evaluate(p,n,current);
    for _ in 0..MAX_ALL{let mut changed=false;
        for ti in 0..current.count{if changed{break;}let t=current.triangles[ti];let mut sides=[0_i64;3];let score=triangle_score(p,t,&mut sides);if compare(score,cm.maximum)!=0||score.num==0{continue;}
            let mut largest=0;if sides[1]>sides[largest]{largest=1;}if sides[2]>sides[largest]{largest=2;}let vertices=[t.a,t.b,t.c];
            for ap in 0..3{if changed{break;}if sides[ap]!=sides[largest]{continue;}let q=vertices[ap];let mut opp=[0_usize;2];let mut used=0;for k in 0..3{if k!=ap{opp[used]=vertices[k];used+=1;}}
                for s in 0..n{if changed{break;}let added=edge_bit(q,s);if s==q||current.edges&added!=0||!proper_cross(p,q,s,opp[0],opp[1]){continue;}let mut retained=current.edges;
                    for u in 0..n{for v in u+1..n{let bit=edge_bit(u,v);if retained&bit!=0&&proper_cross(p,q,s,u,v){retained&=!bit;}}}
                    let mut selected=None;let mut sm=Metrics::default();for ci in 0..total{if all[ci].edges&added==0||all[ci].edges&retained!=retained{continue;}let candidate=evaluate(p,n,all[ci]);if !improves(candidate,cm){continue;}if selected.is_none()||preferable(candidate,sm){selected=Some(ci);sm=candidate;}}
                    if let Some(index)=selected{current_index=index;current=all[index];cm=sm;changed=true;}
                }
            }
        }
        if !changed{break;}
    }
    rank_score(p,n,cm.maximum)
}

#[no_mangle]
pub unsafe extern "C" fn convex_polygon_minimax_eccentricity_edge_insertion(input:*const i64,length:usize)->i64 {
    if input.is_null()||length<1||length>MAX_LEN{return -1;}let count=*input;if count<MIN_N as i64||count>MAX_N as i64{return -1;}let n=count as usize;if length!=1+2*n{return -1;}
    let mut points=[Point::default();MAX_N];for i in 0..n{let x=*input.add(1+2*i);let y=*input.add(2+2*i);if !(-4..=4).contains(&x)||!(-4..=4).contains(&y){return -1;}for j in 0..i{if points[j].x==x&&points[j].y==y{return -1;}}points[i]=Point{x,y};}
    let mut area2=0_i64;for i in 0..n{let j=(i+1)%n;area2+=points[i].x*points[j].y-points[i].y*points[j].x;}if area2==0{return -1;}let direction=if area2>0{1_i64}else{-1_i64};
    for a in 0..n{for b in a+1..n{for c in b+1..n{if orient(points[a],points[b],points[c])==0{return -1;}}}}
    for edge in 0..n{let next=(edge+1)%n;for v in 0..n{if v!=edge&&v!=next&&direction*orient(points[edge],points[next],points[v])<=0{return -1;}}}
    solve(&points,n)
}
