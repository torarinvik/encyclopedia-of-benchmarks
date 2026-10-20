// Fresh bounded port based on NyaanNyaan's CC0 radix-2 Schönhage-Strassen method.
module schoenhage_strassen_multiply

const limb_count = 513
const padded = 2048
const scratch_size = 4096
const output_bytes = 129

fn ss_zero(a &i64, n int) { unsafe { for i in 0 .. n { a[i] = 0 } } }
fn ss_copy(dst &i64, src &i64, n int) { unsafe { for i in 0 .. n { dst[i] = src[i] } } }
fn ss_add(dst &i64, src &i64, n int) { unsafe { for i in 0 .. n { dst[i] += src[i] } } }
fn ss_sub(dst &i64, src &i64, n int) { unsafe { for i in 0 .. n { dst[i] -= src[i] } } }

fn ss_rot(dst &i64, src &i64, size int, shift int) {
	unsafe {
		mut d := shift
		wrapped := d >= size
		if wrapped { d -= size }
		mut i := 0
		if wrapped {
			for i < size-d { dst[i+d] = -src[i]; i++ }
			for i < size { dst[i+d-size] = src[i]; i++ }
		} else {
			for i < size-d { dst[i+d] = src[i]; i++ }
			for i < size { dst[i+d-size] = -src[i]; i++ }
		}
	}
}

fn ss_ctz(value u32) int {
	mut x := value
	mut bits := 0
	for (x & 1) == 0 { bits++; x >>= 1 }
	return bits
}

fn ss_fft(a &i64, l int, m int, buf &i64) {
	if l == 0 { return }
	len := 1 << l; block := 1 << m
	mut dw := [16]int{}
	for i in 0 .. l-1 { dw[i]=(1 << (l-2-i))+(1 << (l-1-i))-(1 << (l-1)); if dw[i]<0 {dw[i]+=len}; if len==block {dw[i]*=2}; if 2*len==block {dw[i]*=4} }
	mut d := len/2
	for d > 0 {
		mut w := 0; mut s := 0; mut k := 0
		for {
			unsafe { for i in s .. s+d { ai:=&a[i*block]; aj:=&a[(i+d)*block]; ss_rot(buf,aj,block,w); ss_copy(aj,ai,block); ss_add(ai,buf,block); ss_sub(aj,buf,block) } }
			s += 2*d; if s>=len {break}; k++; w+=dw[ss_ctz(u32(k))]; if w>=2*block {w-=2*block}
		}
		d/=2
	}
}

fn ss_ifft(a &i64, l int, m int, buf &i64) {
	if l == 0 { return }
	len := 1 << l; block := 1 << m
	mut dw := [16]int{}
	for i in 0 .. l-1 { dw[i]=(1 << (l-2-i))+(1 << (l-1-i))-(1 << (l-1)); if dw[i]<0 {dw[i]+=len}; if len==block {dw[i]*=2}; if 2*len==block {dw[i]*=4} }
	mut d := 1
	for d < len {
		mut w := 0; mut s := 0; mut k := 0
		for {
			unsafe { for i in s .. s+d { ai:=&a[i*block]; aj:=&a[(i+d)*block]; ss_copy(buf,ai,block); ss_add(ai,aj,block); ss_sub(buf,aj,block); ss_rot(aj,buf,block,w) } }
			s += 2*d; if s>=len {break}; k++; w-=dw[ss_ctz(u32(k))]; if w<0 {w+=2*block}
		}
		d*=2
	}
}

fn ss_naive(a &i64, b &i64, n int, buf &i64) {
	size:=1<<n; ss_zero(buf,size)
	unsafe { for i in 0..size { mut j:=0; for j<size-i {buf[i+j]+=a[i]*b[j];j++}; for j<size {buf[i+j-size]-=a[i]*b[j];j++} }; ss_copy(a,buf,size) }
}

fn ss_mul(a &i64, b &i64, n int, buf &i64) {
	if n<=5 {ss_naive(a,b,n,buf);return}
	l:=(n+1)/2; m:=n/2; len:=1<<l; block:=1<<m
	mut aa:=[scratch_size]i64{}; mut bb:=[scratch_size]i64{}
	ss_zero(&aa[0],scratch_size);ss_zero(&bb[0],scratch_size);unsafe{ss_zero(&buf[block],block)}
	unsafe { for i in 0..len { s:=i*(2*block/len); ss_copy(buf,&a[i*block],block);ss_rot(&aa[i*block*2],buf,2*block,s);ss_copy(buf,&b[i*block],block);ss_rot(&bb[i*block*2],buf,2*block,s) } }
	ss_fft(&aa[0],l,m+1,buf);ss_fft(&bb[0],l,m+1,buf)
	for i in 0..len {unsafe{ss_mul(&aa[i*block*2],&bb[i*block*2],m+1,buf)}}
	ss_ifft(&aa[0],l,m+1,buf)
	unsafe { for i in 0..len { s:=i*(2*block/len);ss_copy(buf,&aa[i*block*2],2*block);ss_rot(&aa[i*block*2],buf,2*block,s) } }
	unsafe { for i in 0..len {for j in 0..block {a[i*block+j]=aa[i*block*2+j];if i==0 {a[i*block+j]-=aa[(len-1)*block*2+block+j]} else {a[i*block+j]+=aa[(i-1)*block*2+block+j]}}} }
}

fn ss_mul_cyclic(a &i64, b &i64, n int, buf &i64) {
	if n<=5 {ss_naive(a,b,n,buf);return}
	l:=(n+1)/2;m:=n/2;len:=1<<l;block:=1<<m
	mut aa:=[scratch_size]i64{};mut bb:=[scratch_size]i64{}
	unsafe {for i in 0..len {ss_copy(&aa[i*block*2],&a[i*block],block);ss_copy(&bb[i*block*2],&b[i*block],block)}}
	ss_fft(&aa[0],l,m+1,buf);ss_fft(&bb[0],l,m+1,buf)
	for i in 0..len {unsafe{ss_mul(&aa[i*block*2],&bb[i*block*2],m+1,buf)}}
	ss_ifft(&aa[0],l,m+1,buf)
	unsafe {for i in 0..len {for j in 0..block {prev:=i-1;if i==0 {prev=len-1};a[i*block+j]=aa[i*block*2+j]+aa[prev*block*2+block+j]}}}
}

@[export: 'schoenhage_strassen_multiply']
pub fn schoenhage_strassen_multiply(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input==nil||length!=1027||input[0]!=limb_count {return -1}
		mut a:=[padded]i64{};mut b:=[padded]i64{};mut scratch:=[padded]i64{}
		for i in 0..limb_count {x:=input[1+i];y:=input[1+limb_count+i];if x<0||x>1||y<0||y>1{return -1};a[i]=x;b[i]=y}
		if a[limb_count-1]!=1||b[limb_count-1]!=1{return -1}
		if output==nil||capacity<output_bytes{return -2}
		ss_mul_cyclic(&a[0],&b[0],11,&scratch[0])
		mut result:=[output_bytes]u8{};mut carry:=i64(0)
		for i in 0..1025 {value:=a[i]+carry;bit:=u8(value%2);carry=value/2;if bit!=0 {result[output_bytes-1-i/8]|=bit<<(i%8)}}
		mut bit_index:=1025
		for carry>0 {if carry%2!=0 {result[output_bytes-1-bit_index/8]|=1<<(bit_index%8)};carry/=2;bit_index++}
		for i in 0..output_bytes {output[i]=result[i]}
		return output_bytes
	}
}
