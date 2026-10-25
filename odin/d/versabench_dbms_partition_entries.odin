package versabench_dbms_partition_entries
import "core:c"

MAX_FAN :: 8
MAX_INPUT_LENGTH :: 1 + 8 * (MAX_FAN + 1)

valid_box :: proc "contextless" (v: [^]i64, at: int) -> bool {
	for d := 0; d < 4; d += 1 { if v[at+d] < -8 || v[at+d] > 8 || v[at+4+d] < -8 || v[at+4+d] > 8 || v[at+d] >= v[at+4+d] { return false } }
	return true
}
volume_at :: proc "contextless" (v: [^]i64, at: int) -> i64 { p: i64=1;for d:=0;d<4;d+=1{p*=v[at+4+d]-v[at+d]};return p }
union_volume :: proc "contextless" (v: [^]i64,left,right: int) -> i64 {
	p:i64=1
	for d:=0;d<4;d+=1{lo:=v[left+d];if v[right+d]<lo{lo=v[right+d]};hi:=v[left+4+d];if v[right+4+d]>hi{hi=v[right+4+d]};p*=hi-lo}
	return p
}
penalty :: proc "contextless" (v:[^]i64,seed,entry:int)->i64{return union_volume(v,seed,entry)-volume_at(v,seed)}

@(export, link_name="versabench_dbms_partition_entries")
versabench_dbms_partition_entries :: proc "c" (values:[^]i64,length:c.size_t)->i64{
	if values==nil||length<1||length>c.size_t(MAX_INPUT_LENGTH+1) do return -1
	if values[0]<2||values[0]>MAX_FAN do return -1
	fan:=int(values[0]);count:=fan+1
	if length!=c.size_t(1+8*count) do return -1
	for i:=0;i<count;i+=1{if !valid_box(values,1+8*i) do return -1}
	seed_a,seed_b:=0,1;largest:=union_volume(values,1,9)
	for i:=0;i<count;i+=1{for j:=i+1;j<count;j+=1{candidate:=union_volume(values,1+8*i,1+8*j);if candidate>largest{seed_a=i;seed_b=j;largest=candidate}}}
	a_at:=1+8*seed_a;b_at:=1+8*seed_b;size_a,size_b:=1,1;mask:=i64(1)<<seed_a
	for i:=0;i<count;i+=1{if i==seed_a||i==seed_b{continue};at:=1+8*i
		if size_a<fan&&size_b<fan{if penalty(values,a_at,at)<penalty(values,b_at,at){mask|=i64(1)<<i;size_a+=1}else{size_b+=1}}
		else if size_a>=fan&&size_b<fan{size_b+=1}else if size_b>=fan&&size_a<fan{mask|=i64(1)<<i;size_a+=1}else{return -1}
	}
	return mask
}
