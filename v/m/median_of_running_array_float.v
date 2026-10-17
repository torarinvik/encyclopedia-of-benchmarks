module median_of_running_array_float

import math

const max_count = 64
const max_input_length = 66

fn less_float(left f32, right f32) bool {
	if left < right { return true }
	if left == 0.0 && right == 0.0 { return (math.f32_bits(left) >> 31) != 0 && (math.f32_bits(right) >> 31) == 0 }
	return false
}
fn push_max(mut heap [64]f32, mut count int, value f32) { mut p:=count;count++;for p>0&&less_float(heap[(p-1)/2],value){parent:=(p-1)/2;heap[p]=heap[parent];p=parent};heap[p]=value }
fn pop_max(mut heap [64]f32, mut count int) f32 { result:=heap[0];count--;value:=heap[count];if count==0{return result};mut p:=0;for 2*p+1<count{mut child:=2*p+1;if child+1<count&&less_float(heap[child],heap[child+1]){child++};if !less_float(value,heap[child]){break};heap[p]=heap[child];p=child};heap[p]=value;return result }
fn push_min(mut heap [64]f32, mut count int, value f32) { mut p:=count;count++;for p>0&&less_float(value,heap[(p-1)/2]){parent:=(p-1)/2;heap[p]=heap[parent];p=parent};heap[p]=value }
fn pop_min(mut heap [64]f32, mut count int) f32 { result:=heap[0];count--;value:=heap[count];if count==0{return result};mut p:=0;for 2*p+1<count{mut child:=2*p+1;if child+1<count&&less_float(heap[child+1],heap[child]){child++};if !less_float(heap[child],value){break};heap[p]=heap[child];p=child};heap[p]=value;return result }

@[export: 'median_of_running_array_float']
pub fn median_of_running_array_float(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	unsafe {
		count_value:=input[0]
		if !count_value.is_finite()||count_value<1.0||count_value>f64(max_count)||f64(int(count_value))!=count_value||length!=usize(1+int(count_value)){return -1}
		count:=int(count_value);mut lower:=[64]f32{};mut upper:=[64]f32{};mut medians:=[64]f32{};mut lc:=0;mut uc:=0
		for i in 0..count{sample:=input[i+1];if !sample.is_finite()||sample < -1000000.0||sample>1000000.0{return -1};x:=f32(sample);if f64(x)!=sample||(sample==0.0&&(math.bits_from_f64(sample)>>63)!=(u64(math.f32_bits(x))>>31)){return -1}
			if uc>0&&less_float(x,upper[0]){push_max(mut lower,mut lc,x)}else{push_min(mut upper,mut uc,x)}
			if lc>uc+1{push_min(mut upper,mut uc,pop_max(mut lower,mut lc))}else if uc>lc+1{push_max(mut lower,mut lc,pop_min(mut upper,mut uc))}
			if lc>uc{medians[i]=lower[0]}else if uc>lc{medians[i]=upper[0]}else{sum:=f32(lower[0]+upper[0]);average:=f32(sum/2.0);medians[i]=average}}
		if unsafe { output == nil }||capacity<usize(count){return -2};for i in 0..count{output[i]=f64(medians[i])};return i64(count)
	}
}
