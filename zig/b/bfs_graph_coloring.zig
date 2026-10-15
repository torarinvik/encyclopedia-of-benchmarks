const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 2016;
const MAX_OUTPUT_VALUES: usize = MAX_VERTICES + 2;
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @as(u6, @intCast(8*b)));
}
pub export fn bfs_graph_coloring(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const nv=input[0];const mv=input[1];
    if(nv<0 or nv>64 or mv<0 or mv>2016 or length!=2+2*@as(usize,@intCast(mv)))return -1;
    const n:usize=@intCast(nv);const m:usize=@intCast(mv);
    var adjacency=[_]bool{false}**(MAX_VERTICES*MAX_VERTICES);var degree=[_]usize{0}**MAX_VERTICES;
    for(0..m)|e|{const uv=input[2+2*e];const vv=input[3+2*e];if(uv<0 or uv>=nv or vv<0 or vv>=nv or uv==vv)return -1;const u:usize=@intCast(uv);const v:usize=@intCast(vv);const a=u*MAX_VERTICES+v;const b=v*MAX_VERTICES+u;if(adjacency[a])return -1;adjacency[a]=true;adjacency[b]=true;degree[u]+=1;degree[v]+=1;}
    var visited=[_]bool{false}**MAX_VERTICES;var queue=[_]usize{0}**MAX_VERTICES;
    for(0..n)|start|{if(visited[start])continue;var head:usize=0;var tail:usize=0;var high:usize=0;visited[start]=true;queue[tail]=start;tail+=1;while(head<tail){const vertex=queue[head];head+=1;if(degree[vertex]>1)high+=1;for(0..n)|nb|{if(adjacency[vertex*MAX_VERTICES+nb] and !visited[nb]){visited[nb]=true;queue[tail]=nb;tail+=1;}}}if(high>1)return -1;}
    var colors=[_]i64{0}**MAX_VERTICES;for(0..n)|i|colors[i]=1;visited=[_]bool{false}**MAX_VERTICES;
    for(0..n)|start|{if(visited[start])continue;var head:usize=0;var tail:usize=0;visited[start]=true;queue[tail]=start;tail+=1;while(head<tail){const front=queue[head];head+=1;for(0..n)|nb|{if(!adjacency[front*MAX_VERTICES+nb])continue;if(colors[nb]==colors[front])colors[nb]+=1;if(!visited[nb]){visited[nb]=true;queue[tail]=nb;tail+=1;}}}}
    var colors_used:i64=0;for(0..n)|i|if(colors[i]>colors_used){colors_used=colors[i];};var packed=[_]i64{0}**MAX_OUTPUT_VALUES;packed[0]=nv;for(0..n)|i|packed[i+1]=colors[i];packed[n+1]=colors_used;const used=n+2;const required=used*8;if(output==null or capacity<required)return -2;for(0..used)|i|putI64(output,8*i,packed[i]);return @intCast(required);
}
