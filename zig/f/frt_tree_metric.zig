fn within(d: i64, beta: i64, level: i32) bool {
    if (level >= 0) return d * 1024 <= beta * (@as(i64, 1) << @intCast(level));
    return d * 1024 * (@as(i64, 1) << @intCast(-level)) <= beta;
}
fn put_i64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn frt_tree_metric(input: [*c]const i64, length: usize,
                          output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 8 or length > 74) return -1;
    const n0=input[0];const beta=input[1];
    if(n0<2 or n0>8 or beta<1024 or beta>2047)return -1;
    const n:usize=@intCast(n0);
    if(length!=2+n+n*n)return -1;
    var perm=[_]usize{0}**8;var seen=[_]bool{false}**8;
    for(0..n)|i|{const p=input[2+i];if(p<0 or p>=n0)return -1;const q:usize=@intCast(p);if(seen[q])return -1;seen[q]=true;perm[i]=q;}
    var d=[_] [8]i64{[_]i64{0}**8}**8;var maxd:i64=0;const base=2+n;
    for(0..n)|i|{for(0..n)|j|{const x=input[base+i*n+j];if(x<0 or x>255 or (i==j and x!=0) or (i!=j and x==0))return -1;d[i][j]=x;if(x>maxd)maxd=x;}}
    for(0..n)|i|{for(0..n)|j|{if(d[i][j]!=d[j][i])return -1;for(0..n)|k|{if(d[i][j]>d[i][k]+d[k][j])return -1;}}}
    var high:i32=0;while((@as(i64,1)<<@intCast(high))<maxd):(high+=1){}
    var staged=[_]i64{0}**64;var clusters=[_]u16{0}**256;var next=[_]u16{0}**256;var count:usize=1;clusters[0]=(@as(u16,1)<<@intCast(n))-1;
    var level=high;while(level>=-10):(level-=1){var next_count:usize=0;const td:i64=@as(i64,1)<<@intCast(level+13);
        for(0..count)|ci|{var remaining=clusters[ci];var done:u16=0;
            while(remaining!=0){var center=n;for(0..n)|p|{if((remaining&(@as(u16,1)<<@intCast(perm[p])))!=0){center=perm[p];break;}}if(center==n)return -1;
                var child:u16=0;for(0..n)|v|{if((remaining&(@as(u16,1)<<@intCast(v)))!=0 and within(d[center][v],beta,level)){child|=@as(u16,1)<<@intCast(v);}}if(child==0)child=@as(u16,1)<<@intCast(center);
                for(0..n)|u|{if((done&(@as(u16,1)<<@intCast(u)))!=0){for(0..n)|v|{if((child&(@as(u16,1)<<@intCast(v)))!=0){staged[u*n+v]=td;staged[v*n+u]=td;}}}}
                done|=child;remaining&=~child;next[next_count]=child;next_count+=1;
            }
        }for(0..next_count)|i|{clusters[i]=next[i];}count=next_count;
    }
    const bytes=8*n*n;if(output==null or capacity<bytes)return -2;for(0..n*n)|i|put_i64(output,8*i,staged[i]);return @intCast(bytes);
}
