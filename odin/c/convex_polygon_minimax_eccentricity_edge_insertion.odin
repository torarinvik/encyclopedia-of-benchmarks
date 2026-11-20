package convex_polygon_minimax_eccentricity_edge_insertion

import "core:c"

MIN_N :: 3
MAX_N :: 6
MAX_LEN :: 14
MAX_TRI :: 4
MAX_ALL :: 14
MAX_DIAG :: 9
MAX_TRIPLES :: 20

Point :: struct { x, y: i64 }
Triangle :: struct { a, b, c: int }
Triangulation :: struct { triangles: [MAX_TRI]Triangle, count: int, edges: u64 }
Fraction :: struct { num, den: i64 }
Metrics :: struct { maximum: Fraction, worst: u64 }

orient :: proc "contextless" (a, b, c: Point) -> i64 {
	return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}
gcd64 :: proc "contextless" (a0, b0: i64) -> i64 {
	a,b := a0,b0
	for b != 0 { r := a%b; a=b; b=r }
	return a
}
fraction :: proc "contextless" (num, den: i64) -> Fraction {
	g := gcd64(num,den)
	return Fraction{num/g,den/g}
}
compare :: proc "contextless" (a,b: Fraction) -> int {
	left,right := a.num*b.den,b.num*a.den
	if left<right do return -1
	if left>right do return 1
	return 0
}
edge_bit :: proc "contextless" (a,b: int) -> u64 {
	lo,hi := min(a,b),max(a,b)
	return u64(1) << (lo*MAX_N+hi)
}
proper_cross :: proc "contextless" (p: []Point,a,b,c,d: int) -> bool {
	return orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0 && orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0
}
inside_triangle :: proc "contextless" (p: []Point,t: Triangle,v: int) -> bool {
	dir := orient(p[t.a],p[t.b],p[t.c])
	return orient(p[t.a],p[t.b],p[v])*dir>0 && orient(p[t.b],p[t.c],p[v])*dir>0 && orient(p[t.c],p[t.a],p[v])*dir>0
}
triangle_score :: proc "contextless" (p: []Point,t: Triangle,sides: []i64) -> Fraction {
	a,b,c := p[t.a],p[t.b],p[t.c]
	sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y)
	sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y)
	sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
	largest:=0
	if sides[1]>sides[largest] do largest=1
	if sides[2]>sides[largest] do largest=2
	other:=sides[0]+sides[1]+sides[2]-sides[largest]
	if sides[largest]<=other do return Fraction{0,1}
	area:=abs(orient(a,b,c));diff:=sides[largest]-other
	return fraction(sides[largest]*diff*diff,16*area*area)
}
triangle_id :: proc "contextless" (a,b,c,n: int) -> int {
	id:=0
	for x:=0;x<n;x+=1 { for y:=x+1;y<n;y+=1 { for z:=y+1;z<n;z+=1 {
		if x==a && y==b && z==c do return id
		id+=1
	}}}
	return 0
}
evaluate :: proc "contextless" (p: []Point,n: int,t: Triangulation) -> Metrics {
	m:=Metrics{Fraction{0,1},0}
	for i:=0;i<t.count;i+=1 {
		sides:=[3]i64{}
		s:=triangle_score(p,t.triangles[i],sides[:]);c:=compare(s,m.maximum)
		bit:=u64(1) << triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n)
		if c>0 {m.maximum=s;m.worst=bit} else if c==0 {m.worst|=bit}
	}
	return m
}
improves :: proc "contextless" (a,b: Metrics) -> bool {
	c:=compare(a.maximum,b.maximum)
	return c<0 || (c==0 && a.worst!=b.worst && (a.worst&b.worst)==a.worst)
}
popcount64 :: proc "contextless" (value: u64) -> int {
	x:=value;count:=0
	for x!=0 {x&=x-1;count+=1}
	return count
}
preferable :: proc "contextless" (a,b: Metrics) -> bool {
	c:=compare(a.maximum,b.maximum)
	if c!=0 do return c<0
	x,y:=popcount64(a.worst),popcount64(b.worst)
	return x<y || (x==y && a.worst<b.worst)
}
enumerate :: proc "contextless" (p: []Point,n: int,out: []Triangulation) -> int {
	da,db:=[MAX_DIAG]int{};m:=0
	for a:=0;a<n;a+=1 {for b:=a+2;b<n;b+=1 {if a==0&&b==n-1 do continue;da[m]=a;db[m]=b;m+=1}}
	boundary:u64=0
	for a:=0;a<n;a+=1 {boundary|=edge_bit(a,(a+1)%n)}
	total:=0
	for mask:=0;mask<(1<<m);mask+=1 {
		count:=0;for i:=0;i<m;i+=1 {if ((mask>>i)&1)!=0 do count+=1}
		if count!=n-3 do continue
		crossing:=false
		for i:=0;i<m&&!crossing;i+=1 {if ((mask>>i)&1)==0 do continue;for j:=i+1;j<m;j+=1 {if ((mask>>j)&1)!=0 && proper_cross(p,da[i],db[i],da[j],db[j]) {crossing=true;break}}}
		if crossing do continue
		edges:=boundary;for i:=0;i<m;i+=1 {if ((mask>>i)&1)!=0 do edges|=edge_bit(da[i],db[i])}
		faces:=[MAX_TRI]Triangle{};nf:=0
		for a:=0;a<n;a+=1 {for b:=a+1;b<n;b+=1 {for cidx:=b+1;cidx<n;cidx+=1 {
			if (edges&edge_bit(a,b))==0 || (edges&edge_bit(b,cidx))==0 || (edges&edge_bit(cidx,a))==0 do continue
			contains:=false
			for v:=0;v<n;v+=1 {if v!=a&&v!=b&&v!=cidx&&inside_triangle(p,Triangle{a,b,cidx},v) {contains=true;break}}
			if !contains&&nf<MAX_TRI {faces[nf]=Triangle{a,b,cidx};nf+=1}
	}}}
		if nf==n-2&&total<MAX_ALL {out[total]=Triangulation{faces,nf,edges};total+=1}
	}
	return total
}
rank_score :: proc "contextless" (p: []Point,n: int,target: Fraction) -> i64 {
	seen:=[MAX_TRIPLES]Fraction{};count:=0
	for a:=0;a<n;a+=1 {for b:=a+1;b<n;b+=1 {for cidx:=b+1;cidx<n;cidx+=1 {
		sides:=[3]i64{};s:=triangle_score(p,Triangle{a,b,cidx},sides[:]);if compare(s,target)>=0 do continue
		duplicate:=false;for i:=0;i<count;i+=1 {if compare(s,seen[i])==0 {duplicate=true;break}}
		if !duplicate {seen[count]=s;count+=1}
	}}}
	return i64(count+1)
}
solve :: proc "contextless" (p: []Point,n: int) -> i64 {
	all:=[MAX_ALL]Triangulation{};total:=enumerate(p,n,all[:]);fan:=Triangulation{}
	for k:=1;k<n-1;k+=1 {fan.triangles[fan.count]=Triangle{0,k,k+1};fan.count+=1}
	for a:=0;a<n;a+=1 {fan.edges|=edge_bit(a,(a+1)%n)};for k:=2;k<n-1;k+=1 {fan.edges|=edge_bit(0,k)}
	index:=-1;for i:=0;i<total;i+=1 {if all[i].edges==fan.edges {index=i;break}};if index<0 do return -1
	current:=all[index];cm:=evaluate(p,n,current)
	for step:=0;step<MAX_ALL;step+=1 {
		changed:=false
		for ti:=0;ti<current.count&&!changed;ti+=1 {
			t:=current.triangles[ti];sides:=[3]i64{};score:=triangle_score(p,t,sides[:]);if compare(score,cm.maximum)!=0||score.num==0 do continue
			largest:=0;if sides[1]>sides[largest] do largest=1;if sides[2]>sides[largest] do largest=2
			vertices:=[3]int{t.a,t.b,t.c}
			for ap:=0;ap<3&&!changed;ap+=1 {if sides[ap]!=sides[largest] do continue;q:=vertices[ap];opposite:=[2]int{};used:=0;for k:=0;k<3;k+=1 {if k!=ap {opposite[used]=vertices[k];used+=1}}
				for s:=0;s<n&&!changed;s+=1 {added:=edge_bit(q,s);if s==q||(current.edges&added)!=0||!proper_cross(p,q,s,opposite[0],opposite[1]) do continue;retained:=current.edges
					for u:=0;u<n;u+=1 {for v:=u+1;v<n;v+=1 {bit:=edge_bit(u,v);if (retained&bit)!=0&&proper_cross(p,q,s,u,v) do retained&=~bit}}
					selected:=-1;selected_metrics:=Metrics{Fraction{0,1},0}
					for ci:=0;ci<total;ci+=1 {if (all[ci].edges&added)==0||(all[ci].edges&retained)!=retained do continue;candidate:=evaluate(p,n,all[ci]);if !improves(candidate,cm) do continue;if selected<0||preferable(candidate,selected_metrics) {selected=ci;selected_metrics=candidate}}
					if selected>=0 {current=all[selected];cm=selected_metrics;changed=true}
				}
			}
		}
		if !changed do break
	}
	return rank_score(p,n,cm.maximum)
}

@(export)
convex_polygon_minimax_eccentricity_edge_insertion :: proc "c" (input: [^]i64,length: c.size_t)->i64 {
	if input==nil||length<1||length>c.size_t(MAX_LEN) do return -1
	if input[0]<MIN_N||input[0]>MAX_N do return -1
	n:=int(input[0]);if length!=c.size_t(1+2*n) do return -1
	points:=[MAX_N]Point{}
	for i:=0;i<n;i+=1 {points[i]=Point{input[1+2*i],input[2+2*i]};if points[i].x < -4||points[i].x>4||points[i].y < -4||points[i].y>4 do return -1;for j:=0;j<i;j+=1 {if points[i].x==points[j].x&&points[i].y==points[j].y do return -1}}
	area2:i64=0;for i:=0;i<n;i+=1 {next:=(i+1)%n;area2+=points[i].x*points[next].y-points[i].y*points[next].x};if area2==0 do return -1
	direction:=i64(1);if area2<0 do direction=-1
	for a:=0;a<n;a+=1 {for b:=a+1;b<n;b+=1 {for cidx:=b+1;cidx<n;cidx+=1 {if orient(points[a],points[b],points[cidx])==0 do return -1}}}
	for edge:=0;edge<n;edge+=1 {next:=(edge+1)%n;for v:=0;v<n;v+=1 {if v!=edge&&v!=next&&direction*orient(points[edge],points[next],points[v])<=0 do return -1}}
	return solve(points[:],n)
}
