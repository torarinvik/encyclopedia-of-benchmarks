package bankers_algorithm_python_demo
import "core:c"
MAX_N :: 16
MAX_M :: 8

@(export)
bankers_algorithm_python_demo :: proc "c" (v: [^]i64, length: c.size_t) -> i64 {
	if v == nil || length < 5 || length > 266 do return -1
	if v[0] < 1 || v[0] > MAX_N || v[1] < 1 || v[1] > MAX_M do return -1
	n := int(v[0]); m := int(v[1]); aoff := 2+m; moff := aoff+n*m
	if length != c.size_t(moff+n*m) do return -1
	work: [MAX_M]i64
	for r:=0;r<m;r+=1 { x:=v[2+r]; if x<0||x>100 do return -1; work[r]=x }
	for p:=0;p<n;p+=1 { for r:=0;r<m;r+=1 { i:=p*m+r; a:=v[aoff+i]; x:=v[moff+i]; if a<0||a>100||x<0||x>100||a>x do return -1; work[r]-=a } }
	for r:=0;r<m;r+=1 { if work[r]<0 do return -1 }
	first: [MAX_N]int
	remaining: [MAX_N]int
	for p:=0;p<n;p+=1 {
		first[p]=p; remaining[p]=p
		for q:=0;q<p;q+=1 {
			equal:=true
			for r:=0;r<m;r+=1 { pi:=p*m+r; qi:=q*m+r; if v[moff+pi]-v[aoff+pi] != v[moff+qi]-v[aoff+qi] { equal=false; break } }
			if equal { first[p]=first[q]; break }
		}
	}
	count:=n
	for count>0 {
		selected:=count
		for i:=0;i<count;i+=1 { p:=remaining[i]; feasible:=true; for r:=0;r<m;r+=1 { j:=p*m+r; if v[moff+j]-v[aoff+j]>work[r] { feasible=false;break } }; if feasible {selected=i;break} }
		if selected==count do return 0
		mapped:=first[remaining[selected]]
		for r:=0;r<m;r+=1 { work[r]+=v[aoff+mapped*m+r] }
		for i:=selected+1;i<count;i+=1 { remaining[i-1]=remaining[i] }
		count-=1
	}
	return 1
}
