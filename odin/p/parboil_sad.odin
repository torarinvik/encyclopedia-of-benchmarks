package parboil_sad

import "core:c"

SAD_RANGE :: 16
SAD_DIM :: 33
SAD_POS :: 1089
SAD_PAD :: 1092
SAD_SLOTS :: 44772
TYPE_COUNT :: [8]int{0, 1, 2, 2, 4, 8, 8, 16}
TYPE_OFFSET :: [8]int{0, 0, 1, 3, 5, 9, 17, 25}

pixel :: proc "contextless" (values: [^]i64, image, y, x: int) -> int {
	packed := u32(values[image*64+y*4+x/4])
	return int((packed >> ((x%4)*8)) & 255)
}

@(export)
parboil_sad :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 128 do return -1
	for i := 0; i < 128; i += 1 {
		if values[i] < 0 || values[i] > 4_294_967_295 do return -1
	}

	sads: [SAD_SLOTS]u16 = {}
	for py := -SAD_RANGE; py <= SAD_RANGE; py += 1 {
		for px := -SAD_RANGE; px <= SAD_RANGE; px += 1 {
			for by := 0; by < 4; by += 1 {
				for bx := 0; bx < 4; bx += 1 {
					base := (TYPE_OFFSET[7]+by*4+bx)*SAD_PAD
					pos := (py+SAD_RANGE)*SAD_DIM+px+SAD_RANGE
					sad: u32 = 0
					for y := 0; y < 4; y += 1 {
						for x := 0; x < 4; x += 1 {
							fy, fx := by*4+y, bx*4+x
							ry, rx := fy+py, fx+px
							if ry < 0 do ry = 0
							if ry > 15 do ry = 15
							if rx < 0 do rx = 0
							if rx > 15 do rx = 15
							delta := pixel(values, 0, fy, fx)-pixel(values, 1, ry, rx)
							if delta < 0 do sad += u32(-delta) else sad += u32(delta)
						}
					}
					sads[base+pos] = u16(sad)
				}
			}
		}
	}

	// Source larger_sads hierarchy: types 6, 5, 4, 3, 2, then 1.
	for by := 0; by < 2; by += 1 { for bx := 0; bx < 4; bx += 1 {
		dst, src := TYPE_OFFSET[6]+4*by+bx, TYPE_OFFSET[7]+8*by+bx
		for p := 0; p < SAD_POS; p += 1 { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+4)*SAD_PAD+p] }
	} }
	for by := 0; by < 4; by += 1 { for bx := 0; bx < 2; bx += 1 {
		dst, src := TYPE_OFFSET[5]+2*by+bx, TYPE_OFFSET[7]+4*by+2*bx
		for p := 0; p < SAD_POS; p += 1 { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p] }
	} }
	for by := 0; by < 2; by += 1 { for bx := 0; bx < 2; bx += 1 {
		dst, src := TYPE_OFFSET[4]+2*by+bx, TYPE_OFFSET[5]+4*by+bx
		for p := 0; p < SAD_POS; p += 1 { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p] }
	} }
	for bx := 0; bx < 2; bx += 1 {
		dst, src := TYPE_OFFSET[3]+bx, TYPE_OFFSET[4]+bx
		for p := 0; p < SAD_POS; p += 1 { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+2)*SAD_PAD+p] }
	}
	for by := 0; by < 2; by += 1 {
		dst, src := TYPE_OFFSET[2]+by, TYPE_OFFSET[4]+2*by
		for p := 0; p < SAD_POS; p += 1 { sads[dst*SAD_PAD+p] = sads[src*SAD_PAD+p] + sads[(src+1)*SAD_PAD+p] }
	}
	for p := 0; p < SAD_POS; p += 1 { sads[TYPE_OFFSET[1]*SAD_PAD+p] = sads[TYPE_OFFSET[2]*SAD_PAD+p] + sads[(TYPE_OFFSET[2]+1)*SAD_PAD+p] }

	checksum: i64 = 0
	for kind := 1; kind <= 7; kind += 1 { for block := 0; block < TYPE_COUNT[kind]; block += 1 {
		for p := 0; p < SAD_POS; p += 1 { checksum += i64(sads[(TYPE_OFFSET[kind]+block)*SAD_PAD+p]) }
	} }
	return checksum
}
