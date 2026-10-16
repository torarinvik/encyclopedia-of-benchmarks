package flatten_nested_list
import "core:c"

signed_hash :: proc(hash: u64) -> i64 {
	sign := u64(1) << 63
	if hash < sign do return i64(hash)
	magnitude := u64(0xffffffffffffffff) - hash + 1
	if magnitude == sign do return -9223372036854775807 - 1
	return -i64(magnitude)
}

@(export)
flatten_nested_list :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 open: i64 = -9223372036854775808; close := open+1
 if v==nil||n==0||n>255||v[0]!=open do return -1
 depth:=0;closed:=false;h:u64=0xcbf29ce484222325
 for i:=c.size_t(0);i<n;i+=1{x:=v[i];if x==open{if closed||(depth==0&&i!=0) do return -1;depth+=1;if depth>16 do return -1}else if x==close{if depth==0 do return -1;depth-=1;if depth==0{closed=true;if i+1!=n do return -1}}else{if depth==0||x< -1000000||x>1000000 do return -1;u:=transmute(u64,x);for b:=u32(0);b<8;b+=1{h=(h^((u>>(8*b))&255))*0x100000001b3}}}
 if depth!=0||!closed do return -1
 return signed_hash(h)
}
