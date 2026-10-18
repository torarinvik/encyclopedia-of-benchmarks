module rsa_factorization

const invalid_result = i64(-1)
const factor_base = i64(65536)
const max_packed_length = 21

fn gcd_i64(a_input i64, b_input i64) i64 {
	mut a:=a_input
	mut b:=b_input
	if a<0 { a= -a }
	if b<0 { b= -b }
	for b!=0 { remainder:=a%b;a=b;b=remainder }
	return a
}

fn power_mod_i64(base i64, exponent_input i64, modulus i64) i64 {
	mut exponent:=exponent_input
	mut result:=i64(1)
	mut power:=base%modulus
	for exponent>0 {
		if exponent&1!=0 { result=(result*power)%modulus }
		power=(power*power)%modulus
		exponent/=2
	}
	return result
}

@[export: 'rsa_factorization']
pub fn rsa_factorization(packed &i64, length usize) i64 {
	unsafe {
		if packed==nil||length<4||length>max_packed_length{return invalid_result}
		d,e,modulus,attempts:=packed[0],packed[1],packed[2],packed[3]
		if d<1||d>1000000||e<1||e>1000000||modulus<3||modulus>65535||modulus%2==0||attempts<1||attempts>16||length!=usize(4+attempts){return invalid_result}
		k:=d*e-1
		if k<=0||k%2!=0{return invalid_result}
		for i in 0..int(attempts){base:=packed[4+i];if base<2||base>modulus-1{return invalid_result}}
		for i in 0..int(attempts){
			base:=packed[4+i]
			mut t:=k
			for t%2==0{
				t/=2
				x:=power_mod_i64(base,t,modulus)
				factor:=gcd_i64(x-1,modulus)
				if x>1&&factor>1{other:=modulus/factor;p,q:=factor,other;if p>q{p,q=q,p};return p*factor_base+q}
			}
		}
		return invalid_result
	}
}
