/*
 * C Converted Whetstone Double Precision Benchmark
 *		Version 1.2	22 March 1998
 *
 *		(c) Copyright 1998 Painter Engineering, Inc.
 *		All Rights Reserved.
 *
 *		Permission is granted to use, duplicate, and
 *		publish this text and program as long as it
 *		includes this entire comment block and limited
 *		rights reference.
 *
 * Converted by Rich Painter, Painter Engineering, Inc. based on the
 * www.netlib.org benchmark/whetstoned version obtained 16 March 1998.
 *
 * A novel approach was used here to keep the look and feel of the
 * FORTRAN version.  Altering the FORTRAN-based array indices,
 * starting at element 1, to start at element 0 for C, would require
 * numerous changes, including decrementing the variable indices by 1.
 * Instead, the array E1[] was declared 1 element larger in C.  This
 * allows the FORTRAN index range to function without any literal or
 * variable indices changes.  The array element E1[0] is simply never
 * used and does not alter the benchmark results.
 *
 * The major FORTRAN comment blocks were retained to minimize
 * differences between versions.  Modules N5 and N12, like in the
 * FORTRAN version, have been eliminated here.
 *
 * An optional command-line argument has been provided [-c] to
 * offer continuous repetition of the entire benchmark.
 * An optional argument for setting an alternate LOOP count is also
 * provided.  Define PRINTOUT to cause the POUT() function to print
 * outputs at various stages.  Final timing measurements should be
 * made with the PRINTOUT undefined.
 *
 * Questions and comments may be directed to the author at
 *			r.painter@ieee.org
 */

module ansibench_whetstone
import math

const invalid_result = -1e300

fn pa(mut e [5]f64, t f64) {
	mut j := 0
	for {
		e[1] = (e[1] + e[2] + e[3] - e[4]) * t
		e[2] = (e[1] + e[2] - e[3] + e[4]) * t
		e[3] = (e[1] - e[2] + e[3] + e[4]) * t
		e[4] = (-e[1] + e[2] + e[3] + e[4]) / 2.0
		j++
		if j >= 6 { break }
	}
}

fn p3(x f64, y f64) f64 {
	mut x1 := x
	mut y1 := y
	x1 = 0.499975 * (x1 + y1)
	y1 = 0.499975 * (x1 + y1)
	return (x1 + y1) / 2.0
}

fn add(mut sum f64, mut idx f64, value f64) {
	sum += idx * value
	idx += 1.0
}

fn one_pass() f64 {
	t := 0.499975
	t1 := 0.50025
	t2 := 2.0
	mut sum := 0.0
	mut idx := 1.0
	add(mut sum, mut idx, 1.0)
	add(mut sum, mut idx, -1.0)
	add(mut sum, mut idx, -1.0)
	add(mut sum, mut idx, -1.0)
	mut e := [5]f64{0.0, 1.0, -1.0, -1.0, -1.0}
	for _ in 0 .. 12 {
		e[1] = (e[1] + e[2] + e[3] - e[4]) * t
		e[2] = (e[1] + e[2] - e[3] + e[4]) * t
		e[3] = (e[1] - e[2] + e[3] + e[4]) * t
		e[4] = (-e[1] + e[2] + e[3] + e[4]) * t
	}
	for value in e[1..5] { add(mut sum, mut idx, value) }
	for _ in 0 .. 14 { pa(mut e, t) }
	for value in e[1..5] { add(mut sum, mut idx, value) }
	mut j := 1
	for _ in 0 .. 345 {
		j = if j == 1 { 2 } else { 3 }
		j = if j > 2 { 0 } else { 1 }
		j = if j < 1 { 1 } else { 0 }
	}
	add(mut sum, mut idx, f64(j))
	j = 1
	mut k := 2
	mut l := 3
	for _ in 0 .. 210 {
		j = j * (k - j) * (l - k)
		k = l * k - (l - j) * k
		l = (l - k) * (k + j)
		e[l - 1] = f64(j + k + l)
		e[k - 1] = f64(j * k * l)
	}
	add(mut sum, mut idx, f64(j)); add(mut sum, mut idx, f64(k)); add(mut sum, mut idx, f64(l))
	for value in e[1..5] { add(mut sum, mut idx, value) }
	mut x := 0.5
	mut y := 0.5
	for _ in 0 .. 32 {
		x = t * math.atan(t2 * math.sin(x) * math.cos(x) / (math.cos(x + y) + math.cos(x - y) - 1.0))
		y = t * math.atan(t2 * math.sin(y) * math.cos(y) / (math.cos(x + y) + math.cos(x - y) - 1.0))
	}
	add(mut sum, mut idx, x); add(mut sum, mut idx, y)
	x = 1.0; y = 1.0
	mut z := 1.0
	for _ in 0 .. 899 { z = p3(x, y) }
	add(mut sum, mut idx, x); add(mut sum, mut idx, y); add(mut sum, mut idx, z)
	j = 1; k = 2; l = 3
	e[1] = 1.0; e[2] = 2.0; e[3] = 3.0
	for _ in 0 .. 616 {
		e[j] = e[k]
		e[k] = e[l]
		e[l] = e[j]
	}
	add(mut sum, mut idx, f64(j)); add(mut sum, mut idx, f64(k)); add(mut sum, mut idx, f64(l))
	for value in e[1..5] { add(mut sum, mut idx, value) }
	j = 2; k = 3
	add(mut sum, mut idx, f64(j)); add(mut sum, mut idx, f64(k))
	x = 0.75
	for _ in 0 .. 93 { x = math.sqrt(math.exp(math.log(x) / t1)) }
	add(mut sum, mut idx, x)
	return sum
}

@[export: 'ansibench_whetstone']
pub fn ansibench_whetstone(values &i64, length usize) f64 {
	if values == nil || length != 1 { return invalid_result }
	count := unsafe { values[0] }
	if count < 1 || count > 3 { return invalid_result }
	mut total := 0.0
	for pass in 0 .. int(count) { total += f64(pass + 1) * one_pass() }
	if !total.is_finite() { return invalid_result }
	return total
}
