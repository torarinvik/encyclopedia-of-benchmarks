module elf_hash

const max_codepoints = 8

@[export: 'elf_hash']
pub fn elf_hash(input &i64, length usize) i64 {
    if length > max_codepoints { return -1 }
    unsafe {
        mut hash := u64(0)
        for index in 0 .. int(length) {
            codepoint := input[index]
            if codepoint < 0 || codepoint > 127 { return -1 }
            hash = (hash << 4) + u64(codepoint)
            high := hash & u64(0xF0000000)
            if high != 0 { hash = hash ^ (high >> 24) }
            hash = hash ^ high
        }
        return i64(hash)
    }
}
