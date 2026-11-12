package static_range_lis_query

import "core:c"

MAX_N :: 128
MAX_Q :: 32

lower_bound :: proc "contextless" (tails: [^]i64, count: int, value: i64) -> int {
	lo, hi := 0, count
	for lo < hi {
		mid := lo + (hi-lo)/2
		if tails[mid] < value { lo = mid+1 } else { hi = mid }
	}
	return lo
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits>>(8*byte))&255) }
}

@(export)
static_range_lis_query :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 195 do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > 128 || qv < 1 || qv > 32 do return -1
	n, q := int(nv), int(qv)
	if int(length) != 2+n+2*q do return -1
	permutation := [MAX_N]i64{}
	seen := [MAX_N]bool{}
	left, right, answers, tails := [MAX_Q]i64{}, [MAX_Q]i64{}, [MAX_Q]i64{}, [MAX_N]i64{}
	for i:=0;i<n;i+=1 {
		value:=input[2+i]
		if value<0 || value>=nv || seen[int(value)] do return -1
		seen[int(value)]=true
		permutation[i]=value
	}
	off:=2+n
	for k:=0;k<q;k+=1 {
		left[k]=input[off];right[k]=input[off+1];off+=2
		if left[k]<0 || left[k]>right[k] || right[k]>nv do return -1
	}
	for k:=0;k<q;k+=1 {
		count:=0
		for i:=int(left[k]);i<int(right[k]);i+=1 {
			at:=lower_bound(&tails[0],count,permutation[i])
			tails[at]=permutation[i]
			if at==count {count+=1}
		}
		answers[k]=i64(count)
	}
	bytes:=8*q
	if output==nil || int(capacity)<bytes do return -2
	for k:=0;k<q;k+=1 {put_i64_le(output,8*k,answers[k])}
	return i64(bytes)
}
