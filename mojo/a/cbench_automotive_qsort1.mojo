# Modified bounded profile of cBench automotive_qsort1. The upstream
# directory states that the application is GPL, without identifying a version.
# qsort.c copyright (C) 2002 Michael Ringgaard. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_automotive_qsort1")
fn cbench_automotive_qsort1(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 385: return -1
    if input[0] < 1 or input[0] > 128: return -1
    let n = Int(input[0])
    if length != c_size_t(1+3*n): return -1
    var coords = InlineArray[Int64, 384](fill=0)
    var squared = InlineArray[Int64, 128](fill=0)
    var score = InlineArray[Float64, 128](fill=0.0)
    var order = InlineArray[Int, 128](fill=0)
    for i in range(n):
        var sum: Int64 = 0
        for axis in range(3):
            let value = input[1+3*i+axis]
            if value < -1000000 or value > 1000000: return -1
            coords[3*i+axis] = value; sum += value*value
        for j in range(i):
            if squared[j] == sum: return -1
        squared[i] = sum; score[i] = sqrt(Float64(sum)); order[i] = i
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(12*n): return -2
    var lows = InlineArray[Int, 128](fill=0); var highs = InlineArray[Int, 128](fill=0)
    var stack = 1
    lows[0] = 0; highs[0] = n-1
    while stack > 0:
        stack -= 1
        let lo = lows[stack]; let hi = highs[stack]
        if hi <= lo: continue
        if hi-lo+1 <= 8:
            var last = hi
            while last > lo:
                var largest = lo
                for i in range(lo+1, last+1):
                    if score[order[i]] > score[order[largest]]: largest = i
                let temp = order[largest]; order[largest] = order[last]; order[last] = temp
                last -= 1
            continue
        let mid = lo+(hi-lo+1)//2
        var temp = order[mid]; order[mid] = order[lo]; order[lo] = temp
        var left = lo; var right = hi+1
        while True:
            left += 1
            while left <= hi and score[order[left]] <= score[order[lo]]: left += 1
            right -= 1
            while right > lo and score[order[right]] >= score[order[lo]]: right -= 1
            if right < left: break
            temp = order[left]; order[left] = order[right]; order[right] = temp
        temp = order[lo]; order[lo] = order[right]; order[right] = temp
        if right > lo+1:
            lows[stack] = lo; highs[stack] = right-1; stack += 1
        if left < hi:
            lows[stack] = left; highs[stack] = hi; stack += 1
    for i in range(n):
        for axis in range(3):
            # Masking preserves the little-endian two's-complement i32 bits.
            let bits = UInt64(coords[3*order[i]+axis] & 0xffffffff)
            for byte in range(4): output[12*i+4*axis+byte] = UInt8((bits >> (8*byte)) & 255)
    return Int64(12*n)
