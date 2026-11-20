module convex_polygon_minimax_eccentricity_edge_insertion

const min_n=3
const max_n=6
const max_length=14
const max_tri=4
const max_all=14
const max_diag=9
const max_triples=20

struct Point { x i64; y i64 }
struct Triangle { a int; b int; c int }
struct Triangulation { triangles [max_tri]Triangle; count int; edges u64 }
struct Fraction { num i64; den i64 }
struct Metrics { maximum Fraction; worst u64 }

fn orient(a Point,b Point,c Point) i64 { return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x) }
fn gcd64(a0 i64,b0 i64) i64 { mut a:=a0;mut b:=b0;for b!=0{r:=a%b;a=b;b=r};return a }
fn fraction(num i64,den i64) Fraction { g:=gcd64(num,den);return Fraction{num/g,den/g} }
fn compare(a Fraction,b Fraction) int { x,y:=a.num*b.den,b.num*a.den;if x<y{return -1};if x>y{return 1};return 0 }
fn edge_bit(a int,b int) u64 { lo,hi:=if a<b{a}else{b},if a<b{b}else{a};return u64(1)<<(lo*max_n+hi) }
fn crosses(p [max_n]Point,a int,b int,c int,d int) bool { return orient(p[a],p[b],p[c])*orient(p[a],p[b],p[d])<0&&orient(p[c],p[d],p[a])*orient(p[c],p[d],p[b])<0 }
fn inside(p [max_n]Point,t Triangle,v int) bool { dir:=orient(p[t.a],p[t.b],p[t.c]);return orient(p[t.a],p[t.b],p[v])*dir>0&&orient(p[t.b],p[t.c],p[v])*dir>0&&orient(p[t.c],p[t.a],p[v])*dir>0 }

fn triangle_score(p [max_n]Point,t Triangle,mut sides [3]i64) Fraction {
	a,b,c:=p[t.a],p[t.b],p[t.c]
	sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y)
	sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y)
	sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
	mut largest:=0;if sides[1]>sides[largest]{largest=1};if sides[2]>sides[largest]{largest=2}
	other:=sides[0]+sides[1]+sides[2]-sides[largest];if sides[largest]<=other{return Fraction{0,1}}
	mut area:=orient(a,b,c);if area<0{area = -area};diff:=sides[largest]-other
	return fraction(sides[largest]*diff*diff,16*area*area)
}
fn triangle_id(a int,b int,c int,n int) int { mut id:=0;for x in 0..n{for y in x+1..n{for z in y+1..n{if x==a&&y==b&&z==c{return id};id++}}};return 0 }
fn evaluate(p [max_n]Point,n int,t Triangulation) Metrics {
	mut result:=Metrics{maximum:Fraction{0,1},worst:0}
	for i in 0..t.count{mut sides:=[3]i64{};score:=triangle_score(p,t.triangles[i],mut sides);cmp:=compare(score,result.maximum);bit:=u64(1)<<triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n);if cmp>0{result.maximum=score;result.worst=bit}else if cmp==0{result.worst|=bit}}
	return result
}
fn improves(a Metrics,b Metrics) bool { cmp:=compare(a.maximum,b.maximum);return cmp<0||(cmp==0&&a.worst!=b.worst&&(a.worst&b.worst)==a.worst) }
fn popcount(value u64) int { mut bits:=value;mut count:=0;for bits!=0{bits&=bits-1;count++};return count }
fn preferable(a Metrics,b Metrics) bool { cmp:=compare(a.maximum,b.maximum);if cmp!=0{return cmp<0};x,y:=popcount(a.worst),popcount(b.worst);return x<y||(x==y&&a.worst<b.worst) }

fn enumerate(p [max_n]Point,n int,mut out [max_all]Triangulation) int {
	mut da:=[max_diag]int{};mut db:=[max_diag]int{};mut m:=0
	for a in 0..n{for b in a+2..n{if a==0&&b==n-1{continue};da[m]=a;db[m]=b;m++}}
	mut boundary:=u64(0);for a in 0..n{boundary|=edge_bit(a,(a+1)%n)}
	mut total:=0
	for mask in 0..(1<<m){mut count:=0;for i in 0..m{if ((mask>>i)&1)!=0{count++}};if count!=n-3{continue}
		mut crossing:=false;for i in 0..m{if crossing{break};if ((mask>>i)&1)==0{continue};for j in i+1..m{if ((mask>>j)&1)!=0&&crosses(p,da[i],db[i],da[j],db[j]){crossing=true;break}}};if crossing{continue}
		mut edges:=boundary;for i in 0..m{if ((mask>>i)&1)!=0{edges|=edge_bit(da[i],db[i])}}
		mut faces:=[max_tri]Triangle{};mut nf:=0
		for a in 0..n{for b in a+1..n{for c in b+1..n{if (edges&edge_bit(a,b))==0||(edges&edge_bit(b,c))==0||(edges&edge_bit(c,a))==0{continue};mut contains:=false;for v in 0..n{if v!=a&&v!=b&&v!=c&&inside(p,Triangle{a,b,c},v){contains=true;break}};if !contains&&nf<max_tri{faces[nf]=Triangle{a,b,c};nf++}}}}
		if nf==n-2&&total<max_all{out[total]=Triangulation{triangles:faces,count:nf,edges:edges};total++}
	}
	return total
}
fn rank_score(p [max_n]Point,n int,target Fraction) i64 {
	mut seen:=[max_triples]Fraction{};mut count:=0
	for a in 0..n{for b in a+1..n{for c in b+1..n{mut sides:=[3]i64{};score:=triangle_score(p,Triangle{a,b,c},mut sides);if compare(score,target)>=0{continue};mut duplicate:=false;for i in 0..count{if compare(score,seen[i])==0{duplicate=true;break}};if !duplicate{seen[count]=score;count++}}}}
	return i64(count+1)
}
fn solve(p [max_n]Point,n int) i64 {
	mut all:=[max_all]Triangulation{};total:=enumerate(p,n,mut all);mut fan:=Triangulation{}
	for k in 1..n-1{fan.triangles[fan.count]=Triangle{0,k,k+1};fan.count++};for a in 0..n{fan.edges|=edge_bit(a,(a+1)%n)};for k in 2..n-1{fan.edges|=edge_bit(0,k)}
	mut index:=-1;for i in 0..total{if all[i].edges==fan.edges{index=i;break}};if index<0{return -1}
	mut current:=all[index];mut cm:=evaluate(p,n,current)
	for _ in 0..max_all{mut changed:=false;for ti in 0..current.count{if changed{break};t:=current.triangles[ti];mut sides:=[3]i64{};score:=triangle_score(p,t,mut sides);if compare(score,cm.maximum)!=0||score.num==0{continue};mut largest:=0;if sides[1]>sides[largest]{largest=1};if sides[2]>sides[largest]{largest=2};vertices:=[3]int{t.a,t.b,t.c}
		for ap in 0..3{if changed{break};if sides[ap]!=sides[largest]{continue};q:=vertices[ap];mut opposite:=[2]int{};mut used:=0;for k in 0..3{if k!=ap{opposite[used]=vertices[k];used++}};for s in 0..n{if changed{break};added:=edge_bit(q,s);if s==q||(current.edges&added)!=0||!crosses(p,q,s,opposite[0],opposite[1]){continue};mut retained:=current.edges;for u in 0..n{for v in u+1..n{bit:=edge_bit(u,v);if (retained&bit)!=0&&crosses(p,q,s,u,v){retained&=~bit}}};mut selected:=-1;mut sm:=Metrics{maximum:Fraction{0,1},worst:0};for ci in 0..total{if (all[ci].edges&added)==0||(all[ci].edges&retained)!=retained{continue};candidate:=evaluate(p,n,all[ci]);if !improves(candidate,cm){continue};if selected<0||preferable(candidate,sm){selected=ci;sm=candidate}};if selected>=0{current=all[selected];cm=sm;changed=true}}}
	};if !changed{break}}
	return rank_score(p,n,cm.maximum)
}

@[export: 'convex_polygon_minimax_eccentricity_edge_insertion']
pub fn convex_polygon_minimax_eccentricity_edge_insertion(input &i64,length usize) i64 {
	unsafe {
		if input==nil||length<1||length>max_length{return -1};if input[0]<min_n||input[0]>max_n{return -1};n:=int(input[0]);if length!=usize(1+2*n){return -1}
		mut points:=[max_n]Point{};for i in 0..n{points[i]=Point{x:input[1+2*i],y:input[2+2*i]};if points[i].x < -4||points[i].x>4||points[i].y < -4||points[i].y>4{return -1};for j in 0..i{if points[i].x==points[j].x&&points[i].y==points[j].y{return -1}}}
		mut area:=i64(0);for i in 0..n{next:=(i+1)%n;area+=points[i].x*points[next].y-points[i].y*points[next].x};if area==0{return -1};direction:=if area>0{i64(1)}else{i64(-1)}
		for a in 0..n{for b in a+1..n{for c in b+1..n{if orient(points[a],points[b],points[c])==0{return -1}}}}
		for edge in 0..n{next:=(edge+1)%n;for v in 0..n{if v!=edge&&v!=next&&direction*orient(points[edge],points[next],points[v])<=0{return -1}}}
		return solve(points,n)
	}
}
