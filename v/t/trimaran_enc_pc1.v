// Pukall Cipher 1 adaptation; source author Alexander Pukall (1991), unrestricted use.
module trimaran_enc_pc1

const max_num_input = i64(2049)
struct State {
mut:
	words [16]u16
	si u16
	x1a2 u16
}

fn code_step(mut s State, index int) u16 {
	mut dx := u16(u32(s.x1a2) + u32(index))
    mut ax := s.words[index]
    mut cx := u16(0x015a)
    bx := u16(0x4e35)
    mut tmp := ax
    ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp
    if ax != 0 { ax = u16(u32(ax) * u32(bx)) }
    tmp = ax; ax = cx; cx = tmp
	if ax != 0 { ax = u16(u32(ax) * u32(s.si)); cx = u16(u32(ax) + u32(cx)) }
    tmp = ax; ax = s.si; s.si = tmp
	ax = u16(u32(ax) * u32(bx)); dx = u16(u32(cx) + u32(dx)); ax = u16(u32(ax) + 1)
    s.x1a2 = dx; s.words[index] = ax
    return ax ^ dx
}

fn assemble(mut s State, key []u8) u16 {
    s.words[0] = (u16(key[0]) << 8) | u16(key[1])
    mut inter := code_step(mut s, 0)
    for i in 1 .. 16 {
        word := (u16(key[2*i]) << 8) | u16(key[2*i+1])
        s.words[i] = s.words[i-1] ^ word
        inter ^= code_step(mut s, i)
    }
    return inter
}

@[export: 'trimaran_enc_pc1']
pub fn trimaran_enc_pc1(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_num_input { return -1 }
		mut key := 'abcdefghijklmnopqrstuvwxyz012345'.bytes()
		mut state := State{}
		mut seed := u32(1)
		mut last := u16(0)
		for _ in 0 .. int(input[0] - 1) {
			seed = u32((u64(seed) * 1664525 + 1013904223) & u64(0xffffffff))
			plain := u16((seed >> 16) & 0x7fff)
			inter := assemble(mut state, key)
			cipher := plain ^ ((inter >> 8) ^ (inter & 255))
			feedback := u8(plain & 255)
			for i in 0 .. 32 { key[i] ^= feedback }
			last = cipher
		}
		return i64(last)
	}
}
