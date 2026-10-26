module paq8p_context_mixer

// Copyright (C) 2008 Matt Mahoney, Serge Osnach, Alexander Ratushnyak, Bill Pettis, Przemyslaw Skibinski, Matthew Fite, wowtiger, Andrew Paterson, Jan Ondrus, Andreas Morphis, Pavel L. Holoborodko, KZ.
// This program is free software; redistribute and/or modify it under the GNU
// General Public License as published by the Free Software Foundation, either
// version 2 or (at your option) any later version. It is provided without any
// warranty, including merchantability or fitness for a particular purpose.
// See https://www.gnu.org/licenses/ for details.
const st = [33]i32{1,2,3,6,10,16,27,45,73,120,194,310,488,747,1101,1546,2047,2549,2994,3348,3607,3785,3901,3975,4022,4050,4068,4079,4085,4089,4092,4093,4094}

fn squash(d0 i32) i32 {
	if d0 > 2047 { return 4095 }
	if d0 < -2047 { return 0 }
	w := d0 & 127
	d := (d0 >> 7) + 16
	return (st[d] * (128-w) + st[d+1] * w + 64) >> 7
}

fn make_stretch(mut t [4096]i32) {
	mut pi := 0
	for x := -2047; x <= 2047; x++ {
		end := int(squash(i32(x)))
		for j := pi; j <= end; j++ { t[j] = i32(x) }
		pi = end + 1
	}
	t[4095] = 2047
}

fn dot8(t [8]i32, w [8]i32) i32 {
	mut sum := i32(0)
	for i := 0; i < 8; i += 2 { sum += (t[i]*w[i] + t[i+1]*w[i+1]) >> 8 }
	return sum
}

fn train8(t [8]i32, mut w [8]i32, err i32) {
	for i := 0; i < 8; i++ {
		mut value := w[i] + (((t[i]*err*2 >> 16) + 1) >> 1)
		if value < -32768 { value = -32768 }
		if value > 32767 { value = 32767 }
		w[i] = value
	}
}

@[export: 'paq8p_context_mixer']
pub fn paq8p_context_mixer(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 12 || length > 177 { return -1 }
		count := input[0]
		if count < 1 || count > 16 || int(length) != 1 + int(count)*11 { return -1 }
		mut features := [16][8]i32{}
		mut c0 := [16]i32{}
		mut c1 := [16]i32{}
		mut targets := [16]i32{}
		mut p := 1
		for s := 0; s < int(count); s++ {
			if input[p] < 0 || input[p] > 1 || input[p+1] < 0 || input[p+1] > 1 || input[p+2] < 0 || input[p+2] > 1 { return -1 }
			c0[s] = i32(input[p]); c1[s] = i32(input[p+1]); targets[s] = i32(input[p+2]); p += 3
			for j := 0; j < 8; j++ { if input[p] < -2047 || input[p] > 2047 { return -1 }; features[s][j] = i32(input[p]); p++ }
		}
		needed := int(count)*2
		if output == nil || capacity < usize(needed) { return -2 }
		mut stretch := [4096]i32{}
		make_stretch(mut stretch)
		mut outer := [4][8]i32{}
		mut inner := [8]i32{}
		for i := 0; i < 8; i++ { inner[i] = 32767 }
		mut previous_inner := [8]i32{}
		mut previous_prediction := i32(2048)
		mut previous_target := i32(0)
		for s := 0; s < int(count); s++ {
			if s > 0 { train8(previous_inner, mut inner, ((previous_target << 12)-previous_prediction)*7) }
			contexts := [2]int{int(c0[s]), 2+int(c1[s])}
			mut model := [2]i32{}
			for k := 0; k < 2; k++ { model[k] = squash(dot8(features[s], outer[contexts[k]]) >> 5) }
			x := [8]i32{stretch[model[0]], stretch[model[1]], 0, 0, 0, 0, 0, 0}
			prediction := squash(dot8(x, inner) >> 8)
			output[s*2] = u8(prediction & 255); output[s*2+1] = u8((prediction >> 8) & 255)
			for k := 0; k < 2; k++ { train8(features[s], mut outer[contexts[k]], ((targets[s] << 12)-model[k])*7) }
			previous_inner = x; previous_prediction = prediction; previous_target = targets[s]
		}
		return i64(needed)
	}
}
