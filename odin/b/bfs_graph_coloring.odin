package bfs_graph_coloring

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 2016
MAX_OUTPUT_VALUES :: MAX_VERTICES + 2
put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) { bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits>>(8*b))} }

@(export)
bfs_graph_coloring :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil||length<2 do return -1
	nv,mv:=input[0],input[1];if nv<0||nv>MAX_VERTICES||mv<0||mv>MAX_EDGES||length!=c.size_t(2+2*mv) do return -1
	n,m:=int(nv),int(mv);var adjacency:[MAX_VERTICES*MAX_VERTICES]bool;var degree:[MAX_VERTICES]int
	for e:=0;e<m;e+=1{uv,vv:=input[2+2*e],input[3+2*e];if uv<0||uv>=nv||vv<0||vv>=nv||uv==vv do return -1;u,v:=int(uv),int(vv);a,b:=u*MAX_VERTICES+v,v*MAX_VERTICES+u;if adjacency[a] do return -1;adjacency[a]=true;adjacency[b]=true;degree[u]++;degree[v]++}
	var visited:[MAX_VERTICES]bool;var queue:[MAX_VERTICES]int
	for start:=0;start<n;start+=1{if visited[start] do continue;head,tail,high:=0,0,0;visited[start]=true;queue[tail]=start;tail++
		for head<tail{vertex:=queue[head];head++;if degree[vertex]>1{high++};for nb:=0;nb<n;nb++{if adjacency[vertex*MAX_VERTICES+nb]&&!visited[nb]{visited[nb]=true;queue[tail]=nb;tail++}}};if high>1 do return -1
	}
	var colors:[MAX_VERTICES]i64;for i:=0;i<n;i++{colors[i]=1};for i:=0;i<MAX_VERTICES;i++{visited[i]=false}
	for start:=0;start<n;start++{if visited[start] do continue;head,tail:=0,0;visited[start]=true;queue[tail]=start;tail++
		for head<tail{front:=queue[head];head++;for nb:=0;nb<n;nb++{if !adjacency[front*MAX_VERTICES+nb] do continue;if colors[nb]==colors[front]{colors[nb]++};if !visited[nb]{visited[nb]=true;queue[tail]=nb;tail++}}}
	}
	var packed:[MAX_OUTPUT_VALUES]i64;packed[0]=i64(n);used_colors:=i64(0);for i:=0;i<n;i++{packed[i+1]=colors[i];if colors[i]>used_colors{used_colors=colors[i]}};packed[n+1]=used_colors
	used,required:=n+2,(n+2)*8;if output==nil||capacity<c.size_t(required) do return -2;for i:=0;i<used;i++{put_i64(output,i*8,packed[i])};return i64(required)
}
