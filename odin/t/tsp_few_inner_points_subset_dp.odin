package tsp_few_inner_points_subset_dp

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

solve_subset :: proc(outer: [16]int, outer_n:int, inner:[6]int, k:int, points:[16]Point)->i64 {
	states:=1<<k;sentinel:=k;previous,current:[448]i64
	for cell:=0;cell<states*7;cell+=1 {previous[cell]=INF};previous[sentinel]=0
	for mask:=0;mask<states;mask+=1 {for last:=0;last<=k;last+=1 {
		if last<k && (mask&(1<<last))==0 do continue
		prefix:=previous[mask*7+last];if prefix>=INF do continue
		vertex:=outer[0];if last!=sentinel {vertex=inner[last]}
		for next:=0;next<k;next+=1 {bit:=1<<next;if (mask&bit)!=0 do continue;next_mask:=mask|bit
			candidate:=add_cost(prefix,distance_scaled(points[vertex],points[inner[next]]));if candidate<previous[next_mask*7+next] {previous[next_mask*7+next]=candidate}
		}
	}}
	for i:=1;i<outer_n;i+=1 {
		for cell:=0;cell<states*7;cell+=1 {current[cell]=INF}
		for mask:=0;mask<states;mask+=1 {for last:=0;last<=k;last+=1 {
			if last<k && (mask&(1<<last))==0 do continue
			prefix:=previous[mask*7+last];if prefix>=INF do continue
			vertex:=outer[i-1];if last!=sentinel {vertex=inner[last]}
			candidate:=add_cost(prefix,distance_scaled(points[vertex],points[outer[i]]));if candidate<current[mask*7+sentinel] {current[mask*7+sentinel]=candidate}
		}}
		for mask:=0;mask<states;mask+=1 {for last:=0;last<=k;last+=1 {
			if last<k && (mask&(1<<last))==0 do continue
			prefix:=current[mask*7+last];if prefix>=INF do continue
			vertex:=outer[i];if last!=sentinel {vertex=inner[last]}
			for next:=0;next<k;next+=1 {bit:=1<<next;if (mask&bit)!=0 do continue;next_mask:=mask|bit
				candidate:=add_cost(prefix,distance_scaled(points[vertex],points[inner[next]]));if candidate<current[next_mask*7+next] {current[next_mask*7+next]=candidate}
			}
		}}
		for cell:=0;cell<states*7;cell+=1 {previous[cell]=current[cell]}
	}
	full:=states-1;best:=INF
	for last:=0;last<=k;last+=1 {if last<k && (full&(1<<last))==0 do continue;vertex:=outer[outer_n-1];if last!=sentinel {vertex=inner[last]};candidate:=add_cost(previous[full*7+last],distance_scaled(points[vertex],points[outer[0]]));if candidate<best {best=candidate}}
	return best
}
put_i64 :: proc(out:[^]u8,x:i64){bits:=cast(u64)x;for i:=0;i<8;i+=1{out[i]=u8((bits>>u64(8*i))&255)}}

tsp_few_inner_points_subset_dp :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil || length<2 || length>51 do return -1
	n0,k0:=input[0],input[1];if n0<3 || n0>16 || k0<0 || k0>6 || k0>n0-3 || length!=c.size_t(2+3*n0) do return -1
	n,k,on:=int(n0),int(k0),int(n0-k0);outer:[16]int;inner:[6]int;seen:[16]bool
	for i:=0;i<on;i+=1 {id:=input[2+i];if id<0 || id>=n0 || seen[int(id)] do return -1;outer[i]=int(id);seen[int(id)]=true}
	for i:=0;i<k;i+=1 {id:=input[2+on+i];if id<0 || id>=n0 || seen[int(id)] do return -1;inner[i]=int(id);seen[int(id)]=true}
	for i:=0;i<n;i+=1 {if !seen[i] do return -1}
	points:[16]Point;off:=2+n
	for i:=0;i<n;i+=1 {x,y:=input[off+2*i],input[off+2*i+1];if x< -1000 || x>1000 || y< -1000 || y>1000 do return -1;for j:=0;j<i;j+=1{if points[j].x==x && points[j].y==y do return -1};points[i]=Point{x,y}}
	best:=solve_subset(outer,on,inner,k,points)
	if output==nil || capacity<8 do return -2;put_i64(output,best);return 8
}
