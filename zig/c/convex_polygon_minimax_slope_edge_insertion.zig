const MAX_N: usize = 4;
const MAX_LEN: usize = 14;
const Point = struct { x: i64, y: i64, z: i64 };
const Triangle = struct { a: usize, b: usize, c: usize };
const Slope = struct { num: i64, den: i64 };
fn orient(p: [MAX_N]Point, a: usize, b: usize, c: usize) i64 { return (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x); }
fn slope(p: [MAX_N]Point, t: Triangle) Slope {
    const a=p[t.a];const b=p[t.b];const c=p[t.c];const dx1=b.x-a.x;const dy1=b.y-a.y;const dz1=b.z-a.z;const dx2=c.x-a.x;const dy2=c.y-a.y;const dz2=c.z-a.z;
    const det=dx1*dy2-dx2*dy1;const gx=dz1*dy2-dz2*dy1;const gy=dx1*dz2-dz1*dx2;return .{.num=gx*gx+gy*gy,.den=det*det};
}
fn cmp(a: Slope,b: Slope) i32 { const x=a.num*b.den;const y=b.num*a.den;return if(x>y) 1 else if(x<y) -1 else 0; }
fn maximum(p:[MAX_N]Point,a:Triangle,b:Triangle) Slope { const x=slope(p,a);const y=slope(p,b);return if(cmp(x,y)>=0)x else y; }
fn anchor(p:[MAX_N]Point,t:Triangle,q:usize) bool {
    const a=p[t.a];const b=p[t.b];const c=p[t.c];const dx1=b.x-a.x;const dy1=b.y-a.y;const dz1=b.z-a.z;const dx2=c.x-a.x;const dy2=c.y-a.y;const dz2=c.z-a.z;
    const det=dx1*dy2-dx2*dy1;const gx=dz1*dy2-dz2*dy1;const gy=dx1*dz2-dz1*dx2;if(gx==0 and gy==0)return false;
    var o:[2]usize=.{0,0};var used:usize=0;for([_]usize{t.a,t.b,t.c})|v|{if(v!=q){o[used]=v;used+=1;}}
    const sign:i64=if(det>0)1 else -1;const dx=-gx*sign;const dy=-gy*sign;const ux=p[o[0]].x-p[q].x;const uy=p[o[0]].y-p[q].y;const vx=p[o[1]].x-p[q].x;const vy=p[o[1]].y-p[q].y;
    const turn=ux*vy-uy*vx;const side:i64=if(turn>0)1 else -1;return side*(ux*dy-uy*dx)>=0 and side*(dx*vy-dy*vx)>=0;
}
fn crosses(p:[MAX_N]Point,a:usize,b:usize,c:usize,d:usize) bool { return orient(p,a,b,c)*orient(p,a,b,d)<0 and orient(p,c,d,a)*orient(p,c,d,b)<0; }
fn volume6(p:[MAX_N]Point) i64 { const ax=p[1].x-p[0].x;const ay=p[1].y-p[0].y;const az=p[1].z-p[0].z;const bx=p[2].x-p[0].x;const by=p[2].y-p[0].y;const bz=p[2].z-p[0].z;const cx=p[3].x-p[0].x;const cy=p[3].y-p[0].y;const cz=p[3].z-p[0].z;return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx); }
fn rank(p:[MAX_N]Point,n:usize,target:Slope) i64 { var all:[4]Slope=undefined;var count:usize=0;for(0..n)|a|{for(a+1..n)|b|{for(b+1..n)|c|{all[count]=slope(p,.{.a=a,.b=b,.c=c});count+=1;}}}var distinct:i64=0;for(0..count)|i|{if(cmp(all[i],target)<0){var seen=false;for(0..i)|j|{if(cmp(all[j],all[i])==0)seen=true;}if(!seen)distinct+=1;}}return distinct+1; }
export fn convex_polygon_minimax_slope_edge_insertion(input_opt:?[*]const i64,length:usize) i64 {
    const input=input_opt orelse return -1;if(length==0 or length>MAX_LEN)return -1;const raw=input[0];if(raw<3 or raw>4)return -1;const n:usize=@intCast(raw);if(length!=1+3*n)return -1;
    var p:[MAX_N]Point=undefined;for(0..n)|i|{p[i]=.{.x=input[1+3*i],.y=input[2+3*i],.z=input[3+3*i]};if(p[i].x < -8 or p[i].x>8 or p[i].y < -8 or p[i].y>8 or p[i].z < -8 or p[i].z>8)return -1;}
    var area:i64=0;for(0..n)|i|{const j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area==0)return -1;const sign:i64=if(area>0)1 else -1;
    for(0..n)|a|{for(a+1..n)|b|{for(b+1..n)|c|{if(orient(p,a,b,c)==0)return -1;}}}
    for(0..n)|e|{const j=(e+1)%n;for(0..n)|k|{if(k!=e and k!=j and sign*orient(p,e,j,k)<=0)return -1;}}if(n==4 and volume6(p)==0)return -1;
    const fan=[_]Triangle{.{.a=0,.b=1,.c=2},.{.a=0,.b=2,.c=3}};var worst=if(n==3)slope(p,fan[0]) else maximum(p,fan[0],fan[1]);
    if(n==4){var done=false;for(fan)|t|{if(done)break;if(cmp(slope(p,t),worst)!=0)continue;const v=[_]usize{t.a,t.b,t.c};for(0..3)|k|{if(done)break;const q=v[k];if(!anchor(p,t,q))continue;var o:[2]usize=.{0,0};var u:usize=0;var s:usize=4;for(0..3)|j|{if(j!=k){o[u]=v[j];u+=1;}}for(0..4)|j|{if(j!=v[0] and j!=v[1] and j!=v[2])s=j;}if(!crosses(p,q,s,o[0],o[1]))continue;const candidate=maximum(p,.{.a=q,.b=s,.c=o[0]},.{.a=q,.b=s,.c=o[1]});if(cmp(candidate,worst)<0){worst=candidate;done=true;}}}}
    return rank(p,n,worst);
}
