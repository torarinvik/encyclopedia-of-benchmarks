package smo_deterministic_training

import "core:c"
import "core:math"

MAX_N :: 8
MAX_D :: 3
MAX_INPUT :: 37
TOLERANCE :: 0.001
EPSILON :: 0.001

field :: proc(x: f64, low, high: i64) -> bool {
	if math.is_nan(x) || math.is_inf(x) || x < f64(low) || x > f64(high) do return false
	return f64(i64(x)) == x
}

kernel :: proc(points: []f64, i, j, d: int) -> f64 {
	value := f64(0.0)
	for k := 0; k < d; k += 1 { value += points[i*MAX_D+k] * points[j*MAX_D+k] }
	return value
}

decision :: proc(index: int, alpha: []f64, bias: f64, labels: []i64,
	points: []f64, n, d: int) -> f64 {
	value := bias
	for k := 0; k < n; k += 1 { value += alpha[k] * f64(labels[k]) * kernel(points, k, index, d) }
	return value
}

dual :: proc(alpha: []f64, labels: []i64, points: []f64, n, d: int) -> f64 {
	value := f64(0.0)
	for i := 0; i < n; i += 1 { value += alpha[i] }
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 { value -= 0.5*alpha[i]*alpha[j]*f64(labels[i]*labels[j])*kernel(points,i,j,d) }
	}
	return value
}

take_step :: proc(i, j: int, alpha: []f64, bias: ^f64, c_value: f64,
	labels: []i64, points: []f64, n, d: int) -> bool {
	if i == j do return false
	yi := labels[i]; yj := labels[j]; sign := yi*yj
	old_i := alpha[i]; old_j := alpha[j]
	error_i := decision(i, alpha, bias^, labels, points, n, d)-f64(yi)
	error_j := decision(j, alpha, bias^, labels, points, n, d)-f64(yj)
	low := f64(0.0); high := f64(0.0)
	if yi != yj { low=math.max(0.0,old_j-old_i); high=math.min(c_value,c_value+old_j-old_i) }
	else { low=math.max(0.0,old_i+old_j-c_value); high=math.min(c_value,old_i+old_j) }
	if low == high do return false
	kii := kernel(points,i,i,d); kjj := kernel(points,j,j,d); kij := kernel(points,i,j,d)
	curvature := kii+kjj-2.0*kij
	new_j := f64(0.0)
	if curvature > 0.0 { new_j=math.max(low,math.min(high,old_j+f64(yj)*(error_i-error_j)/curvature)) }
	else {
		var candidate:[MAX_N]f64
		for k:=0; k<n; k+=1 { candidate[k]=alpha[k] }
		candidate[i]=old_i+f64(sign)*(old_j-low); candidate[j]=low
		low_score := dual(candidate[:],labels,points,n,d)
		candidate[i]=old_i+f64(sign)*(old_j-high); candidate[j]=high
		high_score := dual(candidate[:],labels,points,n,d)
		if low_score > high_score+EPSILON { new_j=low }
		else if high_score > low_score+EPSILON { new_j=high }
		else { new_j=old_j }
	}
	if math.abs(new_j-old_j) < EPSILON*(new_j+old_j+EPSILON) do return false
	new_i := old_i+f64(sign)*(old_j-new_j)
	di := new_i-old_i; dj := new_j-old_j
	b_i := bias^ - error_i - f64(yi)*di*kii - f64(yj)*dj*kij
	b_j := bias^ - error_j - f64(yi)*di*kij - f64(yj)*dj*kjj
	if new_i > 0 && new_i < c_value { bias^ = b_i }
	else if new_j > 0 && new_j < c_value { bias^ = b_j }
	else { bias^ = 0.5*(b_i+b_j) }
	alpha[i]=new_i; alpha[j]=new_j
	return true
}

examine :: proc(j: int, alpha: []f64, bias: ^f64, c_value: f64, labels: []i64,
	points: []f64, n, d: int) -> bool {
	error_j := decision(j,alpha,bias^,labels,points,n,d)-f64(labels[j])
	r := error_j*f64(labels[j])
	if !((r < -TOLERANCE && alpha[j] < c_value) || (r > TOLERANCE && alpha[j] > 0)) do return false
	free_count := 0; preferred := -1; greatest_gap := f64(-1.0)
	for i := 0; i < n; i += 1 {
		if alpha[i] > 0 && alpha[i] < c_value {
			free_count += 1
			error_i := decision(i,alpha,bias^,labels,points,n,d)-f64(labels[i])
			gap := math.abs(error_i-error_j)
			if gap > greatest_gap { greatest_gap=gap; preferred=i }
		}
	}
	if free_count > 1 && take_step(preferred,j,alpha,bias,c_value,labels,points,n,d) do return true
	for i := 0; i < n; i += 1 {
		if alpha[i] > 0 && alpha[i] < c_value && take_step(i,j,alpha,bias,c_value,labels,points,n,d) do return true
	}
	for i := 0; i < n; i += 1 { if take_step(i,j,alpha,bias,c_value,labels,points,n,d) do return true }
	return false
}

@(export)
smo_deterministic_training :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 4 || input_length > MAX_INPUT do return -1
	if !field(input[0],2,MAX_N) || !field(input[1],1,MAX_D) ||
		!field(input[2],1,5000) || !field(input[3],1,16) do return -1
	n:=int(input[0]); d:=int(input[1]); c_milli:=i64(input[2]); pass_cap:=int(input[3])
	if input_length != c.size_t(4+n+n*d) do return -1
	var labels:[MAX_N]i64
	var alpha:[MAX_N]f64
	var points:[MAX_N*MAX_D]f64
	positive:=false; negative:=false; at:=4
	for i:=0; i<n; i+=1 {
		if !field(input[at],-1,1) || input[at]==0 do return -1
		labels[i]=i64(input[at]); positive=positive||labels[i]>0; negative=negative||labels[i]<0; at+=1
	}
	if !positive || !negative do return -1
	for i:=0; i<n; i+=1 {
		for k:=0; k<d; k+=1 {
			if !field(input[at],-32,32) do return -1
			points[i*MAX_D+k]=input[at]; at+=1
		}
	}
	if output==nil || output_capacity<c.size_t(n+4) do return -2
	c_value:=f64(c_milli)/1000.0
	bias:=f64(0.0); changed:=0; passes:=0; examine_all:=true
	for passes<pass_cap && (changed>0 || examine_all) {
		changed=0
		for j:=0; j<n; j+=1 {
			if (examine_all || (alpha[j]>0 && alpha[j]<c_value)) && examine(j,alpha[:],&bias,c_value,labels[:],points[:],n,d) { changed+=1 }
		}
		passes+=1
		if examine_all { examine_all=false } else if changed==0 { examine_all=true }
	}
	var staged:[MAX_N+4]f64
	staged[0]=f64(passes); staged[1]=f64(changed)
	staged[2] = if passes < pass_cap && changed == 0 && !examine_all { 1.0 } else { 0.0 }
	for i:=0; i<n; i+=1 { staged[3+i]=alpha[i] }
	staged[3+n]=bias
	for i:=0; i<n+4; i+=1 { output[i]=staged[i] }
	return i64(n+4)
}
