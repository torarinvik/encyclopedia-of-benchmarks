# SPDX-License-Identifier: GPL-3.0-or-later; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("nsichneu")
fn nsichneu(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 9: return -1
    let runs = input[0]
    if runs < 1 or runs > 64: return -1
    var p1 = List[Int64](capacity=3)
    var p2 = List[Int64](capacity=5)
    for i in range(8):
        let value = input[1+i]
        if value < -1000 or value > 1000: return -1
        if i < 3: p1.append(value)
        else: p2.append(value)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 136: return -2
    var p3 = List[Int64](length=6, fill=0)
    var count1 = 3
    var count2 = 5
    var count3 = 0
    for _ in range(Int(runs)):
        count1 = 3; count2 = 5; count3 = 0
        for a in range(3):
            for b in range(3):
                if b == a: continue
                for c in range(3):
                    if c == a or c == b: continue
                    if count1 >= 3 and count3+3 <= 6 and p1[b] == p1[c] and p1[a] < p1[b]:
                        count1 -= 3
                        p3[count3] = p1[a]; p3[count3+1] = p1[b]; p3[count3+2] = p1[a]-p1[b]
                        count3 += 3
        for omitted_number in range(5):
            let omitted = 4-omitted_number
            var subset = List[Int](capacity=4)
            for i in range(5):
                if i != omitted: subset.append(i)
            for a in range(4):
                for b in range(4):
                    if b == a: continue
                    for c in range(4):
                        if c == a or c == b: continue
                        for d in range(4):
                            if d == a or d == b or d == c: continue
                            let x = p2[subset[a]]; let y = p2[subset[b]]
                            if count2 >= 4 and count3+3 <= 6 and y == p2[subset[c]] and y == p2[subset[d]] and y > x:
                                count2 -= 4
                                p3[count3] = x; p3[count3+1] = y; p3[count3+2] = x+y
                                count3 += 3
    var fields = List[Int64](capacity=17)
    fields.append(Int64(count1))
    for value in p1: fields.append(value)
    fields.append(Int64(count2))
    for value in p2: fields.append(value)
    fields.append(Int64(count3))
    for value in p3: fields.append(value)
    for i in range(17):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return 136
