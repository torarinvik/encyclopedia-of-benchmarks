package all_paths_from_source_to_target
import "core:c"
MAX_V :: 8; MAX_E :: 24; MAX_PATHS :: 1000; MAX_OUTPUT :: 72008

put_i64 :: proc "contextless" (out: [^]u8, at: int, value: i64) { bits:=u64(value);for b in 0..<8 {out[at+b]=u8(bits&255);bits >>= 8} }
dfs :: proc "contextless" (adj: ^[MAX_V][MAX_E]int, degree: ^[MAX_V]int, visited: ^[MAX_V]bool, path: ^[MAX_V]int, depth,target: int, count: ^int, out: [^]u8, at: ^int, overflow: ^bool) {
	if overflow^ do return
	u:=path[depth-1]
	if u==target {if count^>=MAX_PATHS {overflow^=true;return};put_i64(out,at^,i64(depth));at^+=8;for i in 0..<depth {put_i64(out,at^,i64(path[i]));at^+=8};count^+=1;return}
	visited[u]=true
	for i in 0..<degree[u] {if overflow^ do break;next:=adj[u][i];if !visited[next] {path[depth]=next;dfs(adj,degree,visited,path,depth+1,target,count,out,at,overflow)}}
	visited[u]=false
}

@(export)
all_paths_from_source_to_target :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values==nil||length<4||length>52||values[0]<1||values[0]>MAX_V||values[1]<0||values[1]>MAX_E do return -1
	nv,ne:=int(values[0]),int(values[1]);if values[2]<0||values[2]>=i64(nv)||values[3]<0||values[3]>=i64(nv)||int(length)!=4+2*ne do return -1
	adj: [MAX_V][MAX_E]int={};degree: [MAX_V]int={}
	for e in 0..<ne {a,b:=values[4+2*e],values[5+2*e];if a<0||a>=i64(nv)||b<0||b>=i64(nv) do return -1;adj[int(a)][degree[int(a)]]=int(b);degree[int(a)]+=1}
	out: [MAX_OUTPUT]u8={};path: [MAX_V]int={};visited: [MAX_V]bool={};count,at:=0,8;overflow:=false;path[0]=int(values[2])
	dfs(&adj,&degree,&visited,&path,1,int(values[3]),&count,&out,&at,&overflow);if overflow do return -2;put_i64(&out,0,i64(count));if output==nil||int(capacity)<at do return -2;for i in 0..<at {output[i]=out[i]};return i64(at)
}
