package edmonds_blossom_algorithm

import "core:c"

MAX_V :: 20

@(export)
edmonds_blossom_algorithm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	n64 := input[0]; m64 := input[1]
	if n64 < 0 || n64 > 20 || m64 < 0 || m64 > 190 do return -1
	n := int(n64); m := int(m64); if int(length) != 2 + 2*m do return -1
	graph: [MAX_V*MAX_V]bool
	for i:=0; i<m; i+=1 {
		a:=input[2+2*i]; b:=input[3+2*i]
		if a<0 || a>=n64 || b<0 || b>=n64 || a==b do return -1
		u:=int(a); v:=int(b); graph[u*MAX_V+v]=true; graph[v*MAX_V+u]=true
	}
	match: [MAX_V]int; parent: [MAX_V]int; base: [MAX_V]int; used: [MAX_V]bool; blossom: [MAX_V]bool; queue: [MAX_V]int
	for i:=0; i<MAX_V; i+=1 { match[i]=-1 }
	answer:=0
	for root:=0; root<n; root+=1 {
		if match[root]!=-1 do continue
		for i:=0; i<n; i+=1 { used[i]=false; parent[i]=-1; base[i]=i }
		head:=0; tail:=0; queue[tail]=root; tail+=1; used[root]=true; endpoint:=-1
		for head<tail && endpoint==-1 {
			v:=queue[head]; head+=1
			for u:=0; u<n; u+=1 {
				if !graph[v*MAX_V+u] || base[v]==base[u] || match[v]==u do continue
				if u==root || (match[u]!=-1 && parent[match[u]]!=-1) {
					path: [MAX_V]bool; x:=v; y:=u
					for { x=base[x]; path[x]=true; if match[x]==-1 { break }; x=parent[match[x]] }
					for !path[base[y]] { y=parent[match[base[y]]] }
					common:=base[y]; for i:=0; i<n; i+=1 { blossom[i]=false }
					x=v; y=u
					for base[x]!=common { blossom[base[x]]=true; blossom[base[match[x]]]=true; parent[x]=y; y=match[x]; x=parent[match[x]] }
					x=u; y=v
					for base[x]!=common { blossom[base[x]]=true; blossom[base[match[x]]]=true; parent[x]=y; y=match[x]; x=parent[match[x]] }
					for i:=0; i<n; i+=1 { if blossom[base[i]] { base[i]=common; if !used[i] { used[i]=true; queue[tail]=i; tail+=1 } } }
				} else if parent[u]==-1 {
					parent[u]=v; if match[u]==-1 { endpoint=u; break }
					next:=match[u]; used[next]=true; queue[tail]=next; tail+=1
				}
			}
		}
		if endpoint!=-1 { v:=endpoint; for v!=-1 { pv:=parent[v]; next:=match[pv]; match[v]=pv; match[pv]=v; v=next }; if match[root]!=-1 { answer+=1 } }
	}
	return i64(answer)
}
