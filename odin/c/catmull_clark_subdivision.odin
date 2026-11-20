package catmull_clark_subdivision

import "core:c"
import "core:math"

MAX_V :: 24
MAX_F :: 8
MAX_D :: 8
MAX_E :: 32
MAX_IN :: 122
MAX_OUT :: 386

Edge :: struct { u, v, f0, f1, uses: int }

cc_int :: proc "contextless" (value: f64, low, high: int) -> int {
	if !math.is_finite(value) || math.trunc_f64(value) != value || value < f64(low) || value > f64(high) do return -1
	return int(value)
}

cc_mean :: proc "contextless" (values: [^]f64, count: int) -> f64 {
	scale: f64 = 0.0
	for i in 0..<count { if math.abs(values[i]) > scale do scale = math.abs(values[i]) }
	if scale == 0.0 do return 0.0
	sum: f64 = 0.0
	for i in 0..<count { sum += values[i] / scale }
	return (sum / f64(count)) * scale
}

cc_average4 :: proc "contextless" (a,b,c0,d: f64) -> f64 {
	scale := math.abs(a)
	if math.abs(b)>scale do scale=math.abs(b)
	if math.abs(c0)>scale do scale=math.abs(c0)
	if math.abs(d)>scale do scale=math.abs(d)
	if scale==0.0 do return 0.0
	return ((a/scale+b/scale+c0/scale+d/scale)*0.25)*scale
}

@(export)
catmull_clark_subdivision :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_IN do return -1
	n_input := int(length)
	for i in 0..<n_input { if !math.is_finite(input[i]) do return -1 }
	nv := cc_int(input[0],0,MAX_V); nf := cc_int(input[1],0,MAX_F)
	if nv < 0 || nf < 0 do return -1
	if (nv == 0 || nf == 0) && !(nv == 0 && nf == 0 && n_input == 2) do return -1

	x: [MAX_V]f64
	y: [MAX_V]f64
	degree: [MAX_F]int
	face: [MAX_F][MAX_D]int
	pos := 2
	if pos + 2*nv > n_input do return -1
	for v in 0..<nv { x[v]=input[pos]; y[v]=input[pos+1]; pos+=2 }
	edges: [MAX_E]Edge
	ne := 0
	for f in 0..<nf {
		if pos >= n_input do return -1
		degree[f]=cc_int(input[pos],3,MAX_D); pos+=1
		if degree[f] < 0 || pos+degree[f] > n_input do return -1
		for i in 0..<degree[f] {
			face[f][i]=cc_int(input[pos],0,nv-1); pos+=1
			if face[f][i] < 0 do return -1
			for j in 0..<i { if face[f][i]==face[f][j] do return -1 }
		}
		for i in 0..<degree[f] {
			a:=face[f][i]; b:=face[f][(i+1)%degree[f]]; u:=a; v:=b
			if u>v { u,v=v,u }
			found:=-1
			for e in 0..<ne { if edges[e].u==u && edges[e].v==v { found=e; break } }
			if found<0 { if ne==MAX_E do return -1; found=ne; ne+=1; edges[found]=Edge{u,v,f,-1,1} }
			else { if edges[found].uses!=1 || edges[found].f0==f do return -1; edges[found].uses=2; edges[found].f1=f }
		}
	}
	if pos!=n_input do return -1
	for e in 0..<ne { if edges[e].uses!=2 do return -1 }

	for vertex in 0..<nv {
		valence:=0
		for e in 0..<ne { if edges[e].u==vertex || edges[e].v==vertex do valence+=1 }
		link_a: [MAX_F]int; link_b: [MAX_F]int; links:=0
		for f in 0..<nf { for i in 0..<degree[f] { if face[f][i]==vertex {
			a:=face[f][(i+degree[f]-1)%degree[f]]; b:=face[f][(i+1)%degree[f]]; lo:=a; hi:=b; if lo>hi {lo,hi=hi,lo}
			for j in 0..<links { oldlo:=link_a[j];oldhi:=link_b[j];if oldlo>oldhi {oldlo,oldhi=oldhi,oldlo};if oldlo==lo&&oldhi==hi do return -1 }
			link_a[links]=a;link_b[links]=b;links+=1
		} } }
		if valence<3 || links!=valence do return -1
		reached: [MAX_V]bool; reached[link_a[0]]=true; changed:=true
		for changed { changed=false; for i in 0..<links { if reached[link_a[i]]&&!reached[link_b[i]] {reached[link_b[i]]=true;changed=true};if reached[link_b[i]]&&!reached[link_a[i]] {reached[link_a[i]]=true;changed=true} } }
		node_degree: [MAX_V]int; nodes:=0
		for i in 0..<links { node_degree[link_a[i]]+=1;node_degree[link_b[i]]+=1 }
		for u in 0..<nv { if node_degree[u]!=0 {nodes+=1;if node_degree[u]!=2||!reached[u] do return -1} }
		if nodes<3 do return -1
	}
	for i in 1..<ne { item:=edges[i]; j:=i; for j>0 && (edges[j-1].u>item.u || (edges[j-1].u==item.u && edges[j-1].v>item.v)) {edges[j]=edges[j-1];j-=1};edges[j]=item }
	face_x: [MAX_F]f64; face_y: [MAX_F]f64
	for f in 0..<nf { vx: [MAX_D]f64;vy: [MAX_D]f64;for i in 0..<degree[f] {vx[i]=x[face[f][i]];vy[i]=y[face[f][i]]};face_x[f]=cc_mean(&vx[0],degree[f]);face_y[f]=cc_mean(&vy[0],degree[f]) }
	staged: [MAX_OUT]f64;out:=0;new_v:=nv+ne+nf;new_f:=0;for f in 0..<nf {new_f+=degree[f]};staged[out]=f64(new_v);out+=1;staged[out]=f64(new_f);out+=1
	for vertex in 0..<nv {
		fxs: [MAX_F]f64;fys: [MAX_F]f64;rx: [MAX_F]f64;ry: [MAX_F]f64;nfi:=0;nei:=0
		for f in 0..<nf {for i in 0..<degree[f] {if face[f][i]==vertex {fxs[nfi]=face_x[f];fys[nfi]=face_y[f];nfi+=1;break}}}
		for e in 0..<ne {if edges[e].u==vertex||edges[e].v==vertex {qx: [2]f64={x[edges[e].u],x[edges[e].v]};qy: [2]f64={y[edges[e].u],y[edges[e].v]};rx[nei]=cc_mean(&qx[0],2);ry[nei]=cc_mean(&qy[0],2);nei+=1}}
		fa_x:=cc_mean(&fxs[0],nfi);fa_y:=cc_mean(&fys[0],nfi);ra_x:=cc_mean(&rx[0],nei);ra_y:=cc_mean(&ry[0],nei)
		sx:=math.abs(x[vertex]);sy:=math.abs(y[vertex]);if math.abs(fa_x)>sx do sx=math.abs(fa_x);if math.abs(ra_x)>sx do sx=math.abs(ra_x);if math.abs(fa_y)>sy do sy=math.abs(fa_y);if math.abs(ra_y)>sy do sy=math.abs(ra_y)
		px:=f64(0);py:=f64(0);if sx!=0 do px=((fa_x/sx+2*ra_x/sx+f64(nei-3)*(x[vertex]/sx))/f64(nei))*sx;if sy!=0 do py=((fa_y/sy+2*ra_y/sy+f64(nei-3)*(y[vertex]/sy))/f64(nei))*sy
		staged[out]=px;out+=1;staged[out]=py;out+=1
	}
	for e in 0..<ne {staged[out]=cc_average4(x[edges[e].u],x[edges[e].v],face_x[edges[e].f0],face_x[edges[e].f1]);out+=1;staged[out]=cc_average4(y[edges[e].u],y[edges[e].v],face_y[edges[e].f0],face_y[edges[e].f1]);out+=1}
	for f in 0..<nf {staged[out]=face_x[f];out+=1;staged[out]=face_y[f];out+=1}
	for f in 0..<nf {for i in 0..<degree[f] {vertex:=face[f][i];next:=face[f][(i+1)%degree[f]];prev:=face[f][(i+degree[f]-1)%degree[f]];u1:=vertex;v1:=next;if u1>v1 {u1,v1=v1,u1};u2:=prev;v2:=vertex;if u2>v2 {u2,v2=v2,u2};en:=0;ep:=0;for e in 0..<ne {if edges[e].u==u1&&edges[e].v==v1 do en=e;if edges[e].u==u2&&edges[e].v==v2 do ep=e};staged[out]=f64(vertex);out+=1;staged[out]=f64(nv+en);out+=1;staged[out]=f64(nv+ne+f);out+=1;staged[out]=f64(nv+ep);out+=1}}
	if out>MAX_OUT do return -1
	if output==nil || capacity<c.size_t(out) do return -2
	for i in 0..<out {output[i]=staged[i]}
	return i64(out)
}
