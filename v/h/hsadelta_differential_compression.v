const max_len = 32
const max_blocks = 16
const max_words = 114
const max_bytes = 912
const max_input = 68

struct Match {
	source int
	target int
	length int
}

fn block_hash(data []i64, start int, width int) i64 {
	mut value := i64(0)
	for i in 0 .. width { value = value * 257 + data[start+i] + 1 }
	return value
}
fn suffix_cmp(h []i64, a0 int, b0 int) int {
	mut a := a0
	mut b := b0
	for a < h.len && b < h.len {
		if h[a] != h[b] { return if h[a] < h[b] { -1 } else { 1 } }
		a++; b++
	}
	return if a == h.len && b == h.len { 0 } else if a == h.len { -1 } else { 1 }
}
fn prefix_cmp(h []i64, suffix int, q []i64, depth int) int {
	for i in 0 .. depth {
		if suffix+i >= h.len { return -1 }
		if h[suffix+i] != q[i] { return if h[suffix+i] < q[i] { -1 } else { 1 } }
	}
	return 0
}
fn interval(sa []int, h []i64, q []i64, depth int) (int,int) {
	mut lo:=0; mut hi:=sa.len
	for lo<hi { mid:=lo+(hi-lo)/2; if prefix_cmp(h,sa[mid],q,depth)<0 { lo=mid+1 } else { hi=mid } }
	first:=lo; hi=sa.len
	for lo<hi { mid:=lo+(hi-lo)/2; if prefix_cmp(h,sa[mid],q,depth)<=0 { lo=mid+1 } else { hi=mid } }
	return first,lo
}
fn best_depth(sa []int,h []i64,q []i64) int {
	mut lo:=0; mut hi:=if sa.len<q.len { sa.len } else { q.len }
	hi++
	for lo+1<hi { mid:=lo+(hi-lo)/2; first,last:=interval(sa,h,q,mid); if first<last { lo=mid } else { hi=mid } }
	return lo
}
fn extend_match(ref []i64, ver []i64, source0 int, target0 int, floor int) Match {
	mut source:=source0; mut target:=target0; mut length:=0
	for source+length<ref.len && target+length<ver.len && ref[source+length]==ver[target+length] { length++ }
	for source>0 && target>floor && ref[source-1]==ver[target-1] { source--; target--; length++ }
	return Match{source,target,length}
}
fn better(a Match,b Match) bool {
	return a.length>b.length || (a.length==b.length && (a.target<b.target || (a.target==b.target && a.source<b.source)))
}
fn find_at(ref []i64,ver []i64,p int,sa []int,hashes []i64,target int,floor int) ?Match {
	qcount:=(ver.len-target)/p
	if qcount==0 || sa.len==0 { return none }
	mut query:=[]i64{len:qcount}
	for i in 0..qcount { query[i]=block_hash(ver,target+i*p,p) }
	depth:=best_depth(sa,hashes,query)
	if depth==0 { return none }
	first,last:=interval(sa,hashes,query,if depth>1 { depth-1 } else { 1 })
	mut found:=false; mut best:=Match{}
	for rank in first..last {
		source:=sa[rank]*p
		if source+p>ref.len { continue }
		candidate:=extend_match(ref,ver,source,target,floor)
		if candidate.length<p { continue }
		if !found || better(candidate,best) { found=true; best=candidate }
	}
	if found { return best }
	return none
}
fn store_i64(out &u8, at int, value i64) {
	bits:=u64(value)
	unsafe { for b in 0..8 { out[at+b]=u8((bits>>(8*b))&255) } }
}

@[export: 'hsadelta_differential_compression']
pub fn hsadelta_differential_compression(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input==nil || length<3 || length>max_input { return -1 }
		mv:=input[0]; nv:=input[1]; pv:=input[2]
		if mv<0 || mv>max_len || nv<0 || nv>max_len || pv<2 || pv>4 { return -1 }
		m:=int(mv); n:=int(nv); p:=int(pv)
		if length!=usize(3+m+n) { return -1 }
		mut ref:=[]i64{len:m}; mut ver:=[]i64{len:n}
		for i in 0..m { if input[3+i]<0 || input[3+i]>255 { return -1 }; ref[i]=input[3+i] }
		for i in 0..n { if input[3+m+i]<0 || input[3+m+i]>255 { return -1 }; ver[i]=input[3+m+i] }
		block_count:=if m>=p { (m-p)/p+1 } else { 0 }
		mut hashes:=[]i64{len:block_count}; mut sa:=[]int{len:block_count}
		for i in 0..block_count { hashes[i]=block_hash(ref,i*p,p); sa[i]=i }
		for i in 1..block_count { value:=sa[i]; mut j:=i; for j>0 && (suffix_cmp(hashes,value,sa[j-1])<0 || (suffix_cmp(hashes,value,sa[j-1])==0 && value<sa[j-1])) { sa[j]=sa[j-1]; j-- }; sa[j]=value }
		mut tokens:=[]i64{cap:max_words}; mut cursor:=0; mut consumed:=0
		for cursor+p<=n {
			mut found:=false; mut best:=Match{}
			scan_end:=if cursor+p-1<n-p { cursor+p-1 } else { n-p }
			for target in cursor..scan_end+1 {
				candidate:=find_at(ref,ver,p,sa,hashes,target,consumed) or { continue }
				if !found || better(candidate,best) { found=true; best=candidate }
			}
			if !found { cursor++; continue }
			if best.target>consumed { tokens<<0; tokens<<i64(best.target-consumed); for i in consumed..best.target { tokens<<ver[i] } }
			tokens<<1; tokens<<i64(best.source); tokens<<i64(best.length)
			consumed=best.target+best.length; cursor=consumed
		}
		if consumed<n { tokens<<0; tokens<<i64(n-consumed); for i in consumed..n { tokens<<ver[i] } }
		required:=tokens.len*8
		if required>0 && (output==nil || capacity<usize(required)) { return -2 }
		for i,value in tokens { store_i64(output,8*i,value) }
		return i64(required)
	}
}
