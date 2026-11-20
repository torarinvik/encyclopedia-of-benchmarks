const MAX_N: usize = 4;
const MAX_LEN: usize = 14;
#[derive(Clone, Copy)] struct Point { x: i64, y: i64, z: i64 }
#[derive(Clone, Copy)] struct Triangle { a: usize, b: usize, c: usize }
#[derive(Clone, Copy)] struct Slope { num: i64, den: i64 }
fn orient(p: &[Point; MAX_N], a: usize, b: usize, c: usize) -> i64 { (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x) }
fn slope(p: &[Point; MAX_N], t: Triangle) -> Slope {
    let (a,b,c)=(p[t.a],p[t.b],p[t.c]); let (dx1,dy1,dz1)=(b.x-a.x,b.y-a.y,b.z-a.z); let (dx2,dy2,dz2)=(c.x-a.x,c.y-a.y,c.z-a.z);
    let det=dx1*dy2-dx2*dy1; let gx=dz1*dy2-dz2*dy1; let gy=dx1*dz2-dz1*dx2; Slope{num:gx*gx+gy*gy,den:det*det}
}
fn cmp(a:Slope,b:Slope)->i32 { let (x,y)=(a.num*b.den,b.num*a.den); if x>y {1} else if x<y {-1} else {0} }
fn maximum(p:&[Point;MAX_N],a:Triangle,b:Triangle)->Slope { let (x,y)=(slope(p,a),slope(p,b)); if cmp(x,y)>=0{x}else{y} }
fn anchor(p:&[Point;MAX_N],t:Triangle,q:usize)->bool {
    let (a,b,c)=(p[t.a],p[t.b],p[t.c]); let (dx1,dy1,dz1)=(b.x-a.x,b.y-a.y,b.z-a.z); let (dx2,dy2,dz2)=(c.x-a.x,c.y-a.y,c.z-a.z);
    let det=dx1*dy2-dx2*dy1; let gx=dz1*dy2-dz2*dy1; let gy=dx1*dz2-dz1*dx2; if gx==0&&gy==0{return false;}
    let mut o=[0usize;2];let mut used=0;for v in [t.a,t.b,t.c]{if v!=q{o[used]=v;used+=1;}}
    let sign=if det>0{1}else{-1};let (dx,dy)=(-gx*sign,-gy*sign);let (ux,uy)=(p[o[0]].x-p[q].x,p[o[0]].y-p[q].y);let (vx,vy)=(p[o[1]].x-p[q].x,p[o[1]].y-p[q].y);
    let turn=ux*vy-uy*vx;let side=if turn>0{1}else{-1};side*(ux*dy-uy*dx)>=0&&side*(dx*vy-dy*vx)>=0
}
fn crosses(p:&[Point;MAX_N],a:usize,b:usize,c:usize,d:usize)->bool { orient(p,a,b,c)*orient(p,a,b,d)<0&&orient(p,c,d,a)*orient(p,c,d,b)<0 }
fn volume6(p:&[Point;MAX_N])->i64 { let (ax,ay,az)=(p[1].x-p[0].x,p[1].y-p[0].y,p[1].z-p[0].z);let (bx,by,bz)=(p[2].x-p[0].x,p[2].y-p[0].y,p[2].z-p[0].z);let (cx,cy,cz)=(p[3].x-p[0].x,p[3].y-p[0].y,p[3].z-p[0].z);ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx) }
fn rank(p:&[Point;MAX_N],n:usize,target:Slope)->i64 { let mut all=[Slope{num:0,den:1};4];let mut count=0;for a in 0..n{for b in a+1..n{for c in b+1..n{all[count]=slope(p,Triangle{a,b,c});count+=1;}}}let mut distinct=0;for i in 0..count{if cmp(all[i],target)<0{let mut seen=false;for j in 0..i{if cmp(all[j],all[i])==0{seen=true;}}if !seen{distinct+=1;}}}distinct+1 }
#[no_mangle]
pub unsafe extern "C" fn convex_polygon_minimax_slope_edge_insertion(input:*const i64,length:usize)->i64 {
    if input.is_null()||length==0||length>MAX_LEN{return -1;}let raw=*input;if raw<3||raw>4{return -1;}let n=raw as usize;if length!=1+3*n{return -1;}
    let mut p=[Point{x:0,y:0,z:0};MAX_N];for i in 0..n{let q=std::slice::from_raw_parts(input.add(1+3*i),3);p[i]=Point{x:q[0],y:q[1],z:q[2]};if p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8{return -1;}}
    let mut area=0;for i in 0..n{let j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x;}if area==0{return -1;}let sign=if area>0{1}else{-1};
    for a in 0..n{for b in a+1..n{for c in b+1..n{if orient(&p,a,b,c)==0{return -1;}}}}
    for e in 0..n{let j=(e+1)%n;for k in 0..n{if k!=e&&k!=j&&sign*orient(&p,e,j,k)<=0{return -1;}}}if n==4&&volume6(&p)==0{return -1;}
    let fan=[Triangle{a:0,b:1,c:2},Triangle{a:0,b:2,c:3}];let mut worst=if n==3{slope(&p,fan[0])}else{maximum(&p,fan[0],fan[1])};
    if n==4{let mut done=false;for t in fan{if done{break;}if cmp(slope(&p,t),worst)!=0{continue;}let v=[t.a,t.b,t.c];for k in 0..3{if done{break;}let q=v[k];if !anchor(&p,t,q){continue;}let mut o=[0usize;2];let mut u=0;for j in 0..3{if j!=k{o[u]=v[j];u+=1;}}let s=(0..4).find(|x|!v.contains(x)).unwrap();if !crosses(&p,q,s,o[0],o[1]){continue;}let cand=maximum(&p,Triangle{a:q,b:s,c:o[0]},Triangle{a:q,b:s,c:o[1]});if cmp(cand,worst)<0{worst=cand;done=true;}}}}
    rank(&p,n,worst)
}
