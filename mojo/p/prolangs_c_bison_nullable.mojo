# Part of the Bison parser generator,
# Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.
#
# BISON is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY.  No author or distributor accepts responsibility to anyone
# for the consequences of using it or for whether it serves any
# particular purpose or works at all, unless he says so in writing.
# Refer to the BISON General Public License for full details.
#
# Everyone is granted permission to copy, modify and redistribute BISON,
# but only under the conditions described in the BISON General Public
# License.  A copy of this license is supposed to have been given to you
# along with BISON so you can know your rights and responsibilities. It
# should be in a file named COPYING. Among other things, the copyright
# notice and this notice must be preserved on all copies.
#
# In other words, you are welcome to use, share and improve this program.
# You are forbidden to forbid anyone else to use, share and improve
# what you give them. Help stamp out software-hoarding!
#
# Modified 2026: bounded numeric grammar adapter; no upstream code is copied.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("prolangs_c_bison_nullable")
fn prolangs_c_bison_nullable(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 323: return -1
    if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 16 or input[2] < 1 or input[2] > 32: return -1
    let n = Int(input[0]); let terminals = Int(input[1]); let rules = Int(input[2])
    var lhs = InlineArray[Int, 32](fill=0)
    var starts = InlineArray[Int, 32](fill=0)
    var sizes = InlineArray[Int, 32](fill=0)
    var remaining = InlineArray[Int, 32](fill=0)
    var eligible = InlineArray[Bool, 32](fill=False)
    var rhs = InlineArray[Int, 256](fill=0)
    var used = 0
    var offset = 3
    for rule in range(rules):
        if offset + 2 > Int(length): return -1
        let target = input[offset]; let count = input[offset+1]
        if target < 0 or target >= Int64(n) or count < 0 or count > 8: return -1
        offset += 2
        let size = Int(count)
        if offset + size > Int(length): return -1
        lhs[rule] = Int(target); starts[rule] = used; sizes[rule] = size
        var has_terminal = False
        for _ in range(size):
            let symbol = input[offset]
            offset += 1
            if symbol < 0 or symbol >= Int64(n + terminals): return -1
            rhs[used] = Int(symbol)
            used += 1
            if symbol >= Int64(n): has_terminal = True
        if size > 0 and not has_terminal:
            eligible[rule] = True
            remaining[rule] = size
    if offset != Int(length): return -1
    var nullable = InlineArray[Bool, 16](fill=False)
    var queue = InlineArray[Int, 16](fill=0)
    var tail = 0
    for rule in range(rules):
        if sizes[rule] == 0 and not nullable[lhs[rule]]:
            nullable[lhs[rule]] = True
            queue[tail] = lhs[rule]
            tail += 1
    var head = 0
    while head < tail:
        let symbol = queue[head]
        head += 1
        for rule in range(rules):
            if not eligible[rule]: continue
            for i in range(sizes[rule]):
                if rhs[starts[rule]+i] == symbol:
                    remaining[rule] -= 1
                    if remaining[rule] == 0 and not nullable[lhs[rule]]:
                        nullable[lhs[rule]] = True
                        queue[tail] = lhs[rule]
                        tail += 1
    var result: Int64 = 0
    for i in range(n):
        if nullable[i]: result |= Int64(1) << i
    return result
