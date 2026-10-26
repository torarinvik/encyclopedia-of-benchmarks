package tsp_few_inner_points

import "core:c"

Point :: struct { x, y: i64 }
INF :: i64(2305843009213693951)

distance_scaled :: proc(a, b: Point) -> i64 {
	dx, dy := a.x-b.x, a.y-b.y
	sq := (dx*dx+dy*dy)*1_000_000
	lo, hi := i64(0), i64(3_000_000)
	for lo < hi { mid := lo+(hi-lo+1)/2; if mid*mid <= sq { lo=mid } else { hi=mid-1 } }
	up:=lo+1
	if up*up-sq < sq-lo*lo do return up
	return lo
}
add_cost :: proc(a,b:i64)->i64 { if a>=INF do return INF; return a+b }

solve_order :: proc(outer: [16]int, outer_n:int, order:[6]int, k:int, points:[16]Point)->i64 {
	po,pi,co,ci:[7]i64
	for j:=0;j<=k;j+=1 { po[j]=INF;pi[j]=INF };po[0]=0
	for j:=1;j<=k;j+=1 { a:=add_cost(po[j-1],distance_scaled(points[outer[0]],points[order[j-1]]));b:=INF;if j>1 { b=add_cost(pi[j-1],distance_scaled(points[order[j-2]],points[order[j-1]])) };if a<b {pi[j]=a}else{pi[j]=b} }
	for i:=1;i<outer_n;i+=1 {
		for j:=0;j<=k;j+=1 {co[j]=INF;ci[j]=INF};edge:=distance_scaled(points[outer[i-1]],points[outer[i]]);co[0]=add_cost(po[0],edge)
		for j:=1;j<=k;j+=1 {a:=add_cost(po[j],edge);b:=add_cost(pi[j],distance_scaled(points[order[j-1]],points[outer[i]]));if a<b{co[j]=a}else{co[j]=b}}
		for j:=1;j<=k;j+=1 {a:=add_cost(co[j-1],distance_scaled(points[outer[i]],points[order[j-1]]));b:=INF;if j>1{b=add_cost(ci[j-1],distance_scaled(points[order[j-2]],points[order[j-1]]))};if a<b{ci[j]=a}else{ci[j]=b}}
		for j:=0;j<=k;j+=1 {po[j]=co[j];pi[j]=ci[j]}
	}
	best:=add_cost(po[k],distance_scaled(points[outer[outer_n-1]],points[outer[0]]));if k>0{close:=add_cost(pi[k],distance_scaled(points[order[k-1]],points[outer[0]]));if close<best{best=close}};return best
}
next_perm :: proc(a: ^[6]int,n:int)->bool {
	if n<2 do return false
	i:=n-2;for i>=0 && a[i]>=a[i+1] {i-=1};if i<0 do return false
	j:=n-1;for a[j]<=a[i] {j-=1};a[i],a[j]=a[j],a[i]
	l,r:=i+1,n-1;for l<r {a[l],a[r]=a[r],a[l];l+=1;r-=1};return true
}
put_i64 :: proc(out:[^]u8,x:i64){bits:=cast(u64)x;for i:=0;i<8;i+=1{out[i]=u8((bits>>u64(8*i))&255)}}

tsp_few_inner_points :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil || length<2 || length>51 do return -1
	n0,k0:=input[0],input[1];if n0<3 || n0>16 || k0<0 || k0>6 || k0>n0-3 || length!=c.size_t(2+3*n0) do return -1
	n,k,on:=int(n0),int(k0),int(n0-k0);outer:[16]int;inner:[6]int;seen:[16]bool
	for i:=0;i<on;i+=1 {id:=input[2+i];if id<0 || id>=n0 || seen[int(id)] do return -1;outer[i]=int(id);seen[int(id)]=true}
	for i:=0;i<k;i+=1 {id:=input[2+on+i];if id<0 || id>=n0 || seen[int(id)] do return -1;inner[i]=int(id);seen[int(id)]=true}
	for i:=0;i<n;i+=1 {if !seen[i] do return -1}
	points:[16]Point;off:=2+n
	for i:=0;i<n;i+=1 {x,y:=input[off+2*i],input[off+2*i+1];if x< -1000 || x>1000 || y< -1000 || y>1000 do return -1;for j:=0;j<i;j+=1{if points[j].x==x && points[j].y==y do return -1};points[i]=Point{x,y}}
	for i:=1;i<k;i+=1{x:=inner[i];j:=i;for j>0 && inner[j-1]>x{inner[j]=inner[j-1];j-=1};inner[j]=x}
	best:=INF;for {v:=solve_order(outer,on,inner,k,points);if v<best{best=v};if !next_perm(&inner,k){break}}
	if output==nil || capacity<8 do return -2;put_i64(output,best);return 8
}
