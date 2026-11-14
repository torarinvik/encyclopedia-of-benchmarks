# /**********************************************************************\
#   SUSAN Version 2l by Stephen Smith
#   Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
#   Department of Clinical Neurology, Oxford University, Oxford, UK
#   (Previously in Computer Vision and Image Processing Group - now
#   Computer Vision and Electro Optics Group - DERA Chertsey, UK)
#   Email:    steve@fmrib.ox.ac.uk
#   WWW:      http://www.fmrib.ox.ac.uk/~steve
#   (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
#   Farnborough, Hampshire, GU14 6TD, UK
#   DERA WWW site:
#   http://www.dera.gov.uk/
#   DERA Computer Vision and Electro Optics Group WWW site:
#   http://www.dera.gov.uk/imageprocessing/dera/group_home.html
#   DERA Computer Vision and Electro Optics Group point of contact:
#   Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
#   A UK patent has been granted: "Method for digitally processing
#   images to determine the position of edges and/or corners therein for
#   guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
#   Secretary of State for Defence, UK. 15 January 1997
#
#   This code is issued for research purposes only and remains the
#   property of the UK Secretary of State for Defence. This code must
#   not be passed on without this header information being kept
#   intact. This code must not be sold.
# \**********************************************************************/
#
# Independent bounded smoothing draft; see package README for restrictions.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn susan_reflect(index: Int, side: Int) -> Int:
    if index < 0: return -index - 1
    if index >= side: return 2 * side - index - 1
    return index

@export("mibench_automotive_susan")
fn mibench_automotive_susan(input: UnsafePointer[Int64, ImmutAnyOrigin],
                            length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin],
                            capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    if input[0] < 15 or input[0] > 16: return -1
    let side = Int(input[0])
    let size = side * side
    if length != c_size_t(size + 1): return -1
    var image = InlineArray[Int, 256](fill=0)
    for i in range(size):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
        image[i] = Int(input[i + 1])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(size): return -2

    var brightness = InlineArray[Int, 511](fill=0)
    for i in range(511):
        let delta = Float32(i - 255) / Float32(20.0)
        let square = Float32(delta * delta)
        let weight = Float32(100.0 * exp(-Float64(square)))
        brightness[i] = Int(weight)
    var distance = InlineArray[Int, 225](fill=0)
    for y in range(-7, 8):
        for x in range(-7, 8):
            distance[15 * (y + 7) + x + 7] = Int(100.0 * exp(Float64(x * x + y * y) / -16.0))

    for y in range(side):
        for x in range(side):
            let center = image[y * side + x]
            var weight_sum = 0
            var weighted = 0
            for dy in range(-7, 8):
                let row = susan_reflect(y + dy, side)
                for dx in range(-7, 8):
                    let column = susan_reflect(x + dx, side)
                    let sample = image[row * side + column]
                    let weight = distance[15 * (dy + 7) + dx + 7] * brightness[center - sample + 255]
                    weight_sum += weight
                    weighted += weight * sample
            let denominator = weight_sum - 10000
            var result = 0
            if denominator != 0:
                result = (weighted - center * 10000) // denominator
            else:
                var neighbors = InlineArray[Int, 8](fill=0)
                var used = 0
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        if dy == 0 and dx == 0: continue
                        let value = image[susan_reflect(y + dy, side) * side + susan_reflect(x + dx, side)]
                        var pos = used
                        while pos > 0 and neighbors[pos - 1] > value:
                            neighbors[pos] = neighbors[pos - 1]
                            pos -= 1
                        neighbors[pos] = value
                        used += 1
                result = (neighbors[3] + neighbors[4]) // 2
            output[y * side + x] = UInt8(result)
    return Int64(size)
