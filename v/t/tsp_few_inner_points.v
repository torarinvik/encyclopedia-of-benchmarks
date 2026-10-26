module tsp_few_inner_points

struct Point { x i64; y i64 }
const inf = i64(2305843009213693951)

fn distance_scaled(a Point,b Point) i64 {
	dx:=a.x-b.x;dy:=a.y-b.y;sq:=(dx*dx+dy*dy)*1_000_000
	mut lo:=i64(0);mut hi:=i64(3_000_000)
	for lo<hi { mid:=lo+(hi-lo+1)/2;if mid*mid<=sq{lo=mid}else{hi=mid-1} }
	up:=lo+1
	if up*up-sq<sq-lo*lo{return up};return lo
}
fn add_cost(a i64,b i64) i64 { if a>=inf{return inf};return a+b }

fn solve_order(outer []int,order []int,points []Point) i64 {
	k:=order.len;mut po:=[]i64{len:7,init:inf};mut pi:=[]i64{len:7,init:inf};po[0]=0
	for j:=1;j<=k;j++ { a:=add_cost(po[j-1],distance_scaled(points[outer[0]],points[order[j-1]]));mut b:=inf;if j>1{b=add_cost(pi[j-1],distance_scaled(points[order[j-2]],points[order[j-1]]))};pi[j]=if a<b{a}else{b} }
	for i:=1;i<outer.len;i++ {
		mut co:=[]i64{len:7,init:inf};mut ci:=[]i64{len:7,init:inf};edge:=distance_scaled(points[outer[i-1]],points[outer[i]]);co[0]=add_cost(po[0],edge)
		for j:=1;j<=k;j++ {a:=add_cost(po[j],edge);b:=add_cost(pi[j],distance_scaled(points[order[j-1]],points[outer[i]]));co[j]=if a<b{a}else{b}}
		for j:=1;j<=k;j++ {a:=add_cost(co[j-1],distance_scaled(points[outer[i]],points[order[j-1]]));mut b:=inf;if j>1{b=add_cost(ci[j-1],distance_scaled(points[order[j-2]],points[order[j-1]]))};ci[j]=if a<b{a}else{b}}
		po=co;pi=ci
	}
	mut best:=add_cost(po[k],distance_scaled(points[outer[outer.len-1]],points[outer[0]]));if k>0{close:=add_cost(pi[k],distance_scaled(points[order[k-1]],points[outer[0]]));if close<best{best=close}};return best
}
fn next_perm(mut a []int) bool {
	if a.len<2{return false};mut i:=a.len-2;for i>=0 && a[i]>=a[i+1]{i--};if i<0{return false};mut j:=a.len-1;for a[j]<=a[i]{j--};a[i],a[j]=a[j],a[i];mut l:=i+1;mut r:=a.len-1;for l<r{a[l],a[r]=a[r],a[l];l++;r--};return true
}
fn put_word(mut output &u8,x i64){bits:=u64(x);for i in 0..8{unsafe{output[i]=u8((bits>>u64(8*i))&255)}}}

@[export:'tsp_few_inner_points']
pub fn tsp_few_inner_points(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if input==nil || length<2 || length>51{return -1}
	unsafe {
		n0,k0:=input[0],input[1];if n0<3 || n0>16 || k0<0 || k0>6 || k0>n0-3 || length!=usize(2+3*n0){return -1}
		n,k,on:=int(n0),int(k0),int(n0-k0);mut outer:=[]int{len:on,init:0};mut inner:=[]int{len:k,init:0};mut seen:=[]bool{len:16,init:false}
		for i in 0..on{id:=input[2+i];if id<0 || id>=n0 || seen[int(id)]{return -1};outer[i]=int(id);seen[int(id)]=true}
		for i in 0..k{id:=input[2+on+i];if id<0 || id>=n0 || seen[int(id)]{return -1};inner[i]=int(id);seen[int(id)]=true}
		for i in 0..n{if !seen[i]{return -1}}
		mut points:=[]Point{len:n,init:Point{0,0}};off:=2+n
		for i in 0..n{x,y:=input[off+2*i],input[off+2*i+1];if x< -1000 || x>1000 || y< -1000 || y>1000{return -1};for j in 0..i{if points[j].x==x && points[j].y==y{return -1}};points[i]=Point{x,y}}
		for i in 1..k{x:=inner[i];mut j:=i;for j>0 && inner[j-1]>x{inner[j]=inner[j-1];j--};inner[j]=x}
		mut best:=inf;for{v:=solve_order(outer,inner,points);if v<best{best=v};if !next_perm(mut inner){break}}
		if output==nil || capacity<8{return -2};put_word(mut output,best);return 8
	}
}
