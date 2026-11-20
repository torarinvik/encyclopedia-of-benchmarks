package weiler_atherton_polygon_intersection

import "core:c"

MAX_V :: 6
MAX_X :: 36
MAX_NODE :: 42
MAX_WORDS :: 210

Rat :: struct { n, d: i64 }
Point :: struct { xn, xd, yn, yd: i64 }
Crossing :: struct { p: Point, ta, tb: Rat, ae, ax, be, bx: bool }
Node :: struct { p: Point, cross: int }
Ring :: struct { p: [48]Point, count: int }

gcd64 :: proc "contextless" (a0, b0: i64) -> i64 {
	a, b := abs(a0), abs(b0)
	for b != 0 { r := a % b; a, b = b, r }
	return if a == 0 then 1 else a
}
make_rat :: proc "contextless" (n0, d0: i64) -> Rat {
	n, d := n0, d0
	if d < 0 { n, d = -n, -d }
	g := gcd64(n,d)
	return Rat{n/g,d/g}
}
less_rat :: proc "contextless" (a,b: Rat) -> bool { return a.n*b.d < b.n*a.d }
less_point :: proc "contextless" (a,b: Point) -> bool {
	if a.xn*b.xd != b.xn*a.xd do return a.xn*b.xd < b.xn*a.xd
	return a.yn*b.yd < b.yn*a.yd
}
int_point :: proc "contextless" (x,y:i64)->Point{return Point{x,1,y,1}}
orient :: proc "contextless" (ax,ay,bx,by,cx,cy:i64)->i64{return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)}
on_segment :: proc "contextless" (ax,ay,bx,by,px,py:i64)->bool{return orient(ax,ay,bx,by,px,py)==0&&px>=min(ax,bx)&&px<=max(ax,bx)&&py>=min(ay,by)&&py<=max(ay,by)}
relation :: proc "contextless" (ax,ay,bx,by,cx,cy,dx,dy:i64)->int{
	o1,o2,o3,o4:=orient(ax,ay,bx,by,cx,cy),orient(ax,ay,bx,by,dx,dy),orient(cx,cy,dx,dy,ax,ay),orient(cx,cy,dx,dy,bx,by)
	if ((o1>0&&o2<0)||(o1<0&&o2>0))&&((o3>0&&o4<0)||(o3<0&&o4>0)) do return 1
	if (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by)) do return 2
	return 0
}
poly_valid :: proc "contextless" (p: [^]i64,n:int)->bool{
	area:i64=0
	for i in 0..<n {prev:=(i+n-1)%n;next:=(i+1)%n;area+=p[2*i]*p[2*next+1]-p[2*i+1]*p[2*next];if orient(p[2*prev],p[2*prev+1],p[2*i],p[2*i+1],p[2*next],p[2*next+1])==0 do return false;for j in 0..<i{if p[2*i]==p[2*j]&&p[2*i+1]==p[2*j+1] do return false}}
	if area<=0 do return false
	for i in 0..<n {for j in i+1..<n{if j==i+1||(i==0&&j==n-1) do continue;k:=(i+1)%n;l:=(j+1)%n;if relation(p[2*i],p[2*i+1],p[2*k],p[2*k+1],p[2*j],p[2*j+1],p[2*l],p[2*l+1])!=0 do return false}}
	return true
}
inside :: proc "contextless" (x,y:i64,p:[^]i64,n:int)->bool{
	winding:=0
	for i in 0..<n{j:=(i+1)%n;side:=orient(p[2*i],p[2*i+1],p[2*j],p[2*j+1],x,y);if p[2*i+1]<=y&&y<p[2*j+1]&&side>0{winding+=1}else if p[2*j+1]<=y&&y<p[2*i+1]&&side<0{winding-=1}}
	return winding!=0
}
crossing_point :: proc "contextless" (ax,ay,bx,by,cx,cy,dx,dy:i64,ta,tb:^Rat)->Point{
	rx,ry,sx,sy:=bx-ax,by-ay,dx-cx,dy-cy;den,tn,un:=rx*sy-ry*sx,(cx-ax)*sy-(cy-ay)*sx,(cx-ax)*ry-(cy-ay)*rx
	if den<0{den,tn,un=-den,-tn,-un};ta^=make_rat(tn,den);tb^=make_rat(un,den);x:=make_rat(ax*den+rx*tn,den);y:=make_rat(ay*den+ry*tn,den);return Point{x.n,x.d,y.n,y.d}
}
store_i64_le :: proc "contextless" (output:[^]u8,offset:int,value:i64){bits:=u64(value);for byte in 0..<8{output[offset+byte]=u8((bits>>(8*byte))&255)}}
canonicalize :: proc (rings:^ [16]Ring,count:int){
	for r in 0..<count{pivot:=0;for i in 1..<rings[r].count{if less_point(rings[r].p[i],rings[r].p[pivot]){pivot=i}};if pivot>0{temp:[48]Point;for i in 0..<rings[r].count{temp[i]=rings[r].p[(pivot+i)%rings[r].count]};for i in 0..<rings[r].count{rings[r].p[i]=temp[i]}}}
	for i in 1..<count{key:=rings[i];j:=i;for j>0&&less_point(key.p[0],rings[j-1].p[0]){rings[j]=rings[j-1];j-=1};rings[j]=key}
}

@(export)
weiler_atherton_polygon_intersection :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<2||length>27 do return -1
	na0,nb0:=input[0],input[1];if na0<3||na0>MAX_V||nb0<3||nb0>MAX_V||length!=c.size_t(2+2*na0+2*nb0) do return -1
	na,nb:=int(na0),int(nb0);a:[12]i64;b:[12]i64;cursor:=2
	for i in 0..<2*na{v:=input[cursor];cursor+=1;if v < -16||v>16 do return -1;a[i]=v};for i in 0..<2*nb{v:=input[cursor];cursor+=1;if v < -16||v>16 do return -1;b[i]=v}
	if !poly_valid(&a[0],na)||!poly_valid(&b[0],nb) do return -1
	crossings:[MAX_X]Crossing;events_a:[MAX_V][MAX_V]int;events_b:[MAX_V][MAX_V]int;count_a:[MAX_V]int;count_b:[MAX_V]int;cross_count:=0
	for i in 0..<na{for j in 0..<nb{ai:=(i+1)%na;bj:=(j+1)%nb;rel:=relation(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1]);if rel==2 do return -1;if rel==1{
		c:=&crossings[cross_count];c.p=crossing_point(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],&c.ta,&c.tb)
		ab:=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*i],a[2*i+1]);aa:=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*ai],a[2*ai+1]);bb:=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1]);ba:=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*bj],b[2*bj+1]);c.ae=ab<0&&aa>0;c.ax=ab>0&&aa<0;c.be=bb<0&&ba>0;c.bx=bb>0&&ba<0;if(!c.ae&&!c.ax)||(!c.be&&!c.bx)||c.ae==c.be do return -1;events_a[i][count_a[i]]=cross_count;events_b[j][count_b[j]]=cross_count;count_a[i]+=1;count_b[j]+=1;cross_count+=1
	}}}
	rings:[16]Ring;ring_count:=0
	if cross_count==0{if inside(a[0],a[1],&b[0],nb){rings[0].count=na;for i in 0..<na{rings[0].p[i]=int_point(a[2*i],a[2*i+1])};ring_count=1}else if inside(b[0],b[1],&a[0],na){rings[0].count=nb;for i in 0..<nb{rings[0].p[i]=int_point(b[2*i],b[2*i+1])};ring_count=1}}else{
		nodes_a:[MAX_NODE]Node;nodes_b:[MAX_NODE]Node;pos_a:[MAX_X]int;pos_b:[MAX_X]int;nca,ncb:=0,0
		for e in 0..<na{nodes_a[nca]=Node{int_point(a[2*e],a[2*e+1]),-1};nca+=1;for z in 1..<count_a[e]{id:=events_a[e][z];k:=z;for k>0&&less_rat(crossings[id].ta,crossings[events_a[e][k-1]].ta){events_a[e][k]=events_a[e][k-1];k-=1};events_a[e][k]=id};for z in 0..<count_a[e]{id:=events_a[e][z];nodes_a[nca]=Node{crossings[id].p,id};pos_a[id]=nca;nca+=1}}
		for e in 0..<nb{nodes_b[ncb]=Node{int_point(b[2*e],b[2*e+1]),-1};ncb+=1;for z in 1..<count_b[e]{id:=events_b[e][z];k:=z;for k>0&&less_rat(crossings[id].tb,crossings[events_b[e][k-1]].tb){events_b[e][k]=events_b[e][k-1];k-=1};events_b[e][k]=id};for z in 0..<count_b[e]{id:=events_b[e][z];nodes_b[ncb]=Node{crossings[id].p,id};pos_b[id]=ncb;ncb+=1}}
		visited:[MAX_X]bool
		for start in 0..<nca{sid:=nodes_a[start].cross;if sid<0||!crossings[sid].ae||visited[sid] do continue;if ring_count>=16 do return -1;r:=&rings[ring_count];r.p[0]=nodes_a[start].p;r.count=1;visited[sid]=true;active_a:=true;index:=start;guard:=0
			for{guard+=1;if guard>2*cross_count+na+nb+1 do return -1;node_count:=ncb;if active_a{node_count=nca};next:=(index+1)%node_count;node:=nodes_b[next];if active_a{node=nodes_a[next]};if node.cross>=0{id:=node.cross;visited[id]=true;if active_a&&id==sid{break};exits:=crossings[id].bx;if active_a{exits=crossings[id].ax};if exits{if id==sid{break};active_a=!active_a;index=pos_b[id];if active_a{index=pos_a[id]};continue}};if r.count>=48 do return -1;r.p[r.count]=node.p;r.count+=1;index=next}
			if r.count<3 do return -1;ring_count+=1}
		for id in 0..<cross_count{if !visited[id] do return -1}
	}
	canonicalize(&rings,ring_count);words:[MAX_WORDS]i64;word_count:=0;words[word_count]=i64(ring_count);word_count+=1
	for r in 0..<ring_count{words[word_count]=i64(rings[r].count);word_count+=1;for i in 0..<rings[r].count{p:=rings[r].p[i];words[word_count]=p.xn;words[word_count+1]=p.xd;words[word_count+2]=p.yn;words[word_count+3]=p.yd;word_count+=4}}
	output_bytes:=word_count*8;if output_bytes>1680 do return -1;if output==nil||capacity<c.size_t(output_bytes) do return -2
	for i in 0..<word_count{store_i64_le(output,i*8,words[i])};return i64(output_bytes)
}
