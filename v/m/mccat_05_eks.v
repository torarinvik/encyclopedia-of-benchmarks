/*
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/
module mccat_05_eks

import math

const min_n = 3
const max_n = 8
const max_input = 66
const input_scale = 1_000_000.0
const output_scale = 1_000.0
const qr_epsilon = 1.0e-10
const max_qr_steps = 4096

fn absd(x f64) f64 { return if x < 0.0 { -x } else { x } }

fn givens(a f64, b f64) (f64, f64) {
	if b == 0.0 { return 0.0, 1.0 }
	if absd(b) > absd(a) { t := -a / b; s := 1.0 / math.sqrt(1.0 + t*t); return s, s*t }
	t := -b / a
	c := 1.0 / math.sqrt(1.0 + t*t)
	return c*t, c
}

fn apply_givens(mut a [64]f64, n int, s f64, c f64, i int, j int, start int, ending int) {
	for k := start; k <= ending; k++ { x := a[i*n+k]; y := a[j*n+k]; a[i*n+k] = c*x-s*y; a[j*n+k] = s*x+c*y }
	for k := start; k <= ending; k++ { x := a[k*n+i]; y := a[k*n+j]; a[k*n+i] = c*x-s*y; a[k*n+j] = s*x+c*y }
}

fn reduce_band(mut a [64]f64, n int, bandwidth int) {
	for i := bandwidth; i >= 2; i-- {
		for j := 0; j < n-i; j++ {
			s, c := givens(a[j*n+j+i-1], a[j*n+j+i]); ending := if j+2*i < n { j+2*i } else { n-1 }
			apply_givens(mut a, n, s, c, j+i-1, j+i, j, ending)
			mut m := j+i
			for m < n-i {
				s2, c2 := givens(a[(m-1)*n+m+i-1], a[(m-1)*n+m+i]); end2 := if m+2*i < n { m+2*i } else { n-1 }
				apply_givens(mut a, n, s2, c2, m+i-1, m+i, m-1, end2)
				m += i
			}
		}
	}
}

fn qr_iterate(mut a [64]f64, n int) bool {
	mut steps := 0
	for {
		for i := 0; i < n-1; i++ { if absd(a[(i+1)*n+i]) < (absd(a[i*n+i])+absd(a[(i+1)*n+i+1]))*qr_epsilon { a[(i+1)*n+i] = 0; a[i*n+i+1] = 0 } }
		mut q := n-1
		for q > 0 && a[(q-1)*n+q] == 0.0 { q-- }
		if q == 0 { return true }
		steps++
		if steps > max_qr_steps { return false }
		mut p := q
		for p > 0 && a[(p-1)*n+p] != 0.0 { p-- }
		d := (a[(q-1)*n+q-1]-a[q*n+q])/2.0
		t := a[q*n+q-1]*a[q*n+q-1]
		sign := if d < 0.0 { -1.0 } else { 1.0 }
		mu := a[q*n+q]-t/(d+sign*math.sqrt(d*d+t))
		mut x := a[p*n+p]-mu
		mut z := a[(p+1)*n+p]
		for i := p; i < q; i++ {
			s,c := givens(x,z)
			l := if i > p { i-1 } else { p }; m := if q < i+2 { q } else { i+2 }
			for k := l; k <= m; k++ { u:=a[i*n+k];v:=a[(i+1)*n+k];a[i*n+k]=c*u-s*v;a[(i+1)*n+k]=s*u+c*v }
			for k := l; k <= m; k++ { u:=a[k*n+i];v:=a[k*n+i+1];a[k*n+i]=c*u-s*v;a[k*n+i+1]=s*u+c*v }
			if i < q-1 { x=a[(i+1)*n+i];z=a[(i+2)*n+i] }
		}
	}
}

fn project(value f64) i32 {
	scaled := value * output_scale
	return if scaled >= 0.0 { i32(scaled + 0.5) } else { i32(scaled - 0.5) }
}
fn before(left f64, right f64) bool { return absd(left)>absd(right)||(absd(left)==absd(right)&&left<right) }
fn put_i32_le(mut output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe { for i in 0..4 { output[offset+i] = u8((bits >> u32(8*i)) & 255) } }
}

@[export: 'mccat_05_eks']
pub fn mccat_05_eks(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n64 := input[0]; bw64 := input[1]
		if n64 < min_n || n64 > max_n || bw64 < 2 || bw64 > 5 || bw64 >= n64 { return -1 }
		n := int(n64); bandwidth := int(bw64)
		if length != usize(2+n*n) { return -1 }
		mut a := [64]f64{}
		for row in 0..n { for column in 0..n {
			value := input[2+row*n+column]
			if value < -1_000_000 || value > 1_000_000 { return -1 }
			if row > column && value != input[2+column*n+row] { return -1 }
			distance := if row > column { row-column } else { column-row }
			if distance > bandwidth && value != 0 { return -1 }
			a[row*n+column] = f64(value)/input_scale
		} }
		required := n*4
		if output == nil || capacity < usize(required) { return -2 }
		reduce_band(mut a,n,bandwidth)
		if !qr_iterate(mut a,n) { return -1 }
		mut eigenvalues := [8]f64{}
		for i in 0..n { eigenvalues[i]=a[i*n+i] }
		for i:=1;i<n;i++ { value:=eigenvalues[i];mut j:=i;for j>0&&before(value,eigenvalues[j-1]){eigenvalues[j]=eigenvalues[j-1];j--};eigenvalues[j]=value }
		mut staged := [32]u8{}
		for i in 0..n { put_i32_le(mut staged[0],4*i,project(eigenvalues[i])) }
		for i in 0..required { output[i]=staged[i] }
		return i64(required)
	}
}
