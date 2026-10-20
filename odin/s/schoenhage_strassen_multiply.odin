package schoenhage_strassen_multiply

import "core:c"

LIMBS :: 513
PADDED :: 2048
SCRATCH :: 4096
OUTPUT_BYTES :: 129

ss_zero :: proc(a: [^]i64, n: int) { for i := 0; i < n; i += 1 { a[i] = 0 } }
ss_copy :: proc(dst, src: [^]i64, n: int) { for i := 0; i < n; i += 1 { dst[i] = src[i] } }
ss_add :: proc(dst, src: [^]i64, n: int) { for i := 0; i < n; i += 1 { dst[i] += src[i] } }
ss_sub :: proc(dst, src: [^]i64, n: int) { for i := 0; i < n; i += 1 { dst[i] -= src[i] } }

ss_rot :: proc(dst, src: [^]i64, size, shift: int) {
	d := shift; wrapped := d >= size; if wrapped { d -= size }
	i := 0
	if wrapped { for ; i < size-d; i += 1 { dst[i+d] = -src[i] }; for ; i < size; i += 1 { dst[i+d-size] = src[i] } }
	else { for ; i < size-d; i += 1 { dst[i+d] = src[i] }; for ; i < size; i += 1 { dst[i+d-size] = -src[i] } }
}

ss_ctz :: proc(value: uint) -> int {
	x := value; bits := 0
	for (x & 1) == 0 { bits += 1; x >>= 1 }
	return bits
}

ss_fft :: proc(a: [^]i64, l, m: int, buf: [^]i64) {
	if l == 0 { return }
	len := 1 << l; block := 1 << m
	dw: [16]int
	for i := 0; i < l-1; i += 1 {
		dw[i] = (1 << (l-2-i)) + (1 << (l-1-i)) - (1 << (l-1))
		if dw[i] < 0 { dw[i] += len }; if len == block { dw[i] *= 2 }; if 2*len == block { dw[i] *= 4 }
	}
	for d := len/2; d > 0; d /= 2 {
		w := 0; s := 0; k := 0
		for {
			for i := s; i < s+d; i += 1 { ai := &a[i*block]; aj := &a[(i+d)*block]; ss_rot(buf, aj, block, w); ss_copy(aj, ai, block); ss_add(ai, buf, block); ss_sub(aj, buf, block) }
			s += 2*d; if s >= len { break }; k += 1; w += dw[ss_ctz(uint(k))]; if w >= 2*block { w -= 2*block }
		}
	}
}

ss_ifft :: proc(a: [^]i64, l, m: int, buf: [^]i64) {
	if l == 0 { return }
	len := 1 << l; block := 1 << m
	dw: [16]int
	for i := 0; i < l-1; i += 1 {
		dw[i] = (1 << (l-2-i)) + (1 << (l-1-i)) - (1 << (l-1))
		if dw[i] < 0 { dw[i] += len }; if len == block { dw[i] *= 2 }; if 2*len == block { dw[i] *= 4 }
	}
	for d := 1; d < len; d *= 2 {
		w := 0; s := 0; k := 0
		for {
			for i := s; i < s+d; i += 1 { ai := &a[i*block]; aj := &a[(i+d)*block]; ss_copy(buf, ai, block); ss_add(ai, aj, block); ss_sub(buf, aj, block); ss_rot(aj, buf, block, w) }
			s += 2*d; if s >= len { break }; k += 1; w -= dw[ss_ctz(uint(k))]; if w < 0 { w += 2*block }
		}
	}
}

ss_naive :: proc(a, b: [^]i64, n: int, buf: [^]i64) {
	size := 1 << n; ss_zero(buf, size)
	for i := 0; i < size; i += 1 {
		j := 0; for ; j < size-i; j += 1 { buf[i+j] += a[i]*b[j] }; for ; j < size; j += 1 { buf[i+j-size] -= a[i]*b[j] }
	}
	ss_copy(a, buf, size)
}

ss_mul :: proc(a, b: [^]i64, n: int, buf: [^]i64) {
	if n <= 5 { ss_naive(a,b,n,buf); return }
	l := (n+1)/2; m := n/2; len := 1<<l; block := 1<<m
	A, B: [SCRATCH]i64; ss_zero(&A[0], SCRATCH); ss_zero(&B[0], SCRATCH); ss_zero(&buf[block], block)
	for i := 0; i < len; i += 1 { s := i*(2*block/len); ss_copy(buf,&a[i*block],block); ss_rot(&A[i*block*2],buf,2*block,s); ss_copy(buf,&b[i*block],block); ss_rot(&B[i*block*2],buf,2*block,s) }
	ss_fft(&A[0],l,m+1,buf); ss_fft(&B[0],l,m+1,buf)
	for i := 0; i < len; i += 1 { ss_mul(&A[i*block*2],&B[i*block*2],m+1,buf) }
	ss_ifft(&A[0],l,m+1,buf)
	for i := 0; i < len; i += 1 { s:=i*(2*block/len); ss_copy(buf,&A[i*block*2],2*block); ss_rot(&A[i*block*2],buf,2*block,s) }
	for i := 0; i < len; i += 1 { for j := 0; j < block; j += 1 { a[i*block+j]=A[i*block*2+j]; if i==0 { a[i*block+j]-=A[(len-1)*block*2+block+j] } else { a[i*block+j]+=A[(i-1)*block*2+block+j] } } }
}

ss_mul_cyclic :: proc(a, b: [^]i64, n: int, buf: [^]i64) {
	if n <= 5 { ss_naive(a,b,n,buf); return }
	l := (n+1)/2; m := n/2; len := 1<<l; block := 1<<m
	A, B: [SCRATCH]i64; ss_zero(&A[0], SCRATCH); ss_zero(&B[0], SCRATCH)
	for i := 0; i < len; i += 1 { ss_copy(&A[i*block*2],&a[i*block],block); ss_copy(&B[i*block*2],&b[i*block],block) }
	ss_fft(&A[0],l,m+1,buf); ss_fft(&B[0],l,m+1,buf)
	for i := 0; i < len; i += 1 { ss_mul(&A[i*block*2],&B[i*block*2],m+1,buf) }
	ss_ifft(&A[0],l,m+1,buf)
	for i := 0; i < len; i += 1 { for j := 0; j < block; j += 1 { prev := i-1; if i==0 { prev=len-1 }; a[i*block+j]=A[i*block*2+j]+A[prev*block*2+block+j] } }
}

@(export, link_name="schoenhage_strassen_multiply")
schoenhage_strassen_multiply :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1027 || input[0] != LIMBS do return -1
	var_a, var_b, scratch: [PADDED]i64
	ss_zero(&var_a[0], PADDED)
	ss_zero(&var_b[0], PADDED)
	ss_zero(&scratch[0], PADDED)
	for i := 0; i < LIMBS; i += 1 { x:=input[1+i]; y:=input[1+LIMBS+i]; if x<0 || x>1 || y<0 || y>1 do return -1; var_a[i]=x; var_b[i]=y }
	if var_a[LIMBS-1] != 1 || var_b[LIMBS-1] != 1 do return -1
	if output == nil || capacity < c.size_t(OUTPUT_BYTES) do return -2
	ss_mul_cyclic(&var_a[0],&var_b[0],11,&scratch[0])
	result: [OUTPUT_BYTES]u8; for i:=0;i<OUTPUT_BYTES;i+=1 { result[i]=0 }
	carry:=i64(0)
	for i:=0;i<1025;i+=1 { value:=var_a[i]+carry; bit:=u8(value%2); carry=value/2; if bit!=0 { result[OUTPUT_BYTES-1-i/8]|=bit<<u8(i%8) } }
	bit_index:=1025
	for carry>0 { if carry%2!=0 { result[OUTPUT_BYTES-1-bit_index/8]|=1<<u8(bit_index%8) }; carry/=2; bit_index+=1 }
	for i:=0;i<OUTPUT_BYTES;i+=1 { output[i]=result[i] }
	return OUTPUT_BYTES
}
