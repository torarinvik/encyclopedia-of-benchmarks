module bfs_graph_coloring

import core:c

const max_vertices = 64
const max_edges = 2016
const max_output_values = max_vertices + 2
fn put_i64(mut output &u8, offset int, value i64) { bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits>>(8*b))}} }
@[export: 'bfs_graph_coloring']
pub fn bfs_graph_coloring(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if unsafe{input==nil}||length<2{return -1}
	unsafe {nv,mv:=input[0],input[1];if nv<0||nv>max_vertices||mv<0||mv>max_edges||length!=usize(2+2*mv){return -1};n,m:=int(nv),int(mv)
		mut adjacency:=[]bool{len:max_vertices*max_vertices};mut degree:=[max_vertices]int{}
		for e in 0..m{uv,vv:=input[2+2*e],input[3+2*e];if uv<0||uv>=nv||vv<0||vv>=nv||uv==vv{return -1};u,v:=int(uv),int(vv);a,b:=u*max_vertices+v,v*max_vertices+u;if adjacency[a]{return -1};adjacency[a]=true;adjacency[b]=true;degree[u]++;degree[v]++}
		mut visited:=[max_vertices]bool{};mut queue:=[max_vertices]int{}
		for start in 0..n{if visited[start]{continue};mut head:=0;mut tail:=0;mut high:=0;visited[start]=true;queue[tail]=start;tail++
			for head<tail{vertex:=queue[head];head++;if degree[vertex]>1{high++};for nb in 0..n{if adjacency[vertex*max_vertices+nb]&&!visited[nb]{visited[nb]=true;queue[tail]=nb;tail++}}};if high>1{return -1}
		}
		mut colors:=[max_vertices]i64{};for i in 0..n{colors[i]=1};for i in 0..max_vertices{visited[i]=false}
		for start in 0..n{if visited[start]{continue};mut head:=0;mut tail:=0;visited[start]=true;queue[tail]=start;tail++
			for head<tail{front:=queue[head];head++;for nb in 0..n{if !adjacency[front*max_vertices+nb]{continue};if colors[nb]==colors[front]{colors[nb]++};if !visited[nb]{visited[nb]=true;queue[tail]=nb;tail++}}}
		}
		mut packed:=[max_output_values]i64{};packed[0]=i64(n);mut used_colors:=i64(0);for i in 0..n{packed[i+1]=colors[i];if colors[i]>used_colors{used_colors=colors[i]}};packed[n+1]=used_colors;required:=(n+2)*8
		if capacity<required||(required!=0&&unsafe{output==nil}){return -2};for i in 0..n+2{put_i64(mut output,i*8,packed[i])};return i64(required)
	}
}
