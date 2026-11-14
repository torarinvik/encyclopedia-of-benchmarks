# SPDX-License-Identifier: GPL-3.0-or-later; see package NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("xgboost")
fn xgboost(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 64: return -1
    for i in range(64):
        if input[i] < 0 or input[i] > 255: return -1
    var thresholds = List[Int64](capacity=18)
    thresholds.append(100); thresholds.append(100); thresholds.append(100)
    thresholds.append(128); thresholds.append(120); thresholds.append(110)
    thresholds.append(90); thresholds.append(140); thresholds.append(80)
    thresholds.append(110); thresholds.append(100); thresholds.append(200)
    thresholds.append(150); thresholds.append(150); thresholds.append(150)
    thresholds.append(70); thresholds.append(130); thresholds.append(180)
    var leaves = List[Int](capacity=24)
    leaves.append(1); leaves.append(0); leaves.append(0); leaves.append(2)
    leaves.append(0); leaves.append(2); leaves.append(1); leaves.append(0)
    leaves.append(0); leaves.append(1); leaves.append(2); leaves.append(0)
    leaves.append(1); leaves.append(0); leaves.append(0); leaves.append(2)
    leaves.append(2); leaves.append(0); leaves.append(1); leaves.append(0)
    leaves.append(0); leaves.append(2); leaves.append(1); leaves.append(0)
    var left = List[Int](capacity=18)
    var right = List[Int](capacity=18)
    for _ in range(6):
        left.append(1); left.append(128); left.append(130)
        right.append(2); right.append(129); right.append(131)
    var votes = List[Int](length=3, fill=0)
    for tree in range(6):
        let base = tree*3
        var node = 0
        while (node & 128) == 0:
            let at = base+node
            if input[at] < thresholds[at]:
                node = left[at]
            else:
                node = right[at]
        votes[tree//2] += leaves[tree*4+(node & 127)]
    var best = 0
    for class_id in range(1,3):
        if votes[class_id] > votes[best]: best = class_id
    return Int64(best)
