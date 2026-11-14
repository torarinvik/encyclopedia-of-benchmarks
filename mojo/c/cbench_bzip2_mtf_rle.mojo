# Altered, independently written bounded implementation of a bzip2 coding stage.
# This program, "bzip2", the associated library "libbzip2", and all
# documentation, are copyright (C) 1996-2006 Julian R Seward. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. The origin of this software must not be misrepresented; you must not claim
#    that you wrote the original software. If you use this software in a product,
#    an acknowledgment in the product documentation would be appreciated but is
#    not required.
# 3. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 4. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# Julian Seward, Cambridge, UK. jseward@bzip.org
# bzip2/libbzip2 version 1.0.4 of 20 December 2006
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_bzip2_mtf_rle")
fn cbench_bzip2_mtf_rle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 68: return -1
    var result = List[UInt8](capacity=33)
    if input[0] == 0:
        if input[1] != 0 or input[2] < 1 or input[2] > 32: return -1
        let count = Int(input[2])
        if length != c_size_t(3 + count): return -1
        var alphabet = List[Int](capacity=32)
        for i in range(count):
            let value = input[3+i]
            if value < 0 or value > 255: return -1
            var present = False
            for item in alphabet:
                if item == Int(value): present = True
            if not present: alphabet.append(Int(value))
        for i in range(1, len(alphabet)):
            let item = alphabet[i]
            var j = i
            while j > 0 and alphabet[j-1] > item:
                alphabet[j] = alphabet[j-1]
                j -= 1
            alphabet[j] = item
        let eob = len(alphabet) + 1
        var zeros = 0
        for i in range(count):
            let value = Int(input[3+i])
            var rank = 0
            while alphabet[rank] != value: rank += 1
            if rank == 0:
                zeros += 1
                continue
            if zeros > 0:
                var code = zeros - 1
                while True:
                    result.append(UInt8(code & 1))
                    if code < 2: break
                    code = (code - 2) // 2
                zeros = 0
            result.append(UInt8(rank + 1))
            let moved = alphabet[rank]
            while rank > 0:
                alphabet[rank] = alphabet[rank-1]
                rank -= 1
            alphabet[0] = moved
        if zeros > 0:
            var code = zeros - 1
            while True:
                result.append(UInt8(code & 1))
                if code < 2: break
                code = (code - 2) // 2
        result.append(UInt8(eob))
    elif input[0] == 1:
        if input[1] < 1 or input[1] > 32 or input[2] < 2 or input[2] > 33: return -1
        let n = Int(input[1]); let tokens = Int(input[2])
        if length != c_size_t(3 + n + tokens): return -1
        var alphabet = List[Int](capacity=n)
        for i in range(n):
            let value = input[3+i]
            if value < 0 or value > 255 or (i > 0 and input[2+i] >= value): return -1
            alphabet.append(Int(value))
        let start = 3 + n
        let eob = n + 1
        for i in range(tokens):
            let token = input[start+i]
            if token < 0 or token > Int64(eob) or (i+1 < tokens and token == Int64(eob)): return -1
        if input[start+tokens-1] != Int64(eob): return -1
        var pos = 0
        while pos < tokens - 1:
            let token = Int(input[start+pos])
            if token <= 1:
                var count = 0
                var weight = 1
                while pos < tokens - 1:
                    let digit = Int(input[start+pos])
                    if digit > 1: break
                    if weight > 32: return -1
                    count += (digit + 1) * weight
                    if count + len(result) > 32: return -1
                    weight *= 2
                    pos += 1
                for _ in range(count): result.append(UInt8(alphabet[0]))
            else:
                let rank = token - 1
                if rank >= n or len(result) >= 32: return -1
                let value = alphabet[rank]
                result.append(UInt8(value))
                var j = rank
                while j > 0:
                    alphabet[j] = alphabet[j-1]
                    j -= 1
                alphabet[0] = value
                pos += 1
        if len(result) == 0: return -1
    else:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(result)): return -2
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
