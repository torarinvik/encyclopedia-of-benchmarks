package paq8p_context_mixer

import "core:c"

// Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
// This program is free software; redistribute and/or modify it under the GNU
// General Public License as published by the Free Software Foundation, either
// version 2 or (at your option) any later version. It is provided without any
// warranty, including merchantability or fitness for a particular purpose.
// See https://www.gnu.org/licenses/ for details.
ST: [33]i32 = {1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094}

squash :: proc(d0: i32) -> i32 {
	if d0 > 2047 do return 4095
	if d0 < -2047 do return 0
	w := d0 & 127
	d := (d0 >> 7) + 16
	return (ST[d] * (128-w) + ST[d+1] * w + 64) >> 7
}
make_stretch :: proc(t: ^[4096]i32) {
	pi := 0
	for x := -2047; x <= 2047; x += 1 { end := squash(i32(x)); for j := pi; j <= int(end); j += 1 { t[j] = i32(x) }; pi = int(end)+1 }
	t[4095] = 2047
}
dot8 :: proc(t, w: [8]i32) -> i32 {
	sum: i32 = 0
	for i := 0; i < 8; i += 2 { sum += (t[i]*w[i] + t[i+1]*w[i+1]) >> 8 }
	return sum
}
train8 :: proc(t: [8]i32, w: ^[8]i32, err: i32) {
	for i := 0; i < 8; i += 1 { value := w[i] + (((t[i]*err*2 >> 16)+1)>>1); if value < -32768 do value=-32768; if value > 32767 do value=32767; w[i]=value }
}

@(export)
paq8p_context_mixer :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 12 || length > 177 do return -1
	count := input[0]
	if count < 1 || count > 16 || int(length) != 1+int(count)*11 do return -1
	features: [16][8]i32
	c0, c1, targets: [16]i32
	p := 1
	for s := 0; s < int(count); s += 1 {
		if input[p] < 0 || input[p] > 1 || input[p+1] < 0 || input[p+1] > 1 || input[p+2] < 0 || input[p+2] > 1 do return -1
		c0[s]=i32(input[p]); c1[s]=i32(input[p+1]); targets[s]=i32(input[p+2]); p+=3
		for j := 0; j < 8; j += 1 { if input[p] < -2047 || input[p] > 2047 do return -1; features[s][j]=i32(input[p]); p+=1 }
	}
	needed := int(count)*2
	if output == nil || int(capacity) < needed do return -2
	stretch: [4096]i32; make_stretch(&stretch)
	outer: [4][8]i32
	inner: [8]i32; for i := 0; i < 8; i += 1 { inner[i]=32767 }
	previous_inner: [8]i32
	previous_prediction: i32=2048; previous_target: i32=0
	for s := 0; s < int(count); s += 1 {
		if s > 0 { train8(previous_inner,&inner,((previous_target<<12)-previous_prediction)*7) }
		contexts := [2]int{int(c0[s]),2+int(c1[s])}
		model: [2]i32
		for k := 0; k < 2; k += 1 { model[k]=squash(dot8(features[s],outer[contexts[k]]) >> 5) }
		x := [8]i32{stretch[model[0]],stretch[model[1]],0,0,0,0,0,0}
		prediction := squash(dot8(x,inner)>>8)
		output[s*2]=u8(prediction&255); output[s*2+1]=u8((prediction>>8)&255)
		for k := 0; k < 2; k += 1 { train8(features[s],&outer[contexts[k]],((targets[s]<<12)-model[k])*7) }
		previous_inner=x; previous_prediction=prediction; previous_target=targets[s]
	}
	return i64(needed)
}
