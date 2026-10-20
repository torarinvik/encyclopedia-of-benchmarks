use std::ffi::c_void;

const N: usize = 8;
const MAX_ARCS: usize = 15;
const MAX_VERTICES: usize = 32;
const MAX_OUTPUT: usize = 1024;
const EPS: f64 = 1.0e-10;

#[derive(Clone, Copy, Default)] struct Point { x: f64, y: f64 }
#[derive(Clone, Copy, Default)] struct Arc { site: usize, prev: isize, next: isize, active: bool }
#[derive(Clone, Copy, Default)] struct Circle { y: f64, x: f64, arc: usize, left: usize, right: usize }
#[derive(Clone, Copy, Default)] struct Rat { n: i64, d: i64 }
#[derive(Clone, Copy, Default)] struct RPoint { x: Rat, y: Rat }

fn rat(n0: i64, d0: i64) -> Rat {
    let (mut n, mut d) = (n0, d0);
    if d < 0 { n = -n; d = -d; }
    let (mut a, mut b) = (n.abs(), d.abs());
    while b != 0 { let t = a % b; a = b; b = t; }
    let g = if a == 0 { 1 } else { a };
    Rat { n: n / g, d: d / g }
}
fn add(a: Rat, b: Rat) -> Rat { rat(a.n*b.d+b.n*a.d,a.d*b.d) }
fn sub(a: Rat, b: Rat) -> Rat { rat(a.n*b.d-b.n*a.d,a.d*b.d) }
fn mul(a: Rat, b: Rat) -> Rat { rat(a.n*b.n,a.d*b.d) }
fn divr(a: Rat, b: Rat) -> Rat { rat(a.n*b.d,a.d*b.n) }
fn cmp(a: Rat, b: Rat) -> i32 { let (l,r)=(a.n*b.d,b.n*a.d); if l<r{-1}else if l>r{1}else{0} }
fn peq(a:RPoint,b:RPoint)->bool{cmp(a.x,b.x)==0&&cmp(a.y,b.y)==0}
fn pless(a:RPoint,b:RPoint)->bool{cmp(a.x,b.x)<0||(cmp(a.x,b.x)==0&&cmp(a.y,b.y)<0)}
fn orient(a:Point,b:Point,c:Point)->i32{let v=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);if v>0.0{1}else if v<0.0{-1}else{0}}
fn breakpoint(p:Point,q:Point,line_y:f64)->f64{
    if (p.y-q.y).abs()<EPS{return(p.x+q.x)*0.5}
    let dp=p.y-line_y;let dq=q.y-line_y;let a=q.y-p.y;
    let b= -2.0*p.x*dq+2.0*q.x*dp;
    let c=(p.x*p.x+p.y*p.y-line_y*line_y)*dq-(q.x*q.x+q.y*q.y-line_y*line_y)*dp;
    let mut disc=b*b-4.0*a*c;if disc<0.0&&disc> -EPS{disc=0.0}
    let root=disc.sqrt();let r1=(-b-root)/(2.0*a);let r2=(-b+root)/(2.0*a);
    if p.y<q.y{r1.max(r2)}else{r1.min(r2)}
}
fn circle(a:Point,b:Point,c:Point,sweep:f64,arc:usize,left:usize,right:usize)->Option<Circle>{
    if orient(a,b,c)>=0{return None}
    let aa=a.x*a.x+a.y*a.y;let bb=b.x*b.x+b.y*b.y;let cc=c.x*c.x+c.y*c.y;
    let d=2.0*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));if d.abs()<EPS{return None}
    let x=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d;
    let y=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d;
    let dx=x-a.x;let dy=y-a.y;let bottom=y-(dx*dx+dy*dy).sqrt();
    if !(bottom<sweep-EPS){return None}
    Some(Circle{y:bottom,x,arc,left,right})
}
fn distance(p:RPoint,a:i64,b:i64,c:i64)->Rat{sub(add(mul(rat(a,1),p.x),mul(rat(b,1),p.y)),rat(c,1))}
fn intersection(p:RPoint,q:RPoint,dp:Rat,dq:Rat)->RPoint{let t=divr(dp,sub(dp,dq));RPoint{x:add(p.x,mul(t,sub(q.x,p.x))),y:add(p.y,mul(t,sub(q.y,p.y)))}}
fn push(poly:&mut [RPoint;MAX_VERTICES],n:&mut usize,p:RPoint){if *n==0||!peq(poly[*n-1],p){poly[*n]=p;*n+=1}}
fn clip(poly:&mut [RPoint;MAX_VERTICES],count:usize,a:i64,b:i64,c:i64)->usize{
    let mut next=[RPoint::default();MAX_VERTICES];let mut n=0;
    for i in 0..count{let p=poly[i];let q=poly[(i+1)%count];let dp=distance(p,a,b,c);let dq=distance(q,a,b,c);let pin=dp.n<=0;let qin=dq.n<=0;
        if pin&&qin{push(&mut next,&mut n,q)}else if pin&&!qin{push(&mut next,&mut n,intersection(p,q,dp,dq))}else if !pin&&qin{push(&mut next,&mut n,intersection(p,q,dp,dq));push(&mut next,&mut n,q)}
    }
    if n>1&&peq(next[0],next[n-1]){n-=1}poly[..n].copy_from_slice(&next[..n]);n
}
unsafe fn valid(input:*const i64,n:usize)->bool{
    for i in 0..n{for j in i+1..n{if *input.add(1+2*i)==*input.add(1+2*j)&&*input.add(2+2*i)==*input.add(2+2*j){return false}if *input.add(2+2*i)==*input.add(2+2*j){return false}}}
    for i in 0..n{for j in i+1..n{for k in j+1..n{let ax=*input.add(1+2*i);let ay=*input.add(2+2*i);let bx=*input.add(1+2*j);let by=*input.add(2+2*j);let cx=*input.add(1+2*k);let cy=*input.add(2+2*k);if (bx-ax)*(cy-ay)==(by-ay)*(cx-ax){return false}}}}
    for i in 0..n{for j in i+1..n{for k in j+1..n{for l in k+1..n{let ax=*input.add(1+2*i)-*input.add(1+2*l);let ay=*input.add(2+2*i)-*input.add(2+2*l);let bx=*input.add(1+2*j)-*input.add(1+2*l);let by=*input.add(2+2*j)-*input.add(2+2*l);let cx=*input.add(1+2*k)-*input.add(1+2*l);let cy=*input.add(2+2*k)-*input.add(2+2*l);let aa=ax*ax+ay*ay;let bb=bx*bx+by*by;let cc=cx*cx+cy*cy;let d=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx);if d==0{return false}}}}}
    true
}
unsafe fn put(out:*mut u8,slot:usize,v:i64){let b=v as u64;for i in 0..8{*out.add(slot*8+i)=(b>>(8*i))as u8}}

#[no_mangle]
pub unsafe extern "C" fn fortune_voronoi(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<3{return -1}let n0=*input;if n0<1||n0>N as i64||length!=1+2*n0 as usize{return -1}let n=n0 as usize;
    for i in 0..n{let x=*input.add(1+2*i);let y=*input.add(2+2*i);if !(-8..=8).contains(&x)||!(-8..=8).contains(&y){return -1}}
    if !valid(input,n){return -1}
    let mut sites=[Point::default();N];let mut order=[0usize;N];for i in 0..n{sites[i]=Point{x:*input.add(1+2*i)as f64,y:*input.add(2+2*i)as f64};order[i]=i}
    for i in 1..n{let v=order[i];let mut j=i;while j>0&&sites[order[j-1]].y<sites[v].y{order[j]=order[j-1];j-=1}order[j]=v}
    let mut arcs=[Arc::default();MAX_ARCS];let mut arc_count=1usize;let mut first=0isize;arcs[0]=Arc{site:order[0],prev:-1,next:-1,active:true};let mut next_site=1usize;let mut sweep=sites[order[0]].y;let mut adjacent=[[false;N];N];
    while next_site<n||first>=0{
        let mut best=Circle::default();let mut has=false;let mut b=first;
        while b>=0{let bi=b as usize;let l=arcs[bi].prev;let r=arcs[bi].next;if l>=0&&r>=0{let li=l as usize;let ri=r as usize;let si=arcs[li].site;let sj=arcs[bi].site;let sk=arcs[ri].site;if si!=sj&&sj!=sk&&si!=sk{if let Some(cand)=circle(sites[si],sites[sj],sites[sk],sweep,bi,li,ri){if !has||cand.y>best.y+EPS||((cand.y-best.y).abs()<=EPS&&bi<best.arc){best=cand;has=true}}}}b=arcs[bi].next}
        let do_site=next_site<n&&(!has||sites[order[next_site]].y>best.y+EPS);if !do_site&&!has{break}
        if do_site{let site=order[next_site];next_site+=1;sweep=sites[site].y;let mut arc=first as usize;while arcs[arc].next>=0{let right=arcs[arc].next as usize;if sites[site].x<breakpoint(sites[arcs[arc].site],sites[arcs[right].site],sweep){break}arc=right}let old_next=arcs[arc].next;let old_site=arcs[arc].site;if arc_count+2>MAX_ARCS{return -1}let middle=arc_count;arc_count+=1;arcs[middle]=Arc{site,prev:arc as isize,next:-1,active:true};let right=arc_count;arc_count+=1;arcs[right]=Arc{site:old_site,prev:middle as isize,next:old_next,active:true};arcs[arc].next=middle as isize;arcs[middle].next=right as isize;if old_next>=0{arcs[old_next as usize].prev=right as isize}adjacent[old_site][site]=true;adjacent[site][old_site]=true
        }else{let arc=best.arc;let left=best.left;let right=best.right;if !arcs[arc].active||arcs[arc].prev!=left as isize||arcs[arc].next!=right as isize{return -1}sweep=best.y;let ls=arcs[left].site;let rs=arcs[right].site;adjacent[ls][rs]=true;adjacent[rs][ls]=true;arcs[left].next=right as isize;arcs[right].prev=left as isize;arcs[arc].active=false}
    }
    let mut values=[0i64;MAX_OUTPUT];let mut used=0usize;values[used]=n as i64;used+=1;
    for i in 0..n{let mut poly=[RPoint::default();MAX_VERTICES];poly[0]=RPoint{x:Rat{n:-16,d:1},y:Rat{n:-16,d:1}};poly[1]=RPoint{x:Rat{n:16,d:1},y:Rat{n:-16,d:1}};poly[2]=RPoint{x:Rat{n:16,d:1},y:Rat{n:16,d:1}};poly[3]=RPoint{x:Rat{n:-16,d:1},y:Rat{n:16,d:1}};let mut count=4;for j in 0..n{if adjacent[i][j]{let x=*input.add(1+2*j);let y=*input.add(2+2*j);let sx=*input.add(1+2*i);let sy=*input.add(2+2*i);count=clip(&mut poly,count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy)}}if count<3||used+2+4*count>MAX_OUTPUT{return -1}let mut start=0;for j in 1..count{if pless(poly[j],poly[start]){start=j}}values[used]=i as i64;used+=1;values[used]=count as i64;used+=1;for j in 0..count{let p=poly[(start+j)%count];values[used]=p.x.n;used+=1;values[used]=p.x.d;used+=1;values[used]=p.y.n;used+=1;values[used]=p.y.d;used+=1}}
    let bytes=used*8;if output.is_null()||capacity<bytes{return -2}for i in 0..used{put(output,i,values[i])}bytes as i64
}
