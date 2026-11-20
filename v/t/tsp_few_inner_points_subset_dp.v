module tsp_few_inner_points_subset_dp

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

fn solve_subset(outer []int,inner []int,points []Point) i64 {
	k:=inner.len;states:=1<<k;sentinel:=k;mut previous:=[]i64{len:448,init:inf};previous[sentinel]=0
	for mask in 0..states {for last in 0..k+1 {
		if last<k && (mask & (1<<last))==0 {continue}
		prefix:=previous[mask*7+last];if prefix>=inf {continue}
		vertex:=outer[0];if last!=sentinel {vertex=inner[last]}
		for next in 0..k {bit:=1<<next;if (mask & bit)!=0 {continue};next_mask:=mask|bit
			candidate:=add_cost(prefix,distance_scaled(points[vertex],points[inner[next]]));if candidate<previous[next_mask*7+next] {previous[next_mask*7+next]=candidate}
		}
	}}
	for i in 1..outer.len {
		mut current:=[]i64{len:448,init:inf}
		for mask in 0..states {for last in 0..k+1 {
			if last<k && (mask & (1<<last))==0 {continue}
			prefix:=previous[mask*7+last];if prefix>=inf {continue}
			vertex:=outer[i-1];if last!=sentinel {vertex=inner[last]}
			candidate:=add_cost(prefix,distance_scaled(points[vertex],points[outer[i]]));if candidate<current[mask*7+sentinel] {current[mask*7+sentinel]=candidate}
		}}
		for mask in 0..states {for last in 0..k+1 {
			if last<k && (mask & (1<<last))==0 {continue}
			prefix:=current[mask*7+last];if prefix>=inf {continue}
			vertex:=outer[i];if last!=sentinel {vertex=inner[last]}
			for next in 0..k {bit:=1<<next;if (mask & bit)!=0 {continue};next_mask:=mask|bit
				candidate:=add_cost(prefix,distance_scaled(points[vertex],points[inner[next]]));if candidate<current[next_mask*7+next] {current[next_mask*7+next]=candidate}
			}
		}}
		previous=current
	}
	full:=states-1;mut best:=inf
	for last in 0..k+1 {if last<k && (full & (1<<last))==0 {continue};vertex:=outer[outer.len-1];if last!=sentinel {vertex=inner[last]};candidate:=add_cost(previous[full*7+last],distance_scaled(points[vertex],points[outer[0]]));if candidate<best {best=candidate}}
	return best
}
fn put_word(mut output &u8,x i64){bits:=u64(x);for i in 0..8{unsafe{output[i]=u8((bits>>u64(8*i))&255)}}}

@[export:'tsp_few_inner_points_subset_dp']
pub fn tsp_few_inner_points_subset_dp(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if input==nil || length<2 || length>51{return -1}
	unsafe {
		n0,k0:=input[0],input[1];if n0<3 || n0>16 || k0<0 || k0>6 || k0>n0-3 || length!=usize(2+3*n0){return -1}
		n,k,on:=int(n0),int(k0),int(n0-k0);mut outer:=[]int{len:on,init:0};mut inner:=[]int{len:k,init:0};mut seen:=[]bool{len:16,init:false}
		for i in 0..on{id:=input[2+i];if id<0 || id>=n0 || seen[int(id)]{return -1};outer[i]=int(id);seen[int(id)]=true}
		for i in 0..k{id:=input[2+on+i];if id<0 || id>=n0 || seen[int(id)]{return -1};inner[i]=int(id);seen[int(id)]=true}
		for i in 0..n{if !seen[i]{return -1}}
		mut points:=[]Point{len:n,init:Point{0,0}};off:=2+n
		for i in 0..n{x,y:=input[off+2*i],input[off+2*i+1];if x< -1000 || x>1000 || y< -1000 || y>1000{return -1};for j in 0..i{if points[j].x==x && points[j].y==y{return -1}};points[i]=Point{x,y}}
		best:=solve_subset(outer,inner,points)
		if output==nil || capacity<8{return -2};put_word(mut output,best);return 8
	}
}
