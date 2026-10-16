fn next_rng(mut state u32) u32 { mut x := state; x ^= x << 13; x ^= x >> 17; x ^= x << 5; state = if x == 0 { u32(0x9e3779b9) } else { x }; return state }
fn partition(mut a []i64, lo int, hi int) int { pivot := a[hi]; mut i := lo; for j in lo .. hi { if a[j] <= pivot { a[i], a[j] = a[j], a[i]; i++ } }; a[i], a[hi] = a[hi], a[i]; return i }
fn select_k(mut a []i64, lo int, hi int, k int, mut state u32) i64 { if lo == hi { return a[lo] }; p := lo + int(next_rng(mut state) % u32(hi-lo+1)); a[p],a[hi]=a[hi],a[p]; q:=partition(mut a,lo,hi);rank:=q-lo+1;if k==rank{return a[q]};if k<rank{return select_k(mut a,lo,q-1,k,mut state)};return select_k(mut a,q+1,hi,k-rank,mut state) }
@[export: 'minimum_element_of_array']
pub fn minimum_element_of_array(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 4 { return -1 }
	unsafe {
		n:=values[0];k:=values[1];seed:=values[2]
		if n<1||n>128||int(length)!=int(n)+3||k<1||k>n||seed<0||seed>2147483647{return -1}
		mut a:=[]i64{cap:int(n)}
		for i in 0 .. int(n) { x:=values[i+3];if x < -1_000_000 || x > 1_000_000{return -1};for y in a{if y==x{return -1}};a<<x }
		mut state:=if seed==0{u32(0x9e3779b9)}else{u32(seed)}
		return select_k(mut a,0,int(n)-1,int(k),mut state)
	}
}
