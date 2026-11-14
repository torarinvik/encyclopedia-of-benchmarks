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
# Independently written bounded grayscale diffusion profile.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn diffusion_quotient(value: Int) -> Int:
    if value < 0: return -((-value)//16)
    return value//16

@export("cbench_tiffdither")
fn cbench_tiffdither(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 515: return -1
    if input[0] < 1 or input[0] > 32 or input[1] < 2 or input[1] > 16 or input[2] < 0 or input[2] > 255: return -1
    let width = Int(input[0]); let height = Int(input[1]); let threshold = Int(input[2])
    let pixels = width*height
    if length != c_size_t(3+pixels): return -1
    var work = InlineArray[Int, 512](fill=0)
    for i in range(pixels):
        if input[3+i] < 0 or input[3+i] > 255: return -1
        work[i] = Int(input[3+i])
    let stride = (width+7)//8
    let bytes = stride*(height-1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = InlineArray[UInt8, 60](fill=0)
    for y in range(height-1):
        for x in range(width):
            let at = y*width+x
            var value = work[at]
            if value < 0: value = 0
            elif value > 255: value = 255
            if value > threshold:
                staged[y*stride+x//8] |= UInt8(0x80 >> (x%8))
                value -= 255
            if x+1 < width: work[at+1] += diffusion_quotient(value*7)
            if y+2 < height:
                if x > 0: work[at+width-1] += diffusion_quotient(value*3)
                work[at+width] += diffusion_quotient(value*5)
                if x+1 < width: work[at+width+1] += diffusion_quotient(value)
    for i in range(bytes): output[i] = staged[i]
    return Int64(bytes)
