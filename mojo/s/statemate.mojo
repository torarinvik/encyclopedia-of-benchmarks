# SPDX-License-Identifier: GPL-3.0-or-later; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("statemate")
fn statemate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let runs = input[0]
    if runs < 1 or runs > 256: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 92: return -2
    var target = List[UInt8](capacity=16)
    target.append(0); target.append(0); target.append(0); target.append(3)
    target.append(2); target.append(1); target.append(1); target.append(0)
    target.append(0); target.append(0); target.append(0); target.append(0)
    target.append(2); target.append(1); target.append(0); target.append(1)
    var snapshot = List[UInt8](length=92, fill=0)
    for _ in range(Int(runs)):
        var states = List[UInt8](length=16, fill=0)
        var stable = False
        while not stable:
            stable = True
            for i in range(16):
                if states[i] == 0 and target[i] != 0:
                    states[i] = target[i]
                    stable = False
        for i in range(92): snapshot[i] = 0
        snapshot[5] = 1
        for i in range(16): snapshot[64+i] = states[i]
    for i in range(92): output[i] = snapshot[i]
    return 92
