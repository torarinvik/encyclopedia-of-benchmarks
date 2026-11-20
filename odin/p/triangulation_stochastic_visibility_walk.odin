package triangulation_stochastic_visibility_walk

import "core:c"

tsw_cross :: proc(ax, ay, bx, by, px, py: i64) -> i64 {
	return (bx-ax)*(py-ay)-(by-ay)*(px-ax)
}
tsw_same :: proc(a, b, c, d: int) -> bool {
	return (a==c && b==d)||(a==d && b==c)
}
tsw_on :: proc(ax, ay, bx, by, px, py: i64) -> bool {
	return tsw_cross(ax,ay,bx,by,px,py)==0 && px>=min(ax,bx) && px<=max(ax,bx) && py>=min(ay,by) && py<=max(ay,by)
}
tsw_intersect :: proc(ax, ay, bx, by, cx, cy, dx, dy: i64) -> bool {
	o1:=tsw_cross(ax,ay,bx,by,cx,cy);o2:=tsw_cross(ax,ay,bx,by,dx,dy)
	o3:=tsw_cross(cx,cy,dx,dy,ax,ay);o4:=tsw_cross(cx,cy,dx,dy,bx,by)
	if (o1==0&&tsw_on(ax,ay,bx,by,cx,cy))||(o2==0&&tsw_on(ax,ay,bx,by,dx,dy))||(o3==0&&tsw_on(cx,cy,dx,dy,ax,ay))||(o4==0&&tsw_on(cx,cy,dx,dy,bx,by)) do return true
	return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0))
}

@(export)
triangulation_stochastic_visibility_walk :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values==nil||length<8||length>57 do return -1
	vr,br,tr,sr:=values[0],values[1],values[2],values[3]
	px,py,capr,kr:=values[4],values[5],values[6],values[7]
	if vr<3||vr>6||br<3||br>vr||tr!=2*vr-br-2||tr<1||tr>7||sr<0||sr>=tr||capr<0||capr>12||kr<0||kr>12||px< -200||px>200||py< -200||py>200 do return -1
	v,bcount,tcount,start,cap,k:=int(vr),int(br),int(tr),int(sr),int(capr),int(kr)
	if length!=c.size_t(8+2*v+bcount+3*tcount+k) do return -1
	var xs:[6]i64;var ys:[6]i64;var boundary:[6]int;var faces:[21]int;var neighbors:[21]int;var used:[6]bool
	cursor:c.size_t=8
	for i in 0..<v {
		xs[i]=values[cursor];ys[i]=values[cursor+1];cursor+=2
		if xs[i]< -200||xs[i]>200||ys[i]< -200||ys[i]>200 do return -1
		for j in 0..<i {if xs[i]==xs[j]&&ys[i]==ys[j] do return -1}
	}
	for i in 0..<bcount {
		raw:=values[cursor];cursor+=1
		if raw<0||raw>=vr do return -1
		boundary[i]=int(raw)
		for j in 0..<i {if boundary[i]==boundary[j] do return -1}
	}
	for i in 0..<bcount {
		a,b:=boundary[i],boundary[(i+1)%bcount]
		for j in 0..<bcount {c:=boundary[j];if c!=a&&c!=b&&tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0 do return -1}
	}
	for p in 0..<v {
		on_boundary:=false
		for j in 0..<bcount {if boundary[j]==p do on_boundary=true}
		if !on_boundary {for j in 0..<bcount {a,b:=boundary[j],boundary[(j+1)%bcount];if tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p])<=0 do return -1}}
	}
	area_sum:i64=0
	for f in 0..<tcount {
		for e in 0..<3 {raw:=values[cursor];cursor+=1;if raw<0||raw>=vr do return -1;faces[f*3+e]=int(raw)}
		a,b,c:=faces[f*3],faces[f*3+1],faces[f*3+2]
		if a==b||b==c||c==a||tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0 do return -1
		used[a]=true;used[b]=true;used[c]=true;area_sum+=tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])
		for g in 0..<f {same:=true;for e in 0..<3 {found:=false;for j in 0..<3 {if faces[f*3+e]==faces[g*3+j] do found=true};if !found do same=false};if same do return -1}
		for e in 0..<3 {neighbors[f*3+e]=-1}
	}
	for i in 0..<v {if !used[i] do return -1}
	polygon_area:i64=0
	for i in 0..<bcount {a,b:=boundary[i],boundary[(i+1)%bcount];polygon_area+=xs[a]*ys[b]-ys[a]*xs[b]}
	if polygon_area<=0||polygon_area!=area_sum do return -1
	for i in 0..<bcount {a,b:=boundary[i],boundary[(i+1)%bcount];owners:=0;for f in 0..<tcount {for e in 0..<3 {if tsw_same(a,b,faces[f*3+e],faces[f*3+(e+1)%3]) do owners+=1}};if owners!=1 do return -1}
	for f in 0..<tcount {for e in 0..<3 {
		a,b:=faces[f*3+e],faces[f*3+(e+1)%3];first:=true
		for g in 0..<f {for ge in 0..<3 {if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]) do first=false}}
		for ge in 0..<e {if tsw_same(a,b,faces[f*3+ge],faces[f*3+(ge+1)%3]) do first=false}
		if first {for p in 0..<v {if p!=a&&p!=b&&tsw_on(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p]) do return -1};for g in f..<tcount {for ge in 0..<3 {if g==f&&ge<=e do continue;c,d:=faces[g*3+ge],faces[g*3+(ge+1)%3];if a==c||a==d||b==c||b==d do continue;if tsw_intersect(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c],xs[d],ys[d]) do return -1}}}
	}}
	for f in 0..<tcount {for e in 0..<3 {
		a,b:=faces[f*3+e],faces[f*3+(e+1)%3];boundary_edge:=false
		for i in 0..<bcount {if tsw_same(a,b,boundary[i],boundary[(i+1)%bcount]) do boundary_edge=true}
		owners,other:=0,-1;first_u,first_v:=-1,-1
		for g in 0..<tcount {for ge in 0..<3 {if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]) {if owners==0 {first_u=faces[g*3+ge];first_v=faces[g*3+(ge+1)%3]} else if faces[g*3+ge]!=first_v||faces[g*3+(ge+1)%3]!=first_u {return -1};owners+=1;if g!=f {other=g}}}}
		if owners!=(if boundary_edge {1}else{2}) do return -1
		if !boundary_edge do neighbors[f*3+e]=other
	}}
	for i in 0..<k {if values[cursor+c.size_t(i)]<0||values[cursor+c.size_t(i)]>1 do return -1}
	for i in 0..<bcount {a,b:=boundary[i],boundary[(i+1)%bcount];if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)<=0 do return -1}
	containing:=0
	for f in 0..<tcount {a,b,c:=faces[f*3],faces[f*3+1],faces[f*3+2];if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)>0&&tsw_cross(xs[b],ys[b],xs[c],ys[c],px,py)>0&&tsw_cross(xs[c],ys[c],xs[a],ys[a],px,py)>0 do containing+=1}
	if containing!=1 do return -1
	face,steps,choice_index:=start,0,0;trace,predicates:=i64(start+1),i64(0);status:=i64(0)
	for {
		a,b,c:=faces[face*3],faces[face*3+1],faces[face*3+2];eu,ev:=[3]int{a,b,c},[3]int{b,c,a};eligible:=[3]int{};count:=0
		for e in 0..<3 {predicates+=1;if tsw_cross(xs[eu[e]],ys[eu[e]],xs[ev[e]],ys[ev[e]],px,py)<0 {eligible[count]=e;count+=1}}
		if count==0 {status=0;break};if steps==cap {status=2;break}
		selected:=0
		if count==1 {selected=eligible[0]} else if count==2 {if choice_index==k {status=1;break};selected=eligible[int(values[cursor+c.size_t(choice_index)])];choice_index+=1} else {return -1}
		face=neighbors[face*3+selected];if face<0 do return -1;steps+=1;trace=trace*9+i64(face+1)
	}
	return (trace*40+predicates)*3+status
}
