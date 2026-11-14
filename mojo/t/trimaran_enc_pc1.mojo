# Pukall Cipher 1 adaptation; source author Alexander Pukall (1991).
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn pc1_step(mut words: List[Int], index: Int, mut state: List[Int]) -> Int:
    var dx = (state[1] + index) & 65535
    var ax = words[index]
    var cx = 0x015a
    let bx = 0x4e35
    var tmp = ax
    ax = state[0]; state[0] = tmp
    tmp = ax; ax = dx; dx = tmp
    if ax != 0: ax = (ax * bx) & 65535
    tmp = ax; ax = cx; cx = tmp
    if ax != 0:
        ax = (ax * state[0]) & 65535
        cx = (cx + ax) & 65535
    tmp = ax; ax = state[0]; state[0] = tmp
    ax = (ax * bx) & 65535
    dx = (dx + cx) & 65535
    ax = (ax + 1) & 65535
    state[1] = dx; words[index] = ax
    return ax ^ dx

@export("trimaran_enc_pc1")
fn trimaran_enc_pc1(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let count = input[0]
    if count < 1 or count > 2049: return -1
    var key = List[Int]()
    for i in range(26): key.append(97 + i)
    for i in range(6): key.append(48 + i)
    var words = List[Int](length=16, fill=0)
    var state = List[Int](length=2, fill=0)
    var seed = UInt64(1)
    var last = 0
    for _ in range(Int(count - 1)):
        seed = (seed * 1664525 + 1013904223) & 0xffffffff
        let plain = Int((seed >> 16) & 0x7fff)
        words[0] = (key[0] << 8) | key[1]
        var inter = pc1_step(words, 0, state)
        for i in range(1, 16):
            words[i] = words[i - 1] ^ ((key[2 * i] << 8) | key[2 * i + 1])
            inter ^= pc1_step(words, i, state)
        last = plain ^ ((inter >> 8) ^ (inter & 255))
        for i in range(32): key[i] ^= plain & 255
    return Int64(last)
