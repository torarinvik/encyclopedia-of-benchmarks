module triangulation_stochastic_visibility_walk

fn tsw_cross(ax i64, ay i64, bx i64, by i64, px i64, py i64) i64 {
	return (bx-ax)*(py-ay)-(by-ay)*(px-ax)
}
fn tsw_same(a int, b int, c int, d int) bool {
	return (a==c && b==d)||(a==d && b==c)
}
fn tsw_on(ax i64, ay i64, bx i64, by i64, px i64, py i64) bool {
	return tsw_cross(ax,ay,bx,by,px,py)==0 && px>=min(ax,bx) && px<=max(ax,bx) && py>=min(ay,by) && py<=max(ay,by)
}
fn tsw_intersect(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) bool {
	o1:=tsw_cross(ax,ay,bx,by,cx,cy);o2:=tsw_cross(ax,ay,bx,by,dx,dy)
	o3:=tsw_cross(cx,cy,dx,dy,ax,ay);o4:=tsw_cross(cx,cy,dx,dy,bx,by)
	if (o1==0&&tsw_on(ax,ay,bx,by,cx,cy))||(o2==0&&tsw_on(ax,ay,bx,by,dx,dy))||(o3==0&&tsw_on(cx,cy,dx,dy,ax,ay))||(o4==0&&tsw_on(cx,cy,dx,dy,bx,by)) { return true }
	return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0))
}

@[export: 'triangulation_stochastic_visibility_walk']
pub fn triangulation_stochastic_visibility_walk(values &i64, length usize) i64 {
	unsafe {
		if isnil(values)||length<8||length>57 { return -1 }
		vr,br,tr,sr:=values[0],values[1],values[2],values[3]
		px,py,capr,kr:=values[4],values[5],values[6],values[7]
		if vr<3||vr>6||br<3||br>vr||tr!=2*vr-br-2||tr<1||tr>7||sr<0||sr>=tr||capr<0||capr>12||kr<0||kr>12||px< -200||px>200||py< -200||py>200 { return -1 }
		v,bcount,tcount,start,cap,k:=int(vr),int(br),int(tr),int(sr),int(capr),int(kr)
		if length!=usize(8+2*v+bcount+3*tcount+k) { return -1 }
		mut xs:=[6]i64{};mut ys:=[6]i64{};mut boundary:=[6]int{};mut faces:=[21]int{};mut neighbors:=[21]int{};mut used:=[6]bool{}
		mut cursor:=8
		for i in 0..v {
			xs[i]=values[cursor];ys[i]=values[cursor+1];cursor+=2
			if xs[i]< -200||xs[i]>200||ys[i]< -200||ys[i]>200 { return -1 }
			for j in 0..i { if xs[i]==xs[j]&&ys[i]==ys[j] { return -1 } }
		}
		for i in 0..bcount {
			raw:=values[cursor];cursor++
			if raw<0||raw>=vr { return -1 }
			boundary[i]=int(raw)
			for j in 0..i { if boundary[i]==boundary[j] { return -1 } }
		}
		for i in 0..bcount {
			a,b:=boundary[i],boundary[(i+1)%bcount]
			for j in 0..bcount { c:=boundary[j];if c!=a&&c!=b&&tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0 { return -1 } }
		}
		for p in 0..v {
			mut on_boundary:=false
			for j in 0..bcount { if boundary[j]==p { on_boundary=true } }
			if !on_boundary { for j in 0..bcount { a,b:=boundary[j],boundary[(j+1)%bcount];if tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p])<=0 { return -1 } } }
		}
		mut area_sum:=i64(0)
		for f in 0..tcount {
			for e in 0..3 { raw:=values[cursor];cursor++;if raw<0||raw>=vr { return -1 };faces[f*3+e]=int(raw) }
			a,b,c:=faces[f*3],faces[f*3+1],faces[f*3+2]
			if a==b||b==c||c==a||tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0 { return -1 }
			used[a]=true;used[b]=true;used[c]=true;area_sum+=tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])
			for g in 0..f { mut same:=true;for e in 0..3 { mut found:=false;for j in 0..3 { if faces[f*3+e]==faces[g*3+j] { found=true } };if !found { same=false } };if same { return -1 } }
			for e in 0..3 { neighbors[f*3+e]= -1 }
		}
		for i in 0..v { if !used[i] { return -1 } }
		mut polygon_area:=i64(0)
		for i in 0..bcount { a,b:=boundary[i],boundary[(i+1)%bcount];polygon_area+=xs[a]*ys[b]-ys[a]*xs[b] }
		if polygon_area<=0||polygon_area!=area_sum { return -1 }
		for i in 0..bcount { a,b:=boundary[i],boundary[(i+1)%bcount];mut owners:=0;for f in 0..tcount { for e in 0..3 { if tsw_same(a,b,faces[f*3+e],faces[f*3+(e+1)%3]) { owners++ } } };if owners!=1 { return -1 } }
		for f in 0..tcount { for e in 0..3 {
			a,b:=faces[f*3+e],faces[f*3+(e+1)%3];mut first:=true
			for g in 0..f { for ge in 0..3 { if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]) { first=false } } }
			if first { for p in 0..v { if p!=a&&p!=b&&tsw_on(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p]) { return -1 } };for g in f..tcount { for ge in 0..3 { if g==f&&ge<=e { continue };c,d:=faces[g*3+ge],faces[g*3+(ge+1)%3];if a==c||a==d||b==c||b==d { continue };if tsw_intersect(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c],xs[d],ys[d]) { return -1 } } } }
		} }
		for f in 0..tcount { for e in 0..3 {
			a,b:=faces[f*3+e],faces[f*3+(e+1)%3];mut boundary_edge:=false
			for i in 0..bcount { if tsw_same(a,b,boundary[i],boundary[(i+1)%bcount]) { boundary_edge=true } }
			mut owners:=0;mut other:= -1;mut first_u:= -1;mut first_v:= -1
			for g in 0..tcount { for ge in 0..3 { if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]) { if owners==0 { first_u=faces[g*3+ge];first_v=faces[g*3+(ge+1)%3] } else if faces[g*3+ge]!=first_v||faces[g*3+(ge+1)%3]!=first_u { return -1 };owners++;if g!=f { other=g } } } }
			if owners!=(if boundary_edge {1}else{2}) { return -1 }
			if !boundary_edge { neighbors[f*3+e]=other }
		} }
		for i in 0..k { if values[cursor+i]<0||values[cursor+i]>1 { return -1 } }
		for i in 0..bcount { a,b:=boundary[i],boundary[(i+1)%bcount];if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)<=0 { return -1 } }
		mut containing:=0
		for f in 0..tcount { a,b,c:=faces[f*3],faces[f*3+1],faces[f*3+2];if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)>0&&tsw_cross(xs[b],ys[b],xs[c],ys[c],px,py)>0&&tsw_cross(xs[c],ys[c],xs[a],ys[a],px,py)>0 { containing++ } }
		if containing!=1 { return -1 }
		mut face:=start;mut steps:=0;mut choice_index:=0;mut trace:=i64(face+1);mut predicates:=i64(0);mut status:=i64(0)
		for {
			a,b,c:=faces[face*3],faces[face*3+1],faces[face*3+2];eu:=[3]int{a,b,c};ev:=[3]int{b,c,a};mut eligible:=[3]int{};mut count:=0
			for e in 0..3 { predicates++;if tsw_cross(xs[eu[e]],ys[eu[e]],xs[ev[e]],ys[ev[e]],px,py)<0 { eligible[count]=e;count++ } }
			if count==0 { status=0;break };if steps==cap { status=2;break }
			mut selected:=0
			if count==1 { selected=eligible[0] } else if count==2 { if choice_index==k { status=1;break };selected=eligible[int(values[cursor+choice_index])];choice_index++ } else { return -1 }
			face=neighbors[face*3+selected];if face<0 { return -1 };steps++;trace=trace*9+i64(face+1)
		}
		return (trace*40+predicates)*3+status
	}
}
