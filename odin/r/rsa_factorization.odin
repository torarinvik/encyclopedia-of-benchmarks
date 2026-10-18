package rsa_factorization

import "core:c"

INVALID_RESULT :: i64 = -1
FACTOR_BASE :: i64 = 65536
MAX_PACKED_LENGTH :: c.size_t(21)

gcd_i64 :: proc "contextless" (a_input, b_input: i64) -> i64 {
	a,b:=a_input,b_input
	if a<0 do a=-a
	if b<0 do b=-b
	for b!=0 { remainder:=a%b;a=b;b=remainder }
	return a
}

power_mod_i64 :: proc "contextless" (base, exponent_input, modulus: i64) -> i64 {
	exponent:=exponent_input
	result:=i64(1)
	power:=base%modulus
	for exponent>0 {
		if exponent&1!=0 do result=(result*power)%modulus
		power=(power*power)%modulus
		exponent/=2
	}
	return result
}

@(export)
rsa_factorization :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed==nil||length<4||length>MAX_PACKED_LENGTH do return INVALID_RESULT
	d,e,modulus,attempts:=packed[0],packed[1],packed[2],packed[3]
	if d<1||d>1000000||e<1||e>1000000||modulus<3||modulus>65535||modulus%2==0||attempts<1||attempts>16||length!=c.size_t(4+attempts) do return INVALID_RESULT
	k:=d*e-1
	if k<=0||k%2!=0 do return INVALID_RESULT
	for i:=i64(0);i<attempts;i+=1{base:=packed[4+c.size_t(i)];if base<2||base>modulus-1 do return INVALID_RESULT}
	for i:=i64(0);i<attempts;i+=1 {
		base:=packed[4+c.size_t(i)]
		t:=k
		for t%2==0 {
			t/=2
			x:=power_mod_i64(base,t,modulus)
			factor:=gcd_i64(x-1,modulus)
			if x>1&&factor>1 {other:=modulus/factor;p,q:=factor,other;if p>q{p,q=q,p};return p*FACTOR_BASE+q}
		}
	}
	return INVALID_RESULT
}
