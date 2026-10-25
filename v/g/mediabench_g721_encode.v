/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

module mediabench_g721_encode

const max_samples = 16
const power2 = [i64(1), 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384]
const qtab = [i64(-124), 80, 178, 246, 300, 349, 400]
const dqlntab = [i64(-2048), 4, 135, 213, 273, 323, 373, 425, 425, 373, 323, 273, 213, 135, 4, -2048]
const witab = [i64(-12), 18, 41, 64, 112, 198, 355, 1122, 1122, 355, 198, 112, 64, 41, 18, -12]
const fitab = [i64(0), 0, 0, 512, 512, 512, 1536, 3584, 3584, 1536, 512, 512, 512, 0, 0, 0]

struct State {
mut:
	yl i64
	yu i64
	dms i64
	dml i64
	ap i64
	a [2]i64
	b [6]i64
	pk [2]i64
	dq [6]i64
	sr [2]i64
	td i64
}

fn wrap16(value i64) i64 {
	low := u64(value) & u64(0xffff)
	if low >= u64(0x8000) { return i64(low) - 65536 }
	return i64(low)
}
fn qtable(value i64, table []i64) i64 {
	mut count := i64(0)
	for item in table { if value < item { break }; count++ }
	return count
}
fn fmult(coefficient i64, encoded i64) i64 {
	magnitude := if coefficient > 0 { coefficient } else { (-coefficient) & i64(0x1fff) }
	exponent := qtable(magnitude, power2) - 6
	mut mantissa := i64(32)
	if magnitude != 0 { if exponent >= 0 { mantissa = magnitude >> u32(exponent) } else { mantissa = magnitude << u32(-exponent) } }
	product_exponent := exponent + ((encoded >> 6) & 15) - 13
	product_mantissa := (mantissa * (encoded & i64(0o77)) + 0x30) >> 4
	value := if product_exponent >= 0 { (product_mantissa << u32(product_exponent)) & 0x7fff } else { product_mantissa >> u32(-product_exponent) }
	if (coefficient ^ encoded) < 0 { return -value }
	return value
}
fn predictor_zero(s &State) i64 {
	mut sum := fmult(s.b[0] >> 2, s.dq[0])
	for i in 1 .. 6 { sum += fmult(s.b[i] >> 2, s.dq[i]) }
	return sum
}
fn predictor_pole(s &State) i64 { return fmult(s.a[1] >> 2, s.sr[1]) + fmult(s.a[0] >> 2, s.sr[0]) }
fn step_size(s &State) i64 {
	if s.ap >= 256 { return s.yu }
	mut y := s.yl >> 6
	difference := s.yu - y
	weight := s.ap >> 2
	if difference > 0 { y += (difference * weight) >> 6 } else if difference < 0 { y += (difference * weight + 0x3f) >> 6 }
	return y
}
fn quantize(difference i64, step i64) i64 {
	magnitude := if difference < 0 { -difference } else { difference }
	exponent := qtable(magnitude >> 1, power2)
	mantissa := ((magnitude << 7) >> u32(exponent)) & i64(0x7f)
	normalized := ((exponent << 7) + mantissa) - (step >> 2)
	index := qtable(normalized, qtab)
	if difference < 0 { return 15 - index }
	if index == 0 { return 15 }
	return index
}
fn reconstruct(sign i64, dqln i64, step i64) i64 {
	dql := dqln + (step >> 2)
	if dql < 0 { return if sign != 0 { -32768 } else { i64(0) } }
	exponent := (dql >> 7) & 15
	mantissa := 128 + (dql & 127)
	value := (mantissa << 7) >> u32(14 - exponent)
	return if sign != 0 { value - 32768 } else { value }
}
fn abs64(value i64) i64 { return if value < 0 { -value } else { value } }

fn update(step i64, wi i64, fi i64, dq i64, sr i64, dqsez i64, mut s State) {
	mag := dq & i64(0x7fff)
	ylint := s.yl >> 15
	ylfrac := (s.yl >> 10) & 0x1f
	threshold1 := (32 + ylfrac) << u32(ylint)
	threshold2 := if ylint > 9 { i64(31 << 10) } else { threshold1 }
	dqthr := (threshold2 + (threshold2 >> 1)) >> 1
	tr := s.td != 0 && mag > dqthr
	s.yu = wrap16(step + ((wi - step) >> 5))
	if s.yu < 544 { s.yu = 544 } else if s.yu > 5120 { s.yu = 5120 }
	s.yl += s.yu + ((-s.yl) >> 6)
	if tr { s.a = [2]i64{}; s.b = [6]i64{} }
	else {
		pk0 := if dqsez < 0 { i64(1) } else { i64(0) }
		pks1 := pk0 ^ s.pk[0]
		mut a2p := s.a[1] - (s.a[1] >> 7)
		if dqsez != 0 {
			fa1 := if pks1 != 0 { s.a[0] } else { -s.a[0] }
			if fa1 < -8191 { a2p -= 0x100 } else if fa1 > 8191 { a2p += 0xff } else { a2p += fa1 >> 5 }
			if (pk0 ^ s.pk[1]) != 0 {
				if a2p <= -12160 { a2p = -12288 } else if a2p >= 12416 { a2p = 12288 } else { a2p -= 0x80 }
			} else if a2p <= -12416 { a2p = -12288 } else if a2p >= 12160 { a2p = 12288 } else { a2p += 0x80 }
		}
		a2p = wrap16(a2p)
		s.a[1] = a2p
		s.a[0] = wrap16(s.a[0] - (s.a[0] >> 8))
		if dqsez != 0 { s.a[0] = wrap16(s.a[0] + (if pks1 == 0 { i64(192) } else { i64(-192) })) }
		limit := 15360 - a2p
		if s.a[0] < -limit { s.a[0] = -limit } else if s.a[0] > limit { s.a[0] = limit }
		s.a[0] = wrap16(s.a[0])
		for i in 0 .. 6 {
			s.b[i] = wrap16(s.b[i] - (s.b[i] >> 8))
			if (dq & 0x7fff) != 0 { s.b[i] = wrap16(s.b[i] + (if (dq ^ s.dq[i]) >= 0 { i64(128) } else { i64(-128) })) }
		}
	}
	for i := 5; i > 0; i-- { s.dq[i] = s.dq[i - 1] }
	if mag == 0 { s.dq[0] = if dq >= 0 { i64(0x20) } else { wrap16(0xfc20) } }
	else { exponent := qtable(mag, power2); encoded := (exponent << 6) + ((mag << 6) >> u32(exponent)); s.dq[0] = wrap16(if dq >= 0 { encoded } else { encoded - 0x400 }) }
	s.sr[1] = s.sr[0]
	if sr == 0 { s.sr[0] = 0x20 }
	else if sr > 0 { exponent := qtable(sr, power2); s.sr[0] = wrap16((exponent << 6) + ((sr << 6) >> u32(exponent))) }
	else if sr > -32768 { absolute := -sr; exponent := qtable(absolute, power2); s.sr[0] = wrap16((exponent << 6) + ((absolute << 6) >> u32(exponent)) - 0x400) }
	else { s.sr[0] = wrap16(0xfc20) }
	s.pk[1] = s.pk[0]
	s.pk[0] = if dqsez < 0 { 1 } else { 0 }
	s.td = if tr { 0 } else if s.a[1] < -11776 { 1 } else { 0 }
	s.dms = wrap16(s.dms + ((fi - s.dms) >> 5))
	s.dml = wrap16(s.dml + (((fi << 2) - s.dml) >> 7))
	if tr { s.ap = 256 } else if step < 1536 || s.td == 1 || abs64((s.dms << 2) - s.dml) >= (s.dml >> 3) { s.ap = wrap16(s.ap + ((0x200 - s.ap) >> 4)) } else { s.ap = wrap16(s.ap + ((-s.ap) >> 4)) }
}

fn init_state() State {
	mut s := State{yl: 34816, yu: 544, dms: 0, dml: 0, ap: 0, td: 0}
	for i in 0 .. 2 { s.a[i] = 0; s.pk[i] = 0; s.sr[i] = 32 }
	for i in 0 .. 6 { s.b[i] = 0; s.dq[i] = 32 }
	return s
}
fn ulaw_to_linear(input i64) i64 {
	value := (~input) & i64(0xff)
	mut sample := ((value & 15) << 3) + 0x84
	sample <<= u32((value & 0x70) >> 4)
	return if (value & 0x80) != 0 { 0x84 - sample } else { sample - 0x84 }
}
fn encode_one(input i64, mut s State) i64 {
	sample := ulaw_to_linear(input) >> 2
	sezi := wrap16(predictor_zero(s)); sez := sezi >> 1
	se := wrap16((sezi + predictor_pole(s)) >> 1)
	difference := wrap16(sample - se); step := wrap16(step_size(s))
	code := quantize(difference, step); dq := wrap16(reconstruct(code & 8, dqlntab[int(code)], step))
	sr := if dq < 0 { se - (dq & 0x3fff) } else { se + dq }
	sr = wrap16(sr); dqsez := wrap16(sr + sez - se)
	update(step, witab[int(code)] << 5, fitab[int(code)], dq, sr, dqsez, mut s)
	return code
}

@[export: 'mediabench_g721_encode']
pub fn mediabench_g721_encode(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 1 || input_length > max_samples + 1 { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 0 || count_value > max_samples { return -1 }
	count := int(count_value)
	if input_length != usize(count + 1) { return -1 }
	for i in 0 .. count { value := unsafe { input[i + 1] }; if value < 0 || value > 255 { return -1 } }
	required := (count + 1) / 2
	if required == 0 { return 0 }
	if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
	mut state := init_state()
	for i in 0 .. count {
		code := u8(encode_one(unsafe { input[i + 1] }, mut state))
		unsafe { if i % 2 == 0 { output[i / 2] = code } else { output[i / 2] |= code << 4 } }
	}
	return i64(required)
}
