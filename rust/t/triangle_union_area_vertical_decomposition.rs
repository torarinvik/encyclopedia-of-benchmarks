const MAX_TRIANGLES: usize = 3;
const MAX_SEGMENTS: usize = 9;
const MAX_EVENTS: usize = 45;
#[derive(Clone, Copy, Default)] struct Rat { n: i64, d: i64 }
#[derive(Clone, Copy, Default)] struct Seg { x0:i64,y0:i64,x1:i64,y1:i64,id:i32 }
#[derive(Clone, Copy, Default)] struct Interval { lo:Rat,hi:Rat,low:Seg,high:Seg,li:i32,hiid:i32 }
fn gcd(mut a:i64,mut b:i64)->i64{a=a.abs();b=b.abs();while b!=0{let t=a%b;a=b;b=t;}if a==0{1}else{a}}
fn r(mut n:i64,mut d:i64)->Rat{if d<0{n=-n;d=-d;}let g=gcd(n,d);Rat{n:n/g,d:d/g}}
fn add(a:Rat,b:Rat)->Rat{r(a.n*b.d+b.n*a.d,a.d*b.d)}
fn sub(a:Rat,b:Rat)->Rat{r(a.n*b.d-b.n*a.d,a.d*b.d)}
fn mul(a:Rat,b:Rat)->Rat{r(a.n*b.n,a.d*b.d)}
fn divv(a:Rat,b:Rat)->Rat{r(a.n*b.d,a.d*b.n)}
fn cmp(a:Rat,b:Rat)->i32{let x=a.n*b.d;let y=b.n*a.d;if x<y{-1}else if x>y{1}else{0}}
fn cross(ax:i64,ay:i64,bx:i64,by:i64)->i64{ax*by-ay*bx}
fn orient(a:(i64,i64),b:(i64,i64),c:(i64,i64))->i64{cross(b.0-a.0,b.1-a.1,c.0-a.0,c.1-a.1)}
fn y_at(s:Seg,x:Rat)->Rat{add(r(s.y0,1),mul(r(s.y1-s.y0,s.x1-s.x0),sub(x,r(s.x0,1))))}
fn intersection(a:Seg,b:Seg)->Option<Rat>{let rx=a.x1-a.x0;let ry=a.y1-a.y0;let sx=b.x1-b.x0;let sy=b.y1-b.y0;let den=cross(rx,ry,sx,sy);if den==0{return None;}let qx=b.x0-a.x0;let qy=b.y0-a.y0;let t=r(cross(qx,qy,sx,sy),den);let u=r(cross(qx,qy,rx,ry),den);if cmp(t,r(0,1))<0||cmp(t,r(1,1))>0||cmp(u,r(0,1))<0||cmp(u,r(1,1))>0{return None;}Some(add(r(a.x0,1),mul(t,r(rx,1))))}
fn push_event(events:&mut [Rat;MAX_EVENTS],n:&mut usize,x:Rat){if events[..*n].iter().any(|e|cmp(*e,x)==0){return;}events[*n]=x;*n+=1;}
fn integrate(area:&mut Rat,lo:Seg,hi:Seg,xl:Rat,xr:Rat){let h0=sub(y_at(hi,xl),y_at(lo,xl));let h1=sub(y_at(hi,xr),y_at(lo,xr));*area=add(*area,mul(sub(xr,xl),divv(add(h0,h1),r(2,1))));}
fn less_interval(a:Interval,b:Interval)->bool{let c=cmp(a.lo,b.lo);if c!=0{return c<0;}if a.li!=b.li{return a.li<b.li;}let c=cmp(a.hi,b.hi);if c!=0{return c<0;}a.hiid<b.hiid}

#[no_mangle]
pub unsafe extern "C" fn triangle_union_area_vertical_decomposition(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1||length>20{return -1;}let v=std::slice::from_raw_parts(input,length);let nv=v[0];if !(1..=3).contains(&nv)||length!=1+6*nv as usize{return -1;}let n=nv as usize;
    let mut tri=[[(0i64,0i64);3];MAX_TRIANGLES];for t in 0..n{for j in 0..3{let x=v[1+6*t+2*j];let y=v[2+6*t+2*j];if !(-1..=1).contains(&x)||!(-1..=1).contains(&y){return -1;}tri[t][j]=(x,y);}}
    for t in 0..n{if tri[t][0]==tri[t][1]||tri[t][0]==tri[t][2]||tri[t][1]==tri[t][2]||orient(tri[t][0],tri[t][1],tri[t][2])==0{return -1;}}
    let mut seg=[Seg::default();MAX_SEGMENTS];let mut ns=0;let mut events=[r(0,1);MAX_EVENTS];let mut ne=0;
    for t in 0..n{for j in 0..3{let a=tri[t][j];let b=tri[t][(j+1)%3];seg[ns]=Seg{x0:a.0,y0:a.1,x1:b.0,y1:b.1,id:(3*t+j) as i32};push_event(&mut events,&mut ne,r(a.0,1));ns+=1;}}
    for i in 0..ns{for j in i+1..ns{if let Some(x)=intersection(seg[i],seg[j]){push_event(&mut events,&mut ne,x);}}}
    events[..ne].sort_by(|a,b|cmp(*a,*b));let mut area=r(0,1);
    for ei in 0..ne.saturating_sub(1){let xl=events[ei];let xr=events[ei+1];if cmp(xl,xr)>=0{continue;}let xm=divv(add(xl,xr),r(2,1));let mut iv=[Interval::default();MAX_TRIANGLES];let mut ni=0;
        for t in 0..n{let mut cross_seg=[Seg::default();3];let mut ys=[r(0,1);3];let mut count=0;for j in 0..3{let s=seg[3*t+j];if s.x0!=s.x1&&cmp(xm,r(s.x0.min(s.x1),1))>0&&cmp(xm,r(s.x0.max(s.x1),1))<0{cross_seg[count]=s;ys[count]=y_at(s,xm);count+=1;}}if count==0{continue;}if count!=2{return -1;}let swap=cmp(ys[0],ys[1])>0||(cmp(ys[0],ys[1])==0&&cross_seg[0].id>cross_seg[1].id);iv[ni]=if swap{Interval{lo:ys[1],hi:ys[0],low:cross_seg[1],high:cross_seg[0],li:cross_seg[1].id,hiid:cross_seg[0].id}}else{Interval{lo:ys[0],hi:ys[1],low:cross_seg[0],high:cross_seg[1],li:cross_seg[0].id,hiid:cross_seg[1].id}};ni+=1;}
        iv[..ni].sort_by(|a,b|if less_interval(*a,*b){std::cmp::Ordering::Less}else if less_interval(*b,*a){std::cmp::Ordering::Greater}else{std::cmp::Ordering::Equal});let mut have=false;let mut low=Seg::default();let mut high=Seg::default();let mut top=r(0,1);let mut hid=0;
        for item in iv.iter().take(ni){if !have{low=item.low;high=item.high;top=item.hi;hid=item.hiid;have=true;continue;}if cmp(item.lo,top)<=0{let c=cmp(item.hi,top);if c>0||(c==0&&item.hiid<hid){high=item.high;top=item.hi;hid=item.hiid;}}else{integrate(&mut area,low,high,xl,xr);low=item.low;high=item.high;top=item.hi;hid=item.hiid;}}
        if have{integrate(&mut area,low,high,xl,xr);}
    }
    if area.n<0||area.d<=0||area.n>11289600||area.d>2822400{return -1;}if output.is_null()||capacity<16{return -2;}for j in 0..8{*output.add(j)=(area.n as u64>>(8*j)) as u8;*output.add(8+j)=(area.d as u64>>(8*j)) as u8;}16
}
