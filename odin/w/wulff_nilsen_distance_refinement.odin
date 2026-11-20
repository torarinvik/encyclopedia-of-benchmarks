package wulff_nilsen_distance_refinement

import "core:c"

SCALE :: i64(86093442)
INF :: i64(0x1000000000000000)
MAX_N :: 8

even_index :: proc(x: int, threshold: i64, nearest: ^[32]int, distance: ^[64]i64) -> int {
	if distance[x*MAX_N+nearest[2*MAX_N+x]] <= threshold { return 2 }
	return 0
}

refine_further :: proc(u, v, iu: int, nearest: ^[32]int, bunch: ^[64]bool, distance: ^[64]i64) -> bool {
	if iu < 2 { return false }
	return bunch[v*MAX_N+nearest[u]] || bunch[u*MAX_N+nearest[MAX_N+v]] ||
		bunch[v*MAX_N+nearest[iu*MAX_N+u]] || bunch[u*MAX_N+nearest[(iu+1)*MAX_N+v]]
}

@(export)
wulff_nilsen_distance_refinement :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 8 || length > 93 do return -1
	n0 := input[0]; m0 := input[1]
	if n0 < 2 || n0 > MAX_N || m0 < 0 || m0 > 28 do return -1
	n := int(n0); m := int(m0)
	if length != c.size_t(8+3*m) do return -1
	full := (i64(1) << n)-1
	mask: [3]i64
	for i in 0..<3 { mask[i]=input[2+i]; if mask[i]<=0 || (mask[i]&~full)!=0 do return -1 }
	if (mask[1]&~mask[0])!=0 || (mask[2]&~mask[1])!=0 do return -1
	distance: [64]i64
	for u in 0..<n { for v in 0..<n { distance[u*MAX_N+v]=if u==v do 0 else INF } }
	prev_u := -1; prev_v := -1
	for e in 0..<m {
		at := 5+3*e; u0:=input[at]; v0:=input[at+1]; weight:=input[at+2]
		if u0<0 || u0>=n0 || v0<=u0 || v0>=n0 || weight<SCALE || weight>100*SCALE || weight%SCALE!=0 do return -1
		u:=int(u0); v:=int(v0)
		if u<prev_u || (u==prev_u && v<=prev_v) do return -1
		prev_u=u;prev_v=v;distance[u*MAX_N+v]=weight;distance[v*MAX_N+u]=weight
	}
	q:=5+3*m; source0:=input[q]; target0:=input[q+1]; estimate:=input[q+2]
	if source0<0 || source0>=n0 || target0<0 || target0>=n0 || source0==target0 || estimate<=0 || estimate%SCALE!=0 do return -1
	source:=int(source0);target:=int(target0)
	for mid in 0..<n { for u in 0..<n { if distance[u*MAX_N+mid]==INF do continue; for v in 0..<n { candidate:=distance[u*MAX_N+mid]+distance[mid*MAX_N+v];if candidate<distance[u*MAX_N+v]{distance[u*MAX_N+v]=candidate} } } }
	for u in 0..<n { for v in 0..<n { if distance[u*MAX_N+v]==INF do return -1 } }
	if estimate<distance[source*MAX_N+target] || estimate>768*distance[source*MAX_N+target] do return -1
	nearest: [32]int
	for x in 0..<n { nearest[x]=x;for level in 1..<4 { best:=-1;for y in 0..<n { if (mask[level-1]>>y)&1!=0 && (best<0 || distance[x*MAX_N+y]<distance[x*MAX_N+best] || (distance[x*MAX_N+y]==distance[x*MAX_N+best]&&y<best)){best=y} };nearest[level*MAX_N+x]=best } }
	layers: [5]i64;layers[0]=full;layers[1]=mask[0];layers[2]=mask[1];layers[3]=mask[2];layers[4]=0
	bunch: [64]bool = {}
	for center in 0..<n { for level in 0..<4 { boundary:=INF;for y in 0..<n { if (layers[level+1]>>y)&1!=0 && distance[center*MAX_N+y]<boundary {boundary=distance[center*MAX_N+y]} };for y in 0..<n { if (layers[level]>>y)&1!=0 && (layers[level+1]>>y)&1==0 && distance[center*MAX_N+y]<boundary { bunch[center*MAX_N+y]=true } } } }
	value:=estimate;iu:=even_index(source,value,&nearest,&distance)
	if !refine_further(source,target,iu,&nearest,&bunch,&distance) do return value
	iteration:=0;for iteration<=15 && refine_further(source,target,iu,&nearest,&bunch,&distance) {value=2*value/3;iu=even_index(source,value,&nearest,&distance);iteration+=1}
	upper:=even_index(source,3*value/2,&nearest,&distance);if upper<2 do return -1
	pivot:=nearest[source];if bunch[target*MAX_N+pivot] do return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot]
	pivot=nearest[MAX_N+target];if bunch[source*MAX_N+pivot] do return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot]
	pivot=nearest[upper*MAX_N+source];if bunch[target*MAX_N+pivot] do return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot]
	pivot=nearest[(upper+1)*MAX_N+target];return distance[source*MAX_N+pivot]+distance[target*MAX_N+pivot]
}
