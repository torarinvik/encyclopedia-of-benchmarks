const max_n: usize = 12;
const max_m: usize = 24;
const max_input: usize = 98;

export fn kkt_mst_sampling_filter(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > max_input) return -1;
    const input = input_opt.?;
    const n64=input[0]; const m64=input[1];
    if (n64<2 or n64>12 or m64<1 or m64>24 or length!=2+4*@as(usize,@intCast(m64))) return -1;
    const n:usize=@intCast(n64);const m:usize=@intCast(m64);
    var eu:[max_m]usize=@splat(0);var ev:[max_m]usize=@splat(0);var ew:[max_m]i64=@splat(0);var sample:[max_m]i64=@splat(0);
    for (0..m) |i| {
        if (input[2+4*i]<0 or input[2+4*i]>=input[3+4*i] or input[3+4*i]>=n64 or input[4+4*i]<1 or input[4+4*i]>1024 or (input[5+4*i]!=0 and input[5+4*i]!=1)) return -1;
        eu[i]=@intCast(input[2+4*i]);ev[i]=@intCast(input[3+4*i]);ew[i]=input[4+4*i];sample[i]=input[5+4*i];
        for (0..i) |j| {
            if ((eu[i]==eu[j] and ev[i]==ev[j]) or ew[i]==ew[j]) return -1;
        }
    }
    if (output_opt==null or capacity<m) return -2;
    var order:[max_m]usize=@splat(0);for (0..m) |i| order[i]=i;
    for (0..m) |i| {
        var best=i;var j=i+1;
        while(j<m):(j+=1){if(ew[order[j]]<ew[order[best]])best=j;}
        const tmp=order[i];order[i]=order[best];order[best]=tmp;
    }
    var parent:[max_n]usize=@splat(0);for(0..n)|i|parent[i]=i;
    var in_forest:[max_m]bool=@splat(false);var staged:[max_m]u8=@splat(0);
    for(0..m)|pos|{
        const e=order[pos];if(sample[e]==0)continue;
        var a=eu[e];var b=ev[e];
        while(parent[a]!=a){a=parent[a];}
        while(parent[b]!=b){b=parent[b];}
        if(a!=b){parent[b]=a;in_forest[e]=true;}
    }
    for(0..m)|e|{
        if(in_forest[e]){staged[e]=1;continue;}
        var path_max:[max_n]i64=@splat(-1);var queue:[max_n]usize=@splat(0);var seen:[max_n]bool=@splat(false);
        const start=eu[e];const target=ev[e];var head:usize=0;var tail:usize=1;queue[0]=start;seen[start]=true;path_max[start]=0;
        while(head<tail and !seen[target]){
            const current=queue[head];head+=1;
            for(0..m)|k|{
                if(!in_forest[k])continue;
                var next:?usize=null;
                if(eu[k]==current){next=ev[k];}else if(ev[k]==current){next=eu[k];}
                if(next)|node|{
                    if(!seen[node]){seen[node]=true;path_max[node]=@max(path_max[current],ew[k]);queue[tail]=node;tail+=1;}
                }
            }
        }
        staged[e]=if(!seen[target] or ew[e]<path_max[target]) 1 else 0;
    }
    const output=output_opt.?;for(0..m)|i|output[i]=staged[i];return @intCast(m);
}
