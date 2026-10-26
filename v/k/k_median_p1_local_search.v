const km_n = 12
const km_k = 4
fn km_put64(mut out &u8, at int, x i64) { b := u64(x); for i in 0 .. 8 { unsafe { out[at+i] = u8((b >> (8*i)) & 255) } } }
fn km_objective(d []i64, n int, centers []int) i64 { mut total := i64(0); for i in 0 .. n { mut best := i64(9223372036854775807); for c in centers { best = if d[i*km_n+c] < best { d[i*km_n+c] } else { best } }; total += best }; return total }
fn km_less(a []int,b []int) bool { for i in 0 .. a.len { if a[i]!=b[i] { return a[i]<b[i] } }; return false }
fn km_sort(mut a []int) { for i in 1 .. a.len { x:=a[i]; mut j:=i; for j>0 && a[j-1]>x { a[j]=a[j-1]; j-- }; a[j]=x } }
@[export: 'k_median_p1_local_search']
pub fn k_median_p1_local_search(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input==nil || length<2 || length>150 { return -1 }
		n64:=input[0]; k64:=input[1]
		if n64<2 || n64>km_n || k64<1 || k64>km_k || k64>n64 || length!=usize(2+n64*n64+k64) { return -1 }
		n:=int(n64); k:=int(k64); mut d:=[]i64{len:144,init:0}; mut p:=2
		for i in 0 .. n { for j in 0 .. n { x:=input[p]; p++; if x<0 || x>1000 { return -1 }; d[i*km_n+j]=x } }
		for i in 0 .. n { for j in 0 .. n { x:=d[i*km_n+j]; if x!=(if i==j { i64(0) } else { x }) || x!=d[j*km_n+i] || (i!=j && x==0) { return -1 }; for h in 0 .. n { if x>d[i*km_n+h]+d[h*km_n+j] { return -1 } } } }
		mut selected:=[]bool{len:km_n,init:false}; mut centers:=[]int{len:k,init:0}
		for j in 0 .. k { x:=input[p]; p++; if x<0 || x>=n64 || selected[int(x)] { return -1 }; centers[j]=int(x); selected[int(x)]=true }
		km_sort(mut centers); mut current:=km_objective(d,n,centers)
		for { mut best:=current; mut bestc:=centers.clone(); mut have:=false; for leave in 0 .. k { for enter in 0 .. n { if selected[enter] { continue }; mut cand:=centers.clone(); cand[leave]=enter; km_sort(mut cand); value:=km_objective(d,n,cand); if value<current && (value<best || (value==best && (!have || km_less(cand,bestc)))) { best=value; bestc=cand; have=true } } }; if !have { break }; for c in centers { selected[c]=false }; centers=bestc; for c in centers { selected[c]=true }; current=best }
		bytes:=8*(2+k); if output==nil || capacity<usize(bytes) { return -2 }; km_put64(mut output,0,current); km_put64(mut output,8,k); for i in 0 .. k { km_put64(mut output,16+8*i,centers[i]) }; return i64(bytes)
	}
}
