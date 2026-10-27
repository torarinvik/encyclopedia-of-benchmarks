module spatial_motif_same_type_contact_pmf

const max_length = 16
const max_support = 17

fn choose_value(n int, k0 int) i64 {
	if k0 < 0 || k0 > n { return 0 }
	mut k := k0
	if k > n-k { k=n-k }
	mut result := i64(1)
	for i := 1; i <= k; i++ { result = result * i64(n-k+i) / i64(i) }
	return result
}
fn gcd_value(a0 i64,b0 i64) i64 {
	mut a:=a0;mut b:=b0
	for b!=0 { r:=a%b;a=b;b=r }
	return a
}
fn put_i64_le(mut output &u8,word int,value i64) {
	bits:=u64(value)
	for byte in 0 .. 8 { unsafe { output[word*8+byte]=u8((bits>>(byte*8))&255) } }
}

@[export: 'spatial_motif_same_type_contact_pmf']
pub fn spatial_motif_same_type_contact_pmf(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if input==nil || length!=3 { return -1 }
	l0:=unsafe{input[0]};x10:=unsafe{input[1]};x20:=unsafe{input[2]}
	if l0<1 || l0>max_length || x10<0 || x10>l0 || x20<0 || x20>l0 { return -1 }
	l:=int(l0);x1:=int(x10);x2:=int(x20)
	low:=if x1+x2>l { x1+x2-l } else { 0 };high:=if x1<x2 { x1 } else { x2 }
	denominator:=choose_value(l,x2)
	mut numerators:=[max_support]i64{}
	for i:=low; i<=high; i++ { numerators[i-low]=choose_value(x1,i)*choose_value(l-x1,x2-i) }
	mut expected_num:=i64(x1*x2);mut expected_den:=i64(l);divisor:=gcd_value(expected_num,expected_den)
	expected_num/=divisor;expected_den/=divisor
	count:=high-low+1;bytes:=(3+count+2)*8
	if output==nil || capacity<usize(bytes) { return -2 }
	put_i64_le(mut output,0,i64(low));put_i64_le(mut output,1,i64(high));put_i64_le(mut output,2,denominator)
	for i in 0 .. count { put_i64_le(mut output,3+i,numerators[i]) }
	put_i64_le(mut output,3+count,expected_num);put_i64_le(mut output,4+count,expected_den)
	return i64(bytes)
}
