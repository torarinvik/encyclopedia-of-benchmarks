fn mix(hash: *u64, value: i64) void { var z: u64 = @bitCast(value); for (0..8) |_| { hash.* = (hash.* ^ (z & 255)) *% 1099511628211; z >>= 8; } }
export fn graph_enumeration(a: ?[*]const i64, length: usize) callconv(.c) i64 {
    if (a == null or length < 1) return -1;
    const x=a.?;const n0=x[0];if(n0<0 or n0>16 or length<1+@as(usize,@intCast(n0)))return -1;const n:usize=@intCast(n0);
    var labels:[16]i64=@splat(0);var sorted:[16]i64=@splat(0);var adj:[16][32]i64=@splat(@splat(0));var degree:[16]usize=@splat(0);
    for(0..n)|i|{labels[i]=x[1+i];if(labels[i]<-1000000 or labels[i]>1000000)return -1;for(0..i)|j|{if(labels[i]==labels[j])return -1;}sorted[i]=labels[i];}
    for(0..n)|i|{for(i+1..n)|j|{if(sorted[j]<sorted[i]){const t=sorted[i];sorted[i]=sorted[j];sorted[j]=t;}}}
    var off:usize=1+n;for(0..n)|i|{if(off>=length)return -1;const d=x[off];off+=1;if(d<0 or d>32 or off+@as(usize,@intCast(d))>length)return -1;degree[i]=@intCast(d);for(0..degree[i])|j|{const v=x[off];off+=1;var found=false;for(0..n)|k|{if(labels[k]==v)found=true;}if(!found)return -1;adj[i][j]=v;}}
    if(off!=length)return -1;var h:u64=14695981039346656037;mix(&h,@intCast(n+1));mix(&h,0);
    for(0..n)|s|{var i:usize=0;while(labels[i]!=sorted[s]){i+=1;}mix(&h,@intCast(degree[i]));for(0..degree[i])|j|{var k:usize=0;while(sorted[k]!=adj[i][j]){k+=1;}mix(&h,@intCast(k+1));}}
    return @bitCast(h);
}
