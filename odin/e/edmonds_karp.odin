package edmonds_karp

import "core:c"

MAX_VERTICES :: 16
MAX_CAPACITY :: i64(1_000_000)

@(export)
edmonds_karp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	n64 := input[0]; source64 := input[1]; sink64 := input[2]
	if n64 < 1 || n64 > MAX_VERTICES || source64 < 0 || source64 >= n64 || sink64 < 0 || sink64 >= n64 do return -1
	n := int(n64)
	if int(length) != 3 + n*n do return -1

	residual: [MAX_VERTICES*MAX_VERTICES]i64
	for row:=0; row<n; row+=1 {
		for column:=0; column<n; column+=1 {
			capacity := input[3+row*n+column]
			if capacity<0 || capacity>MAX_CAPACITY || (row==column && capacity!=0) do return -1
			residual[row*n+column]=capacity
		}
	}
	for left:=0; left<n; left+=1 {
		for right:=left+1; right<n; right+=1 {
			if residual[left*n+right]>0 && residual[right*n+left]>0 do return -1
		}
	}
	source:=int(source64); sink:=int(sink64)
	if source==sink do return 0
	total_flow:=i64(0)
	for {
		parent: [MAX_VERTICES]int
		queue: [MAX_VERTICES]int
		for vertex:=0; vertex<n; vertex+=1 { parent[vertex]=-1 }
		parent[source]=source
		head:=0; tail:=1; queue[0]=source
		for head<tail && parent[sink]==-1 {
			node:=queue[head]; head+=1
			for neighbor:=0; neighbor<n; neighbor+=1 {
				if residual[node*n+neighbor]<=0 || parent[neighbor]!=-1 do continue
				parent[neighbor]=node
				if neighbor==sink { break }
				queue[tail]=neighbor; tail+=1
			}
		}
		if parent[sink]==-1 do return total_flow
		path_flow:=MAX_CAPACITY; node:=sink
		for node!=source {
			previous:=parent[node]
			if residual[previous*n+node]<path_flow { path_flow=residual[previous*n+node] }
			node=previous
		}
		node=sink
		for node!=source {
			previous:=parent[node]
			residual[previous*n+node]-=path_flow
			residual[node*n+previous]+=path_flow
			node=previous
		}
		total_flow+=path_flow
	}
}
