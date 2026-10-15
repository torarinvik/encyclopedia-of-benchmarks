package dinic_maxflow
import "core:c"
MAX_N :: 16
MAX_M :: 64

dfs :: proc(u, sink: int, pushed: i64, residual: ^[MAX_N*MAX_N]i64, level: ^[MAX_N]int, next: ^[MAX_N]int, n: int) -> i64 {
	if u==sink do return pushed
	for next[u]<n {
		v:=next[u];k:=u*MAX_N+v
		if level[v]==level[u]+1&&residual[k]>0 {sent:=dfs(v,sink,min(pushed,residual[k]),residual,level,next,n);if sent>0 {residual[k]-=sent;residual[v*MAX_N+u]+=sent;return sent}}
		next[u]+=1
	}
	return 0
}

// Return the maximum flow for a bounded directed graph edge list.
@(export)
dinic_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input==nil||length<4 do return -1
	nv:=input[0];mv:=input[1];sv:=input[2];tv:=input[3]
	if nv<2||nv>MAX_N||mv<0||mv>MAX_M||sv<1||sv>nv||tv<1||tv>nv||sv==tv do return -1
	n:=int(nv);m:=int(mv);s:=int(sv-1);t:=int(tv-1)
	if length!=c.size_t(4+3*m) do return -1
	var residual:[MAX_N*MAX_N]i64
	for i:=0;i<m;i+=1 {u:=input[4+3*i];v:=input[5+3*i];cap:=input[6+3*i];if u<1||u>nv||v<1||v>nv||u==v||cap<0||cap>100 do return -1;residual[(int(u)-1)*MAX_N+int(v)-1]+=cap}
	flow:i64=0
	for {
		var level:[MAX_N]int;for i:=0;i<MAX_N;i+=1 {level[i]=-1}
		var queue:[MAX_N]int;head:=0;tail:=0;level[s]=0;queue[tail]=s;tail+=1
		for head<tail {u:=queue[head];head+=1;for v:=0;v<n;v+=1 {if residual[u*MAX_N+v]>0&&level[v]<0 {level[v]=level[u]+1;queue[tail]=v;tail+=1}}}
		if level[t]<0 do break
		var next:[MAX_N]int
		for {pushed:=dfs(s,t,6401,&residual,&level,&next,n);if pushed==0 do break;flow+=pushed}
	}
	return flow
}
