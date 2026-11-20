const INF: i64 = 2305843009213693951;
const Point = struct { x: i64, y: i64 };

fn distanceScaled(a: Point,b: Point) i64 {
    const dx=a.x-b.x;const dy=a.y-b.y;const sq=(dx*dx+dy*dy)*1_000_000;
    var lo: i64=0;var hi: i64=3_000_000;
    while(lo<hi){const mid=lo+(hi-lo+1)/2;if(mid*mid<=sq){lo=mid;}else{hi=mid-1;}}
    const up=lo+1;return if(up*up-sq<sq-lo*lo) up else lo;
}
fn addCost(a:i64,b:i64)i64{return if(a>=INF) INF else a+b;}
fn solveSubset(outer:[]const usize,inner:[]const usize,points:[]const Point)i64{
    const k=inner.len;const states=1<<k;const sentinel=k;var previous=[_]i64{INF}**448;previous[sentinel]=0;
    for(0..states)|mask|{
        for(0..k+1)|last|{
            if(last<k and (mask&(1<<last))==0)continue;
            const prefix=previous[mask*7+last];if(prefix>=INF)continue;
            const vertex=if(last==sentinel)outer[0]else inner[last];
            for(0..k)|next|{
                const bit=1<<next;if(mask&bit!=0)continue;const next_mask=mask|bit;
                const candidate=addCost(prefix,distanceScaled(points[vertex],points[inner[next]]));
                previous[next_mask*7+next]=@min(previous[next_mask*7+next],candidate);
            }
        }
    }
    for(1..outer.len)|i|{
        var current=[_]i64{INF}**448;
        for(0..states)|mask|{
            for(0..k+1)|last|{
                if(last<k and (mask&(1<<last))==0)continue;
                const prefix=previous[mask*7+last];if(prefix>=INF)continue;
                const vertex=if(last==sentinel)outer[i-1]else inner[last];const candidate=addCost(prefix,distanceScaled(points[vertex],points[outer[i]]));
                current[mask*7+sentinel]=@min(current[mask*7+sentinel],candidate);
            }
        }
        for(0..states)|mask|{
            for(0..k+1)|last|{
                if(last<k and (mask&(1<<last))==0)continue;
                const prefix=current[mask*7+last];if(prefix>=INF)continue;
                const vertex=if(last==sentinel)outer[i]else inner[last];
                for(0..k)|next|{const bit=1<<next;if(mask&bit!=0)continue;const next_mask=mask|bit;
                    const candidate=addCost(prefix,distanceScaled(points[vertex],points[inner[next]]));current[next_mask*7+next]=@min(current[next_mask*7+next],candidate);
                }
            }
        }
        previous=current;
    }
    const full=states-1;var best:i64=INF;
    for(0..k+1)|last|{if(last<k and (full&(1<<last))==0)continue;const vertex=if(last==sentinel)outer[outer.len-1]else inner[last];best=@min(best,addCost(previous[full*7+last],distanceScaled(points[vertex],points[outer[0]])));}
    return best;
}
fn putWord(out:[*c]u8,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[i]=@truncate(b>>@intCast(8*i));}

export fn tsp_few_inner_points_subset_dp(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<2 or length>51)return -1;const n0=input[0];const k0=input[1];if(n0<3 or n0>16 or k0<0 or k0>6 or k0>n0-3 or length!=2+3*@as(usize,@intCast(n0)))return -1;
    const n:usize=@intCast(n0);const k:usize=@intCast(k0);const on=n-k;var outer_buf=[_]usize{0}**16;var inner_buf=[_]usize{0}**6;var seen=[_]bool{false}**16;
    for(0..on)|i|{const id=input[2+i];if(id<0 or id>=n0)return -1;const u:usize=@intCast(id);if(seen[u])return -1;seen[u]=true;outer_buf[i]=u;}
    for(0..k)|i|{const id=input[2+on+i];if(id<0 or id>=n0)return -1;const u:usize=@intCast(id);if(seen[u])return -1;seen[u]=true;inner_buf[i]=u;}
    for(0..n)|i|{if(!seen[i])return -1;}var points=[_]Point{.{.x=0,.y=0}}**16;const off=2+n;
    for(0..n)|i|{const x=input[off+2*i];const y=input[off+2*i+1];if(x< -1000 or x>1000 or y< -1000 or y>1000)return -1;for(0..i)|j|{if(points[j].x==x and points[j].y==y)return -1;}points[i]=.{.x=x,.y=y};}
    const outer=outer_buf[0..on];const inner=inner_buf[0..k];const best=solveSubset(outer,inner,points[0..n]);
    if(output==null or capacity<8)return -2;putWord(output,best);return 8;
}

