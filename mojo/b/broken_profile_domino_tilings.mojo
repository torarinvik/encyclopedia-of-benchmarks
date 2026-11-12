from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime BPD_STATES = 256
comptime BPD_MOD: Int64 = 998_244_353

@export("broken_profile_domino_tilings")
fn broken_profile_domino_tilings(v: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let h0 = v[0]; let w0 = v[1]
    if h0 < 1 or h0 > 64 or w0 < 1 or w0 > 64 or min(h0,w0) > 8 or h0*w0 > 512: return -1
    let height = Int(max(h0,w0)); let width = Int(min(h0,w0))
    let states = 1 << width; let full = states - 1
    var dp = InlineArray[Int64, 256](fill=0); var next = InlineArray[Int64, 256](fill=0)
    dp[0] = 1
    for row in range(height):
        for s in range(states): next[s] = 0
        for incoming in range(states):
            if dp[incoming] != 0:
                for outgoing in range(states):
                    if (incoming & outgoing) != 0 or (row + 1 == height and outgoing != 0): continue
                    let free = full & ~(incoming | outgoing)
                    var col = 0; var valid = True
                    while col < width:
                        if ((free >> col) & 1) != 0:
                            if col + 1 >= width or ((free >> (col+1)) & 1) == 0:
                                valid = False; break
                            col += 2
                        else: col += 1
                    if valid: next[outgoing] = (next[outgoing] + dp[incoming]) % BPD_MOD
        dp = next
    return dp[0]
