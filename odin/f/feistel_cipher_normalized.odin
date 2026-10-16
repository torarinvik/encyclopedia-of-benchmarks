package feistel_cipher_normalized
import "core:c"
import "core:runtime"

round_key :: proc(key: u32, round: u32) -> u32 {
    p := u32(1)
    for i := u32(0); i < round+2; i += 1 {
        p *= key
    }
    return p ~ key
}

feistel_f :: proc(initial: u32, key: u32) -> u32 {
    x := initial
    for i := 0; i < 32; i += 1 {
        x = ((x ~ 0x55555555) * x) % key
        x ~= key
    }
    return x
}

@(export)
feistel_cipher_normalized :: proc "c" (a: [^]i64, n: c.size_t) -> i64 {
    context = runtime.default_context()
    if a == nil || n != 3 do return -1
    if a[0] < 0 || a[0] > 1 || a[1] < 1 || u64(a[1]) > 0xffffffff do return -1
    key := u32(a[1])
    for i := u32(0); i < 32; i += 1 {
        if round_key(key, i) == 0 do return -1
    }
    bits := u64(a[2])
    left := u32(bits >> 32)
    right := u32(bits)
    if a[0] == 0 {
        for i := u32(0); i < 32; i += 1 {
            t := right ~ feistel_f(left, round_key(key, i))
            right = left
            left = t
        }
    } else {
        for step := 0; step < 32; step += 1 {
            i := u32(31-step)
            t := left ~ feistel_f(right, round_key(key, i))
            left = right
            right = t
        }
    }
    return i64((u64(left) << 32) | u64(right))
}
