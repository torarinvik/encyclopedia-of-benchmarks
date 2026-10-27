const max_n: usize=16;
const max_m: usize=24;
const max_input: usize=74;

fn put32(out:[*]u8,pos:usize,value:i32) void {
    const bits:u32=@bitCast(value);
    for(0..4)|j|out[pos+j]=@truncate(bits>>@intCast(8*j));
}

export fn randomized_contraction_edge_sampling(input_opt:?[*]const i64,length:usize,
    output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null||length<5||length>max_input)return -1;
    const input=input_opt.?;const n64=input[0];const m64=input[1];
    if(n64<2 or n64>16 or m64<n64-1 or m64>24 or length!=2+3*@as(usize,@intCast(m64)))return -1;
    const n:usize=@intCast(n64);const m:usize=@intCast(m64);
    var eu:[max_m]usize=@splat(0);var ev:[max_m]usize=@splat(0);var bits:[max_m]i64=@splat(0);
    for(0..m)|i|{
        if(input[2+3*i]<0 or input[2+3*i]>=input[3+3*i] or input[3+3*i]>=n64 or (input[4+3*i]!=0 and input[4+3*i]!=1))return -1;
        eu[i]=@intCast(input[2+3*i]);ev[i]=@intCast(input[3+3*i]);bits[i]=input[4+3*i];
        for(0..i)|j|{if(eu[i]==eu[j] and ev[i]==ev[j])return -1;}
    }
    var seen:[max_n]bool=@splat(false);var queue:[max_n]usize=@splat(0);var head:usize=0;var tail:usize=1;queue[0]=0;seen[0]=true;
    while(head<tail){const current=queue[head];head+=1;for(0..m)|e|{var next:?usize=null;if(eu[e]==current){next=ev[e];}else if(ev[e]==current){next=eu[e];}if(next)|node|{if(!seen[node]){seen[node]=true;queue[tail]=node;tail+=1;}}}}
    if(tail!=n)return -1;
    var parent:[max_n]usize=@splat(0);for(0..n)|i|parent[i]=i;
    for(0..m)|e|{if(bits[e]!=0){var a=eu[e];var b=ev[e];while(parent[a]!=a){a=parent[a];}while(parent[b]!=b){b=parent[b];}if(a!=b){parent[b]=a;}}}
    var minimum:[max_n]usize=@splat(0);for(0..n)|i|minimum[i]=n;
    for(0..n)|vertex|{var root=vertex;while(parent[root]!=root){root=parent[root];}minimum[root]=@min(minimum[root],vertex);}
    const bytes=4*n;if(output_opt==null or capacity<bytes)return -2;
    var staged:[4*max_n]u8=@splat(0);
    for(0..n)|vertex|{var root=vertex;while(parent[root]!=root){root=parent[root];}put32(&staged,4*vertex,@intCast(minimum[root]));}
    const output=output_opt.?;for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
