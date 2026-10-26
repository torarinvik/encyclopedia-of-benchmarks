package prolangs_c_simulator_format3_4

import "core:c"

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@(export)
prolangs_c_simulator_format3_4 :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n != 7 do return -1
	pc, x, b := v[0], v[1], v[2]
	if pc < 0 || pc > 1048572 || x < 0 || x >= 16777216 || b < 0 || b >= 16777216 do return -1
	for j in 3..<7 { if v[j] < 0 || v[j] > 255 do return -1 }
	byte0, byte1, byte2, byte3 := int(v[3]), int(v[4]), int(v[5]), int(v[6])
	nf, inf := (byte0 >> 1)&1, byte0&1
	xf, bf, pf, ef := (byte1>>7)&1, (byte1>>6)&1, (byte1>>5)&1, (byte1>>4)&1
	sic := nf == 0 && inf == 0
	fmt: i64 = 3
	if ef == 1 && !sic do fmt = 4
	nextpc := pc + fmt
	address: i64 = 0
	if fmt == 4 {
		if bf != 0 || pf != 0 do return -1
		address = i64((byte1&15)<<16 | byte2<<8 | byte3)
		if xf != 0 do address += x
	} else {
		address = i64((byte1&15)<<8 | byte2)
		if sic do return 0
		if bf != 0 && pf != 0 do return -1
		if xf != 0 do address += x
		if bf != 0 do address += b
		if pf != 0 { if address >= 2048 do address = address-4096+nextpc else do address += nextpc }
	}
	if nf == 1 && inf == 0 do return -1
	if address < 0 do return -1
	if nf == 0 && inf == 1 && address >= 16777216 do return -1
	return address
}
