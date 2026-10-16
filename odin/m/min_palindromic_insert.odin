package min_palindromic_insert

import "core:c"

MAX_N :: 256
MAX_OUTPUT :: 527
write_i64 :: proc "contextless" (out: [^]u8, pos_value: int, value: i64) -> int {
	pos := pos_value
	bits := u64(value)
	for i := 0; i < 8; i += 1 { out[pos] = u8((bits >> (8*i)) & 255); pos += 1 }
	return pos
}
@(export)
min_palindromic_insert :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil||length<1||length>MAX_N+1 do return -1
	n_value:=input[0];if n_value<1||n_value>MAX_N||length!=c.size_t(n_value+1) do return -1
	n:=int(n_value);chars:[MAX_N]u8
	for i:=0;i<n;i+=1{if input[i+1]<32||input[i+1]>126 do return -1;chars[i]=u8(input[i+1])}
	dp:[MAX_N*MAX_N]u16 = {}
	for span:=2;span<=n;span+=1{for left:=0;left+span<=n;left+=1{right:=left+span-1;at:=left*MAX_N+right;if chars[left]==chars[right]{if span>2 do dp[at]=dp[(left+1)*MAX_N+right-1]}else{a,b:=dp[(left+1)*MAX_N+right],dp[left*MAX_N+right-1];if a<b{dp[at]=a+1}else{dp[at]=b+1}}}}
	insertions:=int(dp[n-1]);palindrome_length:=n+insertions;palindrome:[2*MAX_N-1]u8
	left,right,out_left,out_right:=0,n-1,0,palindrome_length-1
	for left<=right{if chars[left]==chars[right]{palindrome[out_left]=chars[left];palindrome[out_right]=chars[right];left+=1;if right==0{break};right-=1}else if dp[(left+1)*MAX_N+right]<dp[left*MAX_N+right-1]{palindrome[out_left]=chars[left];palindrome[out_right]=chars[left];left+=1}else{palindrome[out_left]=chars[right];palindrome[out_right]=chars[right];if right==0{break};right-=1};out_left+=1;if out_right==0{break};out_right-=1}
	payload:[MAX_OUTPUT]u8 = {};written:=write_i64(&payload[0],0,i64(insertions));written=write_i64(&payload[0],written,i64(palindrome_length));for i:=0;i<palindrome_length;i+=1{payload[written+i]=palindrome[i]};written+=palindrome_length
	if output==nil||capacity<c.size_t(written) do return -2
	for i:=0;i<written;i+=1{output[i]=payload[i]};return i64(written)
}
