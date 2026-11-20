// Offline point location by sweeping edge endpoints and query x-coordinates.
module point_location_sweep

struct PlPoint { x i64; y i64 }
struct PlEdge { u int; v int; face int }
struct PlEvent { x i64; kind int; id int }
struct PlState {
mut:
	points [16]PlPoint
	edges [24]PlEdge
}

fn pl_cross(a PlPoint,b PlPoint,c PlPoint) i64 { return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x) }
fn pl_on_segment(a PlPoint,b PlPoint,p PlPoint) bool { return pl_cross(a,b,p)==0&&p.x>=min(a.x,b.x)&&p.x<=max(a.x,b.x)&&p.y>=min(a.y,b.y)&&p.y<=max(a.y,b.y) }
fn pl_intersects(a PlPoint,b PlPoint,c PlPoint,d PlPoint) bool {
	o1:=pl_cross(a,b,c);o2:=pl_cross(a,b,d);o3:=pl_cross(c,d,a);o4:=pl_cross(c,d,b)
	if (o1==0&&pl_on_segment(a,b,c))||(o2==0&&pl_on_segment(a,b,d))||(o3==0&&pl_on_segment(c,d,a))||(o4==0&&pl_on_segment(c,d,b)){return true}
	return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0))
}
fn pl_left(state &PlState,e PlEdge) int { return if state.points[e.u].x<state.points[e.v].x {e.u}else{e.v} }
fn pl_right(state &PlState,e PlEdge) int { return if state.points[e.u].x<state.points[e.v].x {e.v}else{e.u} }
fn pl_height_num(state &PlState,e PlEdge,x i64,mut den i64) i64 {
	left:=pl_left(state,e);right:=pl_right(state,e);den=state.points[right].x-state.points[left].x
	return state.points[left].y*den+(state.points[right].y-state.points[left].y)*(x-state.points[left].x)
}
fn pl_edge_less(state &PlState,edges [24]PlEdge,first int,second int,x i64) bool {
	mut d1:=i64(0);mut d2:=i64(0);n1:=pl_height_num(state,edges[first],x,mut d1);n2:=pl_height_num(state,edges[second],x,mut d2)
	if n1*d2!=n2*d1{return n1*d2<n2*d1}
	l1:=pl_left(state,edges[first]);r1:=pl_right(state,edges[first]);l2:=pl_left(state,edges[second]);r2:=pl_right(state,edges[second])
	s1:=(state.points[r1].y-state.points[l1].y)*(state.points[r2].x-state.points[l2].x);s2:=(state.points[r2].y-state.points[l2].y)*(state.points[r1].x-state.points[l1].x)
	if s1!=s2{return s1<s2};return first<second
}
fn pl_event_less(a PlEvent,b PlEvent) bool { if a.x!=b.x{return a.x<b.x};if a.kind!=b.kind{return a.kind<b.kind};return a.id<b.id }
fn pl_query(state &PlState,edges [24]PlEdge,active [24]int,count int,x i64,y i64,faces int) i64 {
	mut low:=0;mut high:=count
	for low<high{mid:=low+(high-low)/2;mut den:=i64(0);num:=pl_height_num(state,edges[active[mid]],x,mut den);if num<y*den{low=mid+1}else{high=mid}}
	if low<count{mut den:=i64(0);num:=pl_height_num(state,edges[active[low]],x,mut den);if num==y*den{return i64(faces+active[low]+1)}}
	if low==0||edges[active[low-1]].face<0{return 0};return i64(edges[active[low-1]].face+1)
}

@[export: 'point_location_sweep']
pub fn point_location_sweep(input &i64,length usize) i64 {
	unsafe {
		if input==nil||length<4||length>141{return -1}
		nr,mr,qr,fr:=input[0],input[1],input[2],input[3]
		if nr<2||nr>16||mr<1||mr>24||qr<0||qr>16||fr<1||fr>16{return -1}
		n,m,q,faces:=int(nr),int(mr),int(qr),int(fr)
		if length!=usize(4+2*n+3*m+2*q){return -1}
		mut state:=PlState{};mut queries:=[16]PlPoint{};mut cursor:=4
		for i in 0..n{state.points[i]=PlPoint{x:input[cursor],y:input[cursor+1]};cursor+=2;if state.points[i].x< -300||state.points[i].x>300||state.points[i].y< -300||state.points[i].y>300{return -1};for j in 0..i{if state.points[j].x==state.points[i].x{return -1}}}
		for i in 0..m{u,v,face:=input[cursor],input[cursor+1],input[cursor+2];cursor+=3;if u<0||u>=nr||v<0||v>=nr||u==v||face< -1||face>=fr{return -1};state.edges[i]=PlEdge{u:int(u),v:int(v),face:int(face)};for j in 0..i{if(state.edges[j].u==int(u)&&state.edges[j].v==int(v))||(state.edges[j].u==int(v)&&state.edges[j].v==int(u)){return -1};su:=state.edges[j].u==int(u)||state.edges[j].u==int(v);sv:=state.edges[j].v==int(u)||state.edges[j].v==int(v);if su||sv{common:=if su{state.edges[j].u}else{state.edges[j].v};oa:=if int(u)==common{int(v)}else{int(u)};ob:=if state.edges[j].u==common{state.edges[j].v}else{state.edges[j].u};if pl_cross(state.points[common],state.points[oa],state.points[ob])==0{return -1}}else if pl_intersects(state.points[int(u)],state.points[int(v)],state.points[state.edges[j].u],state.points[state.edges[j].v]){return -1}}}
		for i in 0..q{queries[i]=PlPoint{x:input[cursor],y:input[cursor+1]};cursor+=2;if queries[i].x< -300||queries[i].x>300||queries[i].y< -300||queries[i].y>300{return -1};for j in 0..n{if queries[i].x==state.points[j].x{return -1}}}
		mut events:=[64]PlEvent{};mut ec:=0
		for i in 0..m{left:=pl_left(&state,state.edges[i]);right:=pl_right(&state,state.edges[i]);events[ec]=PlEvent{x:state.points[left].x,kind:1,id:i};ec++;events[ec]=PlEvent{x:state.points[right].x,kind:0,id:i};ec++}
		for i in 0..q{events[ec]=PlEvent{x:queries[i].x,kind:2,id:i};ec++}
		for i in 1..ec{key:=events[i];mut j:=i;for j>0&&pl_event_less(key,events[j-1]){events[j]=events[j-1];j--};events[j]=key}
		mut active:=[24]int{};mut ac:=0;mut answers:=[16]i64{}
		for ei in 0..ec{ev:=events[ei];if ev.kind==0{mut pos:=0;for pos<ac&&active[pos]!=ev.id{pos++};if pos==ac{return -1};for j in pos+1..ac{active[j-1]=active[j]};ac--}else if ev.kind==1{mut low:=0;mut high:=ac;for low<high{mid:=low+(high-low)/2;if pl_edge_less(&state,state.edges,active[mid],ev.id,ev.x){low=mid+1}else{high=mid}};mut j:=ac;for j>low{active[j]=active[j-1];j--};active[low]=ev.id;ac++}else{answers[ev.id]=pl_query(&state,state.edges,active,ac,ev.x,queries[ev.id].y,faces)}}
		mut result:=i64(0);for i in 0..q{result+=i64(i+1)*answers[i]};return result
	}
}
