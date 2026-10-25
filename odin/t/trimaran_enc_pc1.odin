// Pukall Cipher 1 adaptation; source author Alexander Pukall (1991), unrestricted use.
package trimaran_enc_pc1
import "core:c"

MAX_NUM_INPUT :: i64(2049)
State :: struct { words: [16]u16, si, x1a2: u16 }

code_step :: proc(s: ^State, index: u16) -> u16 {
    dx := u16(u32(s.x1a2) + u32(index))
    ax := s.words[index]
    cx := u16(0x015a); bx := u16(0x4e35)
    tmp := ax; ax = s.si; s.si = tmp; tmp = ax; ax = dx; dx = tmp
    if ax != 0 { ax = u16(u32(ax) * u32(bx)) }
    tmp = ax; ax = cx; cx = tmp
    if ax != 0 { ax = u16(u32(ax) * u32(s.si)); cx = u16(u32(ax) + u32(cx)) }
    tmp = ax; ax = s.si; s.si = tmp
    ax = u16(u32(ax) * u32(bx)); dx = u16(u32(cx) + u32(dx)); ax = u16(u32(ax) + 1)
    s.x1a2 = dx; s.words[index] = ax
    return ax ~ dx
}

assemble :: proc(s: ^State, key: [32]u8) -> u16 {
    s.words[0] = (u16(key[0]) << 8) | u16(key[1])
    inter := code_step(s, 0)
    for i: u16 = 1; i < 16; i += 1 {
        word := (u16(key[2*i]) << 8) | u16(key[2*i+1])
        s.words[i] = s.words[i-1] ~ word
        inter = inter ~ code_step(s, i)
    }
    return inter
}

@(export)
trimaran_enc_pc1 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 1 || input[0] < 1 || input[0] > MAX_NUM_INPUT do return -1
    key: [32]u8 = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
                   'q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5'}
    state: State
    seed: u32 = 1
    last: u16 = 0
    for step: i64 = 0; step < input[0] - 1; step += 1 {
        seed = u32((u64(seed) * 1664525 + 1013904223) & 0xffffffff)
        plain := u16((seed >> 16) & 0x7fff)
        inter := assemble(&state, key)
        cipher := plain ~ ((inter >> 8) ~ (inter & 255))
        feedback := u8(plain & 255)
        for i in 0..<32 { key[i] = key[i] ~ feedback }
        last = cipher
    }
    return i64(last)
}
