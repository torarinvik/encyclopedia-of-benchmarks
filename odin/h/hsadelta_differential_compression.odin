package hsadelta_differential_compression

import "core:c"

MAX_LEN :: 32
MAX_BLOCKS :: 16
MAX_WORDS :: 114
MAX_BYTES :: 912
MAX_INPUT :: 68

block_hash :: proc(data: [^]i64, start, width: int) -> i64 {
	value: i64 = 0
	for i := 0; i < width; i += 1 { value = value * 257 + data[start+i] + 1 }
	return value
}
suffix_cmp :: proc(h: [MAX_BLOCKS]i64, count, a0, b0: int) -> int {
	a, b := a0, b0
	for a < count && b < count {
		if h[a] != h[b] do return if h[a] < h[b] then -1 else 1
		a += 1; b += 1
	}
	if a == count && b == count do return 0
	return if a == count then -1 else 1
}
prefix_cmp :: proc(h: [MAX_BLOCKS]i64, count, suffix: int, q: [MAX_BLOCKS]i64, depth: int) -> int {
	for i := 0; i < depth; i += 1 {
		if suffix+i >= count do return -1
		if h[suffix+i] != q[i] do return if h[suffix+i] < q[i] then -1 else 1
	}
	return 0
}
interval :: proc(sa: [MAX_BLOCKS]int, count: int, h, q: [MAX_BLOCKS]i64, depth: int) -> (int, int) {
	lo, hi := 0, count
	for lo < hi { mid := lo+(hi-lo)/2; if prefix_cmp(h,count,sa[mid],q,depth)<0 do lo=mid+1 else hi=mid }
	first := lo; hi=count
	for lo < hi { mid := lo+(hi-lo)/2; if prefix_cmp(h,count,sa[mid],q,depth)<=0 do lo=mid+1 else hi=mid }
	return first, lo
}
best_depth :: proc(sa: [MAX_BLOCKS]int, count: int, h, q: [MAX_BLOCKS]i64, qcount: int) -> int {
	lo, hi := 0, min(count,qcount)+1
	for lo+1 < hi { mid:=lo+(hi-lo)/2; first,last:=interval(sa,count,h,q,mid); if first<last do lo=mid else hi=mid }
	return lo
}
Match :: struct { source, target, length: int }
extend :: proc(ref, ver: [^]i64, m,n, source0,target0,floor: int) -> Match {
	source,target,length:=source0,target0,0
	for source+length<m && target+length<n && ref[source+length]==ver[target+length] { length+=1 }
	for source>0 && target>floor && ref[source-1]==ver[target-1] { source-=1; target-=1; length+=1 }
	return Match{source,target,length}
}
better :: proc(a,b: Match) -> bool { return a.length>b.length || (a.length==b.length && (a.target<b.target || (a.target==b.target && a.source<b.source))) }
store_i64 :: proc(out: [^]u8, offset: int, value: i64) {
	bits:=u64(value)
	for b:=0;b<8;b+=1 { out[offset+b]=u8((bits>>(8*b))&255) }
}

@(export)
hsadelta_differential_compression :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<3 || length>c.size_t(MAX_INPUT) do return -1
	mv,nv,pv:=input[0],input[1],input[2]
	if mv<0 || mv>MAX_LEN || nv<0 || nv>MAX_LEN || pv<2 || pv>4 do return -1
	m,n,p:=int(mv),int(nv),int(pv)
	if length!=c.size_t(3+m+n) do return -1
	for i:=0;i<m+n;i+=1 { if input[3+i]<0 || input[3+i]>255 do return -1 }
	var ref_storage: [MAX_LEN]i64
	var ver_storage: [MAX_LEN]i64
	for i:=0;i<m;i+=1 { ref_storage[i]=input[3+i] }
	for i:=0;i<n;i+=1 { ver_storage[i]=input[3+m+i] }
	ref,ver:=&ref_storage[0],&ver_storage[0]
	var hashes: [MAX_BLOCKS]i64
	var sa: [MAX_BLOCKS]int
	count:=0
	if m>=p { count=(m-p)/p+1 }
	for i:=0;i<count;i+=1 { hashes[i]=block_hash(ref,i*p,p); sa[i]=i }
	for i:=1;i<count;i+=1 { value:=sa[i]; j:=i; for j>0 && (suffix_cmp(hashes,count,value,sa[j-1])<0 || (suffix_cmp(hashes,count,value,sa[j-1])==0 && value<sa[j-1])) { sa[j]=sa[j-1]; j-=1 }; sa[j]=value }
	var tokens: [MAX_WORDS]i64
	words,cursor,consumed:=0,0,0
	for cursor+p<=n {
		found:=false; best:=Match{}
		scan_end:=min(cursor+p-1,n-p)
		for target:=cursor;target<=scan_end;target+=1 {
			qcount:=(n-target)/p
			if qcount==0 || count==0 do continue
			var query: [MAX_BLOCKS]i64
			for i:=0;i<qcount;i+=1 { query[i]=block_hash(ver,target+i*p,p) }
			depth:=best_depth(sa,count,hashes,query,qcount)
			if depth==0 do continue
			first,last:=interval(sa,count,hashes,query,max(1,depth-1))
			for rank:=first;rank<last;rank+=1 {
				source:=sa[rank]*p
				if source+p>m do continue
				candidate:=extend(ref,ver,m,n,source,target,consumed)
				if candidate.length<p do continue
				if !found || better(candidate,best) { found=true; best=candidate }
			}
		}
		if !found { cursor+=1; continue }
		if best.target>consumed { tokens[words]=0; words+=1; tokens[words]=i64(best.target-consumed); words+=1; for i:=consumed;i<best.target;i+=1 { tokens[words]=ver[i]; words+=1 } }
		tokens[words]=1; words+=1; tokens[words]=i64(best.source); words+=1; tokens[words]=i64(best.length); words+=1
		consumed=best.target+best.length; cursor=consumed
	}
	if consumed<n { tokens[words]=0; words+=1; tokens[words]=i64(n-consumed); words+=1; for i:=consumed;i<n;i+=1 { tokens[words]=ver[i]; words+=1 } }
	required:=words*8
	if required>0 && (output==nil || capacity<c.size_t(required)) do return -2
	for i:=0;i<words;i+=1 { store_i64(output,8*i,tokens[i]) }
	return i64(required)
}
