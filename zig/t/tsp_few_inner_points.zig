const INF: i64 = 2305843009213693951;
const Point = struct { x: i64, y: i64 };

fn distanceScaled(a: Point,b: Point) i64 {
    const dx=a.x-b.x;const dy=a.y-b.y;const sq=(dx*dx+dy*dy)*1_000_000;
    var lo: i64=0;var hi: i64=3_000_000;
    while(lo<hi){const mid=lo+(hi-lo+1)/2;if(mid*mid<=sq){lo=mid;}else{hi=mid-1;}}
    const up=lo+1;return if(up*up-sq<sq-lo*lo) up else lo;
}
fn addCost(a:i64,b:i64)i64{return if(a>=INF) INF else a+b;}
fn solveOrder(outer:[]const usize,order:[]const usize,points:[]const Point)i64{
    const k=order.len;var po=[_]i64{INF}**7;var pi=[_]i64{INF}**7;po[0]=0;
    for(1..k+1)|j|{const a=addCost(po[j-1],distanceScaled(points[outer[0]],points[order[j-1]]));const b=if(j>1)addCost(pi[j-1],distanceScaled(points[order[j-2]],points[order[j-1]]))else INF;pi[j]=@min(a,b);}
    for(1..outer.len)|i|{var co=[_]i64{INF}**7;var ci=[_]i64{INF}**7;const edge=distanceScaled(points[outer[i-1]],points[outer[i]]);co[0]=addCost(po[0],edge);
        for(1..k+1)|j|co[j]=@min(addCost(po[j],edge),addCost(pi[j],distanceScaled(points[order[j-1]],points[outer[i]])));
        for(1..k+1)|j|{const a=addCost(co[j-1],distanceScaled(points[outer[i]],points[order[j-1]]));const b=if(j>1)addCost(ci[j-1],distanceScaled(points[order[j-2]],points[order[j-1]]))else INF;ci[j]=@min(a,b);}
        po=co;pi=ci;
    }
    var best=addCost(po[k],distanceScaled(points[outer[outer.len-1]],points[outer[0]]));if(k>0)best=@min(best,addCost(pi[k],distanceScaled(points[order[k-1]],points[outer[0]])));return best;
}
fn nextPerm(a:[]usize)bool{if(a.len<2)return false;var i=a.len-2;while(true){if(a[i]<a[i+1])break;if(i==0)return false;i-=1;}var j=a.len-1;while(a[j]<=a[i]){j-=1;}const t=a[i];a[i]=a[j];a[j]=t;var l=i+1;var r=a.len-1;while(l<r){const x=a[l];a[l]=a[r];a[r]=x;l+=1;r-=1;}return true;}
fn putWord(out:[*c]u8,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[i]=@truncate(b>>@intCast(8*i));}

export fn tsp_few_inner_points(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<2 or length>51)return -1;const n0=input[0];const k0=input[1];if(n0<3 or n0>16 or k0<0 or k0>6 or k0>n0-3 or length!=2+3*@as(usize,@intCast(n0)))return -1;
    const n:usize=@intCast(n0);const k:usize=@intCast(k0);const on=n-k;var outer_buf=[_]usize{0}**16;var inner_buf=[_]usize{0}**6;var seen=[_]bool{false}**16;
    for(0..on)|i|{const id=input[2+i];if(id<0 or id>=n0)return -1;const u:usize=@intCast(id);if(seen[u])return -1;seen[u]=true;outer_buf[i]=u;}
    for(0..k)|i|{const id=input[2+on+i];if(id<0 or id>=n0)return -1;const u:usize=@intCast(id);if(seen[u])return -1;seen[u]=true;inner_buf[i]=u;}
    for(0..n)|i|{if(!seen[i])return -1;}var points=[_]Point{.{.x=0,.y=0}}**16;const off=2+n;
    for(0..n)|i|{const x=input[off+2*i];const y=input[off+2*i+1];if(x< -1000 or x>1000 or y< -1000 or y>1000)return -1;for(0..i)|j|{if(points[j].x==x and points[j].y==y)return -1;}points[i]=.{.x=x,.y=y};}
    const outer=outer_buf[0..on];const inner=inner_buf[0..k];var si:usize=1;while(si<k):(si+=1){const x=inner[si];var sj=si;while(sj>0 and inner[sj-1]>x):(sj-=1){inner[sj]=inner[sj-1];}inner[sj]=x;}
    var best=INF;while(true){best=@min(best,solveOrder(outer,inner,points[0..n]));if(!nextPerm(inner))break;}
    if(output==null or capacity<8)return -2;putWord(output,best);return 8;
}

