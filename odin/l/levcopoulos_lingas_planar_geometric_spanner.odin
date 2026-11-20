package levcopoulos_lingas_planar_geometric_spanner

import "core:c"
import "core:math"

MAX_N :: 8
MAX_E :: 18
MAX_F :: 16
MAX_D :: 14
MAX_STACK :: 64
MAX_INPUT :: 55

Point :: struct { x, y: i64 }
Edge :: struct { u, v: int }
Face :: struct { a, b, c: int }
State :: struct {
	n, m, face_count, contour_len, stack_len: int,
	points: [MAX_N]Point,
	eu, ev: [MAX_E]i64,
	fa, fb, fc: [MAX_F]i64,
	degree, tree_degree: [MAX_N]int,
	rotation, tree_rotation: [MAX_N][MAX_N]i64,
	contour_u, contour_v, stack_u, stack_v: [MAX_STACK]i64,
	weight: [MAX_N][MAX_N]f64,
	hull: [MAX_N]bool,
	tree, kept: [MAX_N][MAX_N]bool,
}

orient :: proc(s: ^State, a, b, c0: i64) -> i64 {
	return (s.points[b].x-s.points[a].x)*(s.points[c0].y-s.points[a].y) - (s.points[b].y-s.points[a].y)*(s.points[c0].x-s.points[a].x)
}
incircle_det :: proc(s: ^State, a, b, c0, p: i64) -> i64 {
	ax, ay := s.points[a].x-s.points[p].x, s.points[a].y-s.points[p].y
	bx, by := s.points[b].x-s.points[p].x, s.points[b].y-s.points[p].y
	cx, cy := s.points[c0].x-s.points[p].x, s.points[c0].y-s.points[p].y
	return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx) + (cx*cx+cy*cy)*(ax*by-ay*bx)
}
distance2 :: proc(s: ^State, a, b: i64) -> i64 {
	dx, dy := s.points[a].x-s.points[b].x, s.points[a].y-s.points[b].y
	return dx*dx + dy*dy
}
sort_three :: proc(a, b, c0: ^i64) {
	if a^ > b^ { a^, b^ = b^, a^ }
	if b^ > c0^ { b^, c0^ = c0^, b^ }
	if a^ > b^ { a^, b^ = b^, a^ }
}
is_face :: proc(s: ^State, a0, b0, c0: i64) -> bool {
	a, b, cc := a0, b0, c0
	sort_three(&a, &b, &cc)
	for i := 0; i < s.face_count; i += 1 {
		if s.fa[i] == a && s.fb[i] == b && s.fc[i] == cc do return true
	}
	return false
}
angle_half :: proc(dx, dy: i64) -> int {
	if dy > 0 || (dy == 0 && dx >= 0) do return 0
	return 1
}
angle_less :: proc(s: ^State, origin, a, b: i64) -> bool {
	ax, ay := s.points[a].x-s.points[origin].x, s.points[a].y-s.points[origin].y
	bx, by := s.points[b].x-s.points[origin].x, s.points[b].y-s.points[origin].y
	ah, bh := angle_half(ax, ay), angle_half(bx, by)
	if ah != bh do return ah < bh
	cross := ax*by-ay*bx
	if cross != 0 do return cross > 0
	return a < b
}
sort_rotation :: proc(s: ^State) {
	for v := 0; v < s.n; v += 1 {
		for i := 1; i < s.degree[v]; i += 1 {
			key := s.rotation[v][i]
			pos := i
			for pos > 0 && angle_less(s, i64(v), key, s.rotation[v][pos-1]) {
				s.rotation[v][pos] = s.rotation[v][pos-1]
				pos -= 1
			}
			s.rotation[v][pos] = key
		}
	}
}
sort_tree_rotation :: proc(s: ^State) {
	for v := 0; v < s.n; v += 1 {
		for i := 1; i < s.tree_degree[v]; i += 1 {
			key := s.tree_rotation[v][i]
			pos := i
			for pos > 0 && angle_less(s, i64(v), key, s.tree_rotation[v][pos-1]) {
				s.tree_rotation[v][pos] = s.tree_rotation[v][pos-1]
				pos -= 1
			}
			s.tree_rotation[v][pos] = key
		}
	}
}
cw_next :: proc(s: ^State, u, v: i64) -> Edge {
	for i := 0; i < s.degree[v]; i += 1 {
		if s.rotation[v][i] == u do return Edge{int(v), int(s.rotation[v][(i+s.degree[v]-1)%s.degree[v]])}
	}
	return Edge{-1, -1}
}
cw_tree_next :: proc(s: ^State, u, v: i64) -> Edge {
	for i := 0; i < s.tree_degree[v]; i += 1 {
		if s.tree_rotation[v][i] == u do return Edge{int(v), int(s.tree_rotation[v][(i+s.tree_degree[v]-1)%s.tree_degree[v]])}
	}
	return Edge{-1, -1}
}
contour_find :: proc(s: ^State, u, v: i64) -> int {
	for i := 0; i < s.contour_len; i += 1 do if s.contour_u[i] == u && s.contour_v[i] == v do return i
	return -1
}
canonicalize :: proc(s: ^State) {
	if s.contour_len == 0 do return
	first := 0
	for i := 1; i < s.contour_len; i += 1 {
		if s.contour_u[i] < s.contour_u[first] || (s.contour_u[i] == s.contour_u[first] && s.contour_v[i] < s.contour_v[first]) do first = i
	}
	var tu, tv: [MAX_D]i64
	for i := 0; i < s.contour_len; i += 1 { at := (first+i)%s.contour_len; tu[i], tv[i] = s.contour_u[at], s.contour_v[at] }
	for i := 0; i < s.contour_len; i += 1 { s.contour_u[i], s.contour_v[i] = tu[i], tv[i] }
}
eligible :: proc(s: ^State, u, v: i64) -> bool {
	at := contour_find(s, u, v)
	if at < 0 || s.hull[v] || s.contour_len < 3 do return false
	next_at := (at+1)%s.contour_len
	next := cw_next(s, u, v)
	return s.contour_u[next_at] == next.u && s.contour_v[next_at] == next.v && is_face(s, u, v, next.v)
}
push_if_eligible :: proc(s: ^State, u, v: i64) -> bool {
	if !eligible(s, u, v) do return true
	if s.stack_len >= MAX_STACK do return false
	s.stack_u[s.stack_len], s.stack_v[s.stack_len] = u, v
	s.stack_len += 1
	return true
}

parse :: proc(s: ^State, input: [^]i64, length: c.size_t) -> bool {
	if input == nil || length < 14 || length > MAX_INPUT do return false
	n64 := input[0]
	if n64 < 3 || n64 > MAX_N do return false
	s.n = int(n64)
	m_at := 1+2*s.n
	if length <= c.size_t(m_at) do return false
	m64 := input[m_at]
	if m64 < 3 || m64 > MAX_E || length != c.size_t(m_at+1+2*m64) do return false
	s.m = int(m64)
	for i := 0; i < s.n; i += 1 {
		s.points[i] = Point{input[1+2*i], input[2+2*i]}
		if s.points[i].x < -10 || s.points[i].x > 10 || s.points[i].y < -10 || s.points[i].y > 10 do return false
		for j := 0; j < i; j += 1 do if s.points[i] == s.points[j] do return false
	}
	for a := 0; a < s.n; a += 1 {
		for b := a+1; b < s.n; b += 1 { for cc := b+1; cc < s.n; cc += 1 do if orient(s, i64(a), i64(b), i64(cc)) == 0 do return false }
	}
	for a := 0; a < s.n; a += 1 {
		for b := a+1; b < s.n; b += 1 { for cc := b+1; cc < s.n; cc += 1 { for d := cc+1; d < s.n; d += 1 do if incircle_det(s, i64(a), i64(b), i64(cc), i64(d)) == 0 do return false } }
	}
	var supplied, expected: [MAX_N][MAX_N]bool
	for i := 0; i < s.m; i += 1 {
		u, v := input[m_at+1+2*i], input[m_at+2+2*i]
		if u < 0 || v <= u || v >= n64 do return false
		if i > 0 && (u < s.eu[i-1] || (u == s.eu[i-1] && v <= s.ev[i-1])) do return false
		s.eu[i], s.ev[i] = u, v
		supplied[u][v], supplied[v][u] = true, true
	}
	for a0 := 0; a0 < s.n; a0 += 1 {
		for b0 := a0+1; b0 < s.n; b0 += 1 {
			for c0 := b0+1; c0 < s.n; c0 += 1 {
				a,b,cc := i64(a0),i64(b0),i64(c0)
				if orient(s,a,b,cc)<0 { b,cc=cc,b }
				empty:=true
				for p:=0;p<s.n;p+=1 do if i64(p)!=a && i64(p)!=b && i64(p)!=cc && incircle_det(s,a,b,cc,i64(p))>0 do empty=false
				if empty {
					fa,fb,fc:=a,b,cc;sort_three(&fa,&fb,&fc)
					if s.face_count>=MAX_F do return false
					s.fa[s.face_count],s.fb[s.face_count],s.fc[s.face_count]=fa,fb,fc;s.face_count+=1
					expected[a][b],expected[b][a]=true,true;expected[a][cc],expected[cc][a]=true,true;expected[b][cc],expected[cc][b]=true,true
				}
			}
		}
	}
	for a:=0;a<s.n;a+=1 do for b:=a+1;b<s.n;b+=1 do if supplied[a][b]!=expected[a][b] do return false
	for a:=0;a<s.n;a+=1 {
		for b:=a+1;b<s.n;b+=1 {
			positive,negative:=false,false
			for p:=0;p<s.n;p+=1 { if p==a || p==b do continue;side:=orient(s,i64(a),i64(b),i64(p));positive=positive||side>0;negative=negative||side<0 }
			if !(positive&&negative){s.hull[a],s.hull[b]=true,true}
		}
	}
	for i:=0;i<s.m;i+=1 {
		u,v:=s.eu[i],s.ev[i]
		s.rotation[u][s.degree[u]]=v;s.degree[u]+=1;s.rotation[v][s.degree[v]]=u;s.degree[v]+=1
	}
	sort_rotation(s)
	return true
}

build_tree :: proc(s: ^State) -> bool {
	var order: [MAX_E]int
	for i:=0;i<s.m;i+=1 do order[i]=i
	for i:=1;i<s.m;i+=1 {
		key:=order[i];pos:=i
		for pos>0 {
			prev:=order[pos-1];pd,kd:=distance2(s,s.eu[prev],s.ev[prev]),distance2(s,s.eu[key],s.ev[key])
			if pd<kd || (pd==kd && (s.eu[prev]<s.eu[key] || (s.eu[prev]==s.eu[key] && s.ev[prev]<=s.ev[key]))) do break
			order[pos]=prev;pos-=1
		}
		order[pos]=key
	}
	var parent,size: [MAX_N]i64
	for i:=0;i<s.n;i+=1 { parent[i]=i;size[i]=1 }
	chosen:=0
	for rank:=0;rank<s.m;rank+=1 {
		e:=order[rank];u,v:=s.eu[e],s.ev[e];a,b:=u,v
		for parent[a]!=a {parent[a]=parent[parent[a]];a=parent[a]};for parent[b]!=b {parent[b]=parent[parent[b]];b=parent[b]}
		if a==b do continue
		if size[a]<size[b] {a,b=b,a};parent[b]=a;size[a]+=size[b]
		s.tree[u][v],s.tree[v][u]=true,true;s.kept[u][v],s.kept[v][u]=true,true
		s.tree_rotation[u][s.tree_degree[u]]=v;s.tree_degree[u]+=1;s.tree_rotation[v][s.tree_degree[v]]=u;s.tree_degree[v]+=1;chosen+=1
	}
	if chosen!=s.n-1 do return false
	sort_tree_rotation(s)
	for i:=0;i<s.m;i+=1 {u,v:=s.eu[i],s.ev[i];d:=math.sqrt(f64(distance2(s,u,v)));s.weight[u][v],s.weight[v][u]=d,d}
	fu,fv:=i64(MAX_N),i64(MAX_N)
	for u:=0;u<s.n;u+=1 do for v:=0;v<s.n;v+=1 do if s.tree[u][v] && (u<fu || (u==fu && v<fv)){fu,fv=u,v}
	if fu==MAX_N do return false
	s.contour_u[0],s.contour_v[0]=fu,fv;s.contour_len=1;expected:=2*(s.n-1)
	for s.contour_len<expected {
		last:=s.contour_len-1;next:=cw_tree_next(s,s.contour_u[last],s.contour_v[last]);if next.u<0 do return false
		if next.u==fu && next.v==fv do break
		if contour_find(s,next.u,next.v)>=0 || s.contour_len>=expected do return false
		s.contour_u[s.contour_len],s.contour_v[s.contour_len]=i64(next.u),i64(next.v);s.contour_len+=1
	}
	if s.contour_len!=expected do return false
	close:=cw_tree_next(s,s.contour_u[s.contour_len-1],s.contour_v[s.contour_len-1])
	return close.u==int(fu) && close.v==int(fv)
}

run_algorithm :: proc(s: ^State) -> (i64,i64,bool) {
	for i:=0;i<s.contour_len;i+=1 do if !push_if_eligible(s,s.contour_u[i],s.contour_v[i]) do return 0,0,false
	absorbed,steps:=i64(0),0
	for s.stack_len>0 && steps<2*MAX_E {
		s.stack_len-=1;v,w:=s.stack_u[s.stack_len],s.stack_v[s.stack_len]
		if !eligible(s,v,w) do continue
		at:=contour_find(s,v,w);next_at:=(at+1)%s.contour_len;u:=s.contour_v[next_at]
		path:=s.weight[v][w]+s.weight[w][u];direct:=math.sqrt(f64(distance2(s,v,u)))
		if path>2.0*direct{s.kept[v][u],s.kept[u][v]=true,true}else{s.weight[v][u]=path}
		if next_at==0 {
			for i:=0;i+1<s.contour_len;i+=1{s.contour_u[i],s.contour_v[i]=s.contour_u[i+1],s.contour_v[i+1]}
			s.contour_len-=1;s.contour_u[s.contour_len-1],s.contour_v[s.contour_len-1]=v,u
		}else{
			s.contour_u[at],s.contour_v[at]=v,u
			for i:=next_at;i+1<s.contour_len;i+=1{s.contour_u[i],s.contour_v[i]=s.contour_u[i+1],s.contour_v[i+1]};s.contour_len-=1
		}
		canonicalize(s);absorbed+=1;steps+=1;ci:=contour_find(s,v,u);if ci<0 do return 0,0,false
		if !push_if_eligible(s,v,u) do return 0,0,false
		li:=(ci+s.contour_len-1)%s.contour_len;if !push_if_eligible(s,s.contour_u[li],s.contour_v[li]) do return 0,0,false
	}
	if steps>=2*MAX_E && s.stack_len>0 do return 0,0,false
	shortcuts:=i64(0);for u:=0;u<s.n;u+=1 do for v:=u+1;v<s.n;v+=1 do if s.kept[u][v] && !s.tree[u][v] do shortcuts+=1
	return absorbed,shortcuts,true
}
store_i64_le :: proc(output: [^]u8, word: int, value: i64) {
	bits:=u64(value);for byte:=0;byte<8;byte+=1{output[word*8+byte]=u8(bits>>(8*byte))}
}

@(export)
levcopoulos_lingas_planar_geometric_spanner :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<14 || length>MAX_INPUT do return -1
	state: State
	if !parse(&state,input,length) || !build_tree(&state) do return -1
	absorbed,shortcuts,ok:=run_algorithm(&state);if !ok do return -1
	var words: [3+2*MAX_E]i64
	count:=3;words[0],words[1]=absorbed,shortcuts
	for u:=0;u<state.n;u+=1 do for v:=u+1;v<state.n;v+=1 do if state.kept[u][v]{words[count],words[count+1]=i64(u),i64(v);count+=2;words[2]+=1}
	bytes:=count*8;if output==nil || capacity<c.size_t(bytes) do return -2
	for i:=0;i<count;i+=1 do store_i64_le(output,i,words[i])
	return i64(bytes)
}
