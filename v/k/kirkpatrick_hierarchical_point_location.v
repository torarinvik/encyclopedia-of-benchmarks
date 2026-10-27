module kirkpatrick_hierarchical_point_location

const max_vertices = 16
const max_levels = 4
const max_faces = 8
const max_input = 268

fn cross(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}
fn on_segment(ax i64, ay i64, bx i64, by i64, px i64, py i64) bool {
	return cross(ax, ay, bx, by, px, py) == 0 && px >= min(ax,bx) && px <= max(ax,bx) && py >= min(ay,by) && py <= max(ay,by)
}
fn inside(qx i64, qy i64, t []i64, xy []i64) bool {
	a := int(t[0] * 2); b := int(t[1] * 2); c := int(t[2] * 2)
	return cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)>0 && cross(xy[b],xy[b+1],xy[c],xy[c+1],qx,qy)>0 && cross(xy[c],xy[c+1],xy[a],xy[a+1],qx,qy)>0
}
fn boundary(qx i64, qy i64, t []i64, xy []i64) bool {
	for e in 0..3 { a:=int(t[e]*2);b:=int(t[(e+1)%3]*2);if on_segment(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy){return true} }
	return false
}
fn seg_hit(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) bool {
	o1:=cross(ax,ay,bx,by,cx,cy);o2:=cross(ax,ay,bx,by,dx,dy);o3:=cross(cx,cy,dx,dy,ax,ay);o4:=cross(cx,cy,dx,dy,bx,by)
	if o1==0&&on_segment(ax,ay,bx,by,cx,cy){return true};if o2==0&&on_segment(ax,ay,bx,by,dx,dy){return true};if o3==0&&on_segment(cx,cy,dx,dy,ax,ay){return true};if o4==0&&on_segment(cx,cy,dx,dy,bx,by){return true}
	return o1*o2<0&&o3*o4<0
}
fn closed_inside(px i64, py i64, t []i64, xy []i64) bool {
	for e in 0..3 {a:=int(t[e]*2);b:=int(t[(e+1)%3]*2);if cross(xy[a],xy[a+1],xy[b],xy[b+1],px,py)<0{return false}}
	return true
}
fn tri_hit(a []i64, b []i64, xy []i64) bool {
	for i in 0..3 {p:=int(a[i]*2);if closed_inside(xy[p],xy[p+1],b,xy){return true};p=int(b[i]*2);if closed_inside(xy[p],xy[p+1],a,xy){return true}}
	for i in 0..3 {for j in 0..3 {a0:=int(a[i]*2);a1:=int(a[(i+1)%3]*2);b0:=int(b[j]*2);b1:=int(b[(j+1)%3]*2);if seg_hit(xy[a0],xy[a0+1],xy[a1],xy[a1+1],xy[b0],xy[b0+1],xy[b1],xy[b1+1]){return true}}}
	return false
}
fn put_i64(mut out &u8, at int, value i64) { bits:=u64(value);for j in 0..8 {unsafe{out[at+j]=u8((bits>>(8*j))&255)}} }

@[export: 'kirkpatrick_hierarchical_point_location']
pub fn kirkpatrick_hierarchical_point_location(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input==nil||length<14||length>max_input{return -1}
		nv64:=input[0];nl64:=input[1];qx:=input[2];qy:=input[3]
		if nv64<3||nv64>max_vertices||nl64<1||nl64>max_levels||qx< -1000||qx>1000||qy< -1000||qy>1000{return -1}
		n:=int(nv64);levels:=int(nl64);mut xy:=[max_vertices*2]i64{};mut faces:=[max_levels*max_faces*3]i64{};mut face_count:=[max_levels]int{};mut cc:=[max_levels*max_faces]int{};mut ids:=[max_levels*max_faces*max_faces]int{}
		mut pos:=4
		for v in 0..n {xy[2*v]=input[pos];xy[2*v+1]=input[pos+1];pos+=2;if xy[2*v]< -1000||xy[2*v]>1000||xy[2*v+1]< -1000||xy[2*v+1]>1000{return -1}}
		for level in 0..levels {
			if pos>=int(length){return -1};count64:=input[pos];pos++;if count64<1||count64>max_faces||(level==0&&count64!=1){return -1};count:=int(count64);face_count[level]=count
			for f in 0..count {if pos+3>int(length){return -1};base:=(level*max_faces+f)*3;for k in 0..3 {faces[base+k]=input[pos];pos++;if faces[base+k]<0||faces[base+k]>=nv64{return -1}};a:=int(faces[base]*2);b:=int(faces[base+1]*2);c:=int(faces[base+2]*2);if faces[base]==faces[base+1]||faces[base]==faces[base+2]||faces[base+1]==faces[base+2]||cross(xy[a],xy[a+1],xy[b],xy[b+1],xy[c],xy[c+1])<=0{return -1}}
			if level+1<levels {for f in 0..count {if pos>=int(length){return -1};nchild64:=input[pos];pos++;if nchild64<1||nchild64>max_faces||pos+int(nchild64)>int(length){return -1};nchild:=int(nchild64);cc[level*max_faces+f]=nchild;for j in 0..nchild {child64:=input[pos];pos++;if child64<0||child64>=max_faces{return -1};child:=int(child64);slot:=(level*max_faces+f)*max_faces+j;if j>0&&child<=ids[slot-1]{return -1};ids[slot]=child}}}
		}
		if pos!=int(length){return -1}
		for level in 0..levels-1 {for f in 0..face_count[level] {for j in 0..cc[level*max_faces+f] {child:=ids[(level*max_faces+f)*max_faces+j];if child>=face_count[level+1]||!tri_hit(faces[(level*max_faces+f)*3..(level*max_faces+f)*3+3],faces[((level+1)*max_faces+child)*3..((level+1)*max_faces+child)*3+3],xy[..]){return -1}}}}
		for level in 0..levels {mut hits:=0;for f in 0..face_count[level] {base:=(level*max_faces+f)*3;if boundary(qx,qy,faces[base..base+3],xy[..]){return -1};if inside(qx,qy,faces[base..base+3],xy[..]){hits++}};if hits!=1{return -1}}
		mut face:=0;mut predicates:=i64(1)
		for level in 0..levels-1 {mut found:=-1;for j in 0..cc[level*max_faces+face] {child:=ids[(level*max_faces+face)*max_faces+j];predicates++;base:=((level+1)*max_faces+child)*3;if inside(qx,qy,faces[base..base+3],xy[..]){found=child;break}};if found<0{return -1};face=found}
		if output==nil||capacity<16{return -2};mut staged:=[16]u8{};put_i64(mut &staged[0],0,i64(face));put_i64(mut &staged[0],8,predicates);for i in 0..16{output[i]=staged[i]};return 16
	}
}
