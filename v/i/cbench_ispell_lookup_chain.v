module cbench_ispell_lookup_chain

fn ihash(a &i64, start int, size int, modulus int) int {
	mut h := u32(0)
	first := if size < 4 { size } else { 4 }
	for i in 0 .. first { h = (h << 8) | u32(a[start+i]-32) }
	for i in first .. size { h = ((h << 5) | (h >> 27)) ^ u32(a[start+i]-32) }
	return int(h % u32(modulus))
}

@[export: 'cbench_ispell_lookup_chain']
pub fn cbench_ispell_lookup_chain(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 108 { return -1 }
	mut a := [108]i64{}
	unsafe { for i in 0 .. int(length) { a[i] = input[i] } }
	if a[0] < 1 || a[0] > 8 || a[1] < 1 || a[1] > 8 || a[2] < 0 || a[2] > 8 { return -1 }
	m,q,n := int(a[0]),int(a[1]),int(a[2])
	if length < usize(3+q+m+2*n) { return -1 }
	h0,nx0,l0 := 3+q,3+q+m,3+q+m+n
	mut p := l0+n
	for j in 0 .. q { if a[3+j] < 97 || a[3+j] > 122 { return -1 } }
	mut heads := [8]i64{}
	mut next := [8]i64{}
	mut lens := [8]int{}
	mut offs := [8]int{}
	for b in 0 .. m { heads[b]=a[h0+b];if heads[b] < -1 || heads[b] >= n { return -1 } }
	for i in 0 .. n {
		next[i]=a[nx0+i]
		if next[i] < -1 || next[i] >= n || a[l0+i] < 1 || a[l0+i] > 8 { return -1 }
		lens[i]=int(a[l0+i]);if p+lens[i] > int(length) { return -1 };offs[i]=p
		for j in 0 .. lens[i] { if a[p+j] < 97 || a[p+j] > 122 { return -1 } }
		p+=lens[i]
	}
	if p != int(length) { return -1 }
	mut seen := [8]bool{}
	mut count:=0
	for b in 0 .. m { mut x:=heads[b];for x != -1 { i:=int(x);if seen[i] { return -1 };seen[i]=true;count++;if ihash(&a[0],offs[i],lens[i],m) != b { return -1 };x=next[i] } }
	if count != n { return -1 }
	b:=ihash(&a[0],3,q,m);mut x:=heads[b]
	for x != -1 { i:=int(x);if lens[i]==q { mut j:=0;for j<q && a[offs[i]+j]==a[3+j] { j++ };if j==q { return i64(i+1) } };x=next[i] }
	return 0
}
