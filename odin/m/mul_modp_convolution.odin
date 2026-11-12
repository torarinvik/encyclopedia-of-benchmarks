package mul_modp_convolution
import "core:c"

MAX_P :: 97
MAX_INPUT :: 196
MAX_OUTPUT :: 776
MOD :: i64(998244353)

pow_mod :: proc(base_input: i64, exponent_input, modulus: int) -> int {
	base := base_input % i64(modulus); exponent := exponent_input; result := i64(1)
	for exponent > 0 { if (exponent & 1) != 0 { result=result*base%i64(modulus) }; base=base*base%i64(modulus); exponent >>= 1 }
	return int(result)
}
is_prime :: proc(p: int) -> bool {
	if p<2 do return false
	for d:=2;d*d<=p;d+=1 {if p%d==0 do return false}
	return true
}
primitive_root :: proc(p: int) -> int {
	order:=p-1
	for candidate:=1;candidate<p;candidate+=1 {
		good:=true
		for factor:=2;factor<=order;factor+=1 {
			if order%factor!=0 || !is_prime(factor) do continue
			if pow_mod(i64(candidate),order/factor,p)==1 {good=false;break}
		}
		if good do return candidate
	}
	return 1
}
store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits:=u64(value);for byte:=0;byte<8;byte+=1 {output[offset+byte]=u8(bits&255);bits>>=8}
}

@(export)
mul_modp_convolution :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length<5 || length>MAX_INPUT do return -1
	p0:=input[0]
	if p0<2 || p0>MAX_P || !is_prime(int(p0)) do return -1
	p:=int(p0)
	if length!=c.size_t(1+2*p) do return -1
	for i:=1;i<int(length);i+=1 {if input[i]<0 || input[i]>=MOD do return -1}
	bytes:=8*p
	if bytes>MAX_OUTPUT do return -1
	if output==nil || capacity<c.size_t(bytes) do return -2
	a,b,left,right,cyclic,result: [MAX_P]i64 = {}, {}, {}, {}, {}, {}
	by_exp: [MAX_P]int = {}
	for i:=0;i<p;i+=1 {a[i]=input[1+i];b[i]=input[1+p+i]}
	q:=p-1;root:=primitive_root(p);residue:=1
	for e:=0;e<q;e+=1 {by_exp[e]=residue;residue=residue*root%p}
	for e:=0;e<q;e+=1 {left[e]=a[by_exp[e]];right[e]=b[by_exp[e]]}
	for i:=0;i<q;i+=1 {for j:=0;j<q;j+=1 {slot:=(i+j)%q;cyclic[slot]=(cyclic[slot]+left[i]*right[j]%MOD)%MOD}}
	sum_a,sum_b:=i64(0),i64(0)
	for i:=0;i<p;i+=1 {sum_a=(sum_a+a[i])%MOD}
	for i:=1;i<p;i+=1 {sum_b=(sum_b+b[i])%MOD}
	result[0]=(sum_a*b[0]%MOD+a[0]*sum_b%MOD)%MOD
	for e:=0;e<q;e+=1 {result[by_exp[e]]=cyclic[e]}
	for i:=0;i<p;i+=1 {store_le(output,8*i,result[i])}
	return i64(bytes)
}
