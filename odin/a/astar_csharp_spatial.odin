package astar_csharp_spatial

import "core:c"
import "core:math"

MAX_NODES :: 16
Node :: struct { x, y, multiplier, current, estimated: f64, traversable: bool, state, parent: i32 }

distance :: proc(nodes: [^]Node, a, b: int) -> f64 {
	dx, dy := nodes[a].x-nodes[b].x, nodes[a].y-nodes[b].y
	return math.sqrt(dx*dx + dy*dy)
}
total :: proc(nodes: [^]Node, i: int) -> f64 { return nodes[i].current + nodes[i].estimated }
enqueue :: proc(heap: [^]int, count: ^int, value: int, nodes: [^]Node) {
	i := count^; count^ += 1
	for i > 0 { p := (i-1)/2; if total(nodes,heap[p]) <= total(nodes,value) { break }; heap[i]=heap[p]; i=p }
	heap[i]=value
}
dequeue :: proc(heap: [^]int, count: ^int, nodes: [^]Node) -> int {
	target := heap[0]; count^ -= 1; root := heap[count^]; i := 0
	for i*2+1 < count^ { l:=i*2+1; r:=i*2+2; child:=l; if r<count^ && total(nodes,heap[r])<total(nodes,heap[l]) { child=r }; if total(nodes,heap[child])>=total(nodes,root) { break }; heap[i]=heap[child]; i=child }
	if count^ > 0 { heap[i]=root }; return target
}
put_i64_le :: proc(output: [^]u8, offset: int, value: i64) { bits:=transmute(u64)value; for b:=0;b<8;b+=1 { output[offset+b]=u8(bits>>u64(b*8)) } }

@(export)
astar_csharp_spatial :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<4 do return -1
	n64,m64,s64,g64:=input[0],input[1],input[2],input[3]
	if n64<2 || n64>MAX_NODES || m64!=n64-1 || s64<0 || s64>=n64 || g64<0 || g64>=n64 do return -1
	n,m,start,goal:=int(n64),int(m64),int(s64),int(g64); edge:=4+4*n
	if length!=n+3*n+4+2*m do return -1
	var nodes: [MAX_NODES]Node; var parents,seen,stack: [MAX_NODES]int
	for i:=0;i<n;i+=1 { o:=4+4*i; x,y,t,mul:=input[o],input[o+1],input[o+2],input[o+3]
		if x < -1000 || x > 1000 || y < -1000 || y > 1000 || (t!=0 && t!=1) || mul<1 || mul>4 do return -1
		nodes[i]=Node{f64(x),f64(y),f64(mul),0,0,t==1,0,-1}
		for j:=0;j<i;j+=1 { if nodes[i].x==nodes[j].x && nodes[i].y==nodes[j].y do return -1 }
	}
	for e:=0;e<m;e+=1 { u,v:=input[edge+2*e],input[edge+2*e+1]; if u<0 || u>=n64 || v<0 || v>=n64 || u==v do return -1; parents[int(v)]+=1; if parents[int(v)]>1 do return -1; for p:=0;p<e;p+=1 { if input[edge+2*p]==u && input[edge+2*p+1]==v do return -1 } }
	if parents[start]!=0 do return -1; for i:=0;i<n;i+=1 { if i!=start && parents[i]!=1 do return -1 }
	top,visited:=0,0; stack[top]=start; top+=1; for top>0 { top-=1; u:=stack[top]; if seen[u]!=0 do continue; seen[u]=1; visited+=1; for e:=0;e<m;e+=1 { if input[edge+2*e]==i64(u) { stack[top]=int(input[edge+2*e+1]); top+=1 } } }; if visited!=n do return -1
	var heap: [MAX_NODES]int; hc:=0
	for e:=0;e<m;e+=1 { if input[edge+2*e]==i64(start) { v:=int(input[edge+2*e+1]); if nodes[v].traversable { nodes[v].current=distance(&nodes,start,v)*nodes[v].multiplier; nodes[v].estimated=distance(&nodes,v,goal); enqueue(&heap,&hc,v,&nodes) } } }
	var path: [MAX_NODES]int; pc:=0
	for hc>0 { u:=dequeue(&heap,&hc,&nodes); nodes[u].state=2; if total(&nodes,u)==total(&nodes,goal) { q:=goal; for q>=0 && pc<MAX_NODES { path[pc]=q; pc+=1; q=int(nodes[q].parent) }; break }
		for e:=0;e<m;e+=1 { if input[edge+2*e]!=i64(u) do continue; v:=int(input[edge+2*e+1]); if !nodes[v].traversable || nodes[v].state==2 do continue
			if nodes[v].state==0 { nodes[v].parent=i32(u); nodes[v].current=nodes[u].current+distance(&nodes,u,v)*nodes[v].multiplier; nodes[v].estimated=nodes[v].current+distance(&nodes,v,goal); nodes[v].state=1; enqueue(&heap,&hc,v,&nodes) }
			else if total(&nodes,u)!=total(&nodes,v) { ng:=nodes[u].current+distance(&nodes,u,v); nf:=ng+nodes[u].estimated; if nf<total(&nodes,v) { nodes[v].parent=i32(u); nodes[v].current=ng } }
			else { return -1 }
		}
	}
	bytes:=pc*8; if bytes==0 do return 0; if output==nil || capacity<c.size_t(bytes) do return -2
	for i:=0;i<pc;i+=1 { put_i64_le(output,i*8,i64(path[pc-1-i])) }; return i64(bytes)
}
