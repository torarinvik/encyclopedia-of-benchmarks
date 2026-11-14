# Copyright (c) 1988, 1989, 1990, Regents of the University of California.
# All rights reserved.
#
# Use and copying of this software and preparation of derivative works
# based upon this software are permitted. However, any distribution of
# this software or derivative works must include the above copyright
# notice.
#
# This software is made available AS IS, and neither the Electronics
# Research Laboratory or the University of California make any warranty
# about the software, its performance or its conformity to any
# specification.
#
# Independent bounded Boolean cover draft; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn espresso_coverage(fixed: Int, value: Int, size: Int) -> UInt64:
    var coverage: UInt64 = 0
    for point in range(size):
        if (point & fixed) == value: coverage |= UInt64(1) << UInt(point)
    return coverage

@export("mallocbench_espresso")
fn mallocbench_espresso(input: UnsafePointer[Int64, ImmutAnyOrigin],
                       length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    if input[0] < 1 or input[0] > 5 or input[1] < 0 or input[2] < 0: return -1
    let variables = Int(input[0])
    let size = 1 << variables
    let universe = (UInt64(1) << UInt(size)) - 1
    let onset = UInt64(input[1])
    let dont_care = UInt64(input[2])
    if ((onset | dont_care) & ~universe) != 0 or (onset & dont_care) != 0: return -1
    let allowed = onset | dont_care
    var fixed = InlineArray[Int, 32](fill=0)
    var covers = InlineArray[UInt64, 32](fill=0)
    var active = InlineArray[Bool, 32](fill=False)
    var count = 0
    for point in range(size):
        if (onset & (UInt64(1) << UInt(point))) == 0: continue
        var mask = size - 1
        var pattern = point
        for bit in range(variables):
            let candidate = mask & ~(1 << bit)
            let candidate_pattern = pattern & candidate
            let covered = espresso_coverage(candidate, candidate_pattern, size)
            if (covered & ~allowed) == 0:
                mask = candidate
                pattern = candidate_pattern
        fixed[count] = mask
        covers[count] = espresso_coverage(mask, pattern, size)
        active[count] = True
        count += 1
    for i in range(count):
        var other_coverage: UInt64 = 0
        for j in range(count):
            if i != j and active[j]: other_coverage |= covers[j]
        if (covers[i] & onset & ~other_coverage) == 0: active[i] = False
    var cubes: Int64 = 0
    var literals: Int64 = 0
    for i in range(count):
        if not active[i]: continue
        cubes += 1
        for bit in range(variables):
            if (fixed[i] & (1 << bit)) != 0: literals += 1
    return cubes * 1024 + literals
