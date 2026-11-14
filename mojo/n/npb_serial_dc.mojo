# NAS Parallel Benchmarks 3.3 DC source notice:
# Permission to use, copy, distribute and modify this software for any purpose
# with or without fee is hereby granted. We request, however, that all derived
# work reference the NAS Parallel Benchmarks 3.3. This software is provided
# "as is" without express or implied warranty.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("npb_serial_dc")
fn npb_serial_dc(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 98: return -1
    let dv = input[0]; let rv = input[1]
    if dv < 1 or dv > 5 or rv < 1 or rv > 16: return -1
    let dims = Int(dv); let rows = Int(rv)
    if length != c_size_t(2+rows*(dims+1)): return -1
    var attrs = List[Int64](capacity=rows*dims)
    var measures = List[Int64](capacity=rows)
    for row in range(rows):
        let base = 2+row*(dims+1)
        for d in range(dims):
            let value = input[base+d]
            if value < 0 or value > 7: return -1
            attrs.append(value)
        let measure = input[base+dims]
        if measure < 0 or measure > 1000: return -1
        measures.append(measure)
    var checksum = Int64(0)
    for mask in range(1,1 << dims):
        var keys = List[Int64](length=rows*dims, fill=0)
        var sums = List[Int64](length=rows, fill=0)
        var groups = 0
        for row in range(rows):
            var group = 0
            while group < groups:
                var equal = True
                for d in range(dims):
                    if (mask & (1 << d)) != 0 and keys[group*dims+d] != attrs[row*dims+d]: equal = False
                if equal: break
                group += 1
            if group == groups:
                for d in range(dims):
                    if (mask & (1 << d)) != 0: keys[group*dims+d] = attrs[row*dims+d]
                sums[group] = measures[row]
                groups += 1
            else: sums[group] += measures[row]
        for i in range(1,groups):
            var pos = i
            while pos > 0:
                var comparison = 0
                for d in range(dims):
                    if (mask & (1 << d)) == 0: continue
                    if keys[pos*dims+d] < keys[(pos-1)*dims+d]:
                        comparison = -1
                        break
                    if keys[pos*dims+d] > keys[(pos-1)*dims+d]:
                        comparison = 1
                        break
                if comparison >= 0: break
                for d in range(dims):
                    let temp = keys[pos*dims+d]
                    keys[pos*dims+d] = keys[(pos-1)*dims+d]
                    keys[(pos-1)*dims+d] = temp
                let temp = sums[pos]
                sums[pos] = sums[pos-1]
                sums[pos-1] = temp
                pos -= 1
        let view = Int64(mask)
        checksum += view*1009+Int64(groups)*9176
        for group in range(groups):
            checksum += (view+1)*Int64(group+1)*(sums[group]+13)
            for d in range(dims):
                if (mask & (1 << d)) != 0:
                    checksum += Int64(d+1)*(keys[group*dims+d]+1)*Int64(group+3)*(view+5)
    return checksum
