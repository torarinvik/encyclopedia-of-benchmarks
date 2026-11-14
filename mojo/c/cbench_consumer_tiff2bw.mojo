# Copyright (c) 1988-1997 Sam Leffler
# Copyright (c) 1991-1997 Silicon Graphics, Inc.
#
# Permission to use, copy, modify, distribute, and sell this software and
# its documentation for any purpose is hereby granted without fee, provided
# that (i) the above copyright notices and this permission notice appear in
# all copies of the software and related documentation, and (ii) the names of
# Sam Leffler and Silicon Graphics may not be used in any advertising or
# publicity relating to the software without the specific, prior written
# permission of Sam Leffler and Silicon Graphics.
#
# THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
# EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
# WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
#
# IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
# ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
# LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THIS SOFTWARE.
# Independently written bounded RGB-to-gray profile.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_tiff2bw")
fn cbench_consumer_tiff2bw(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 193: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let count = Int(input[0])
    if length != c_size_t(1+3*count): return -1
    for i in range(1, Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count):
        let base = 1+3*i
        let gray = 71*input[base] + 150*input[base+1] + 28*input[base+2]
        output[i] = UInt8(gray >> 8)
    return Int64(count)
