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
# Independent bounded corner detector draft; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn corner_round(value: Float32) -> Int:
    if value < 0.0: return Int(Float64(value) - 0.5)
    return Int(Float64(value) + 0.5)

@export("cbench_automotive_susan_c")
fn cbench_automotive_susan_c(input: UnsafePointer[Int64, ImmutAnyOrigin],
                            length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin],
                            capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    if input[0] < 11 or input[0] > 16: return -1
    let side = Int(input[0])
    let size = side * side
    if length != c_size_t(size + 1): return -1
    var image = InlineArray[Int, 256](fill=0)
    for i in range(size):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
        image[i] = Int(input[i + 1])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(size): return -2

    var lookup = InlineArray[Int, 513](fill=0)
    for i in range(513):
        var delta = i - 256
        if delta < 0: delta = -delta
        let scaled = Float64(delta) / 20.0
        let square = scaled * scaled
        lookup[i] = Int(100.0 * exp(-(square * square * square)))
    var response = InlineArray[Int, 256](fill=0)
    for y in range(5, side - 5):
        for x in range(5, side - 5):
            let center = image[y * side + x]
            var area = 100
            var gx = 0
            var gy = 0
            for dy in range(-3, 4):
                var radius = 3
                if dy == -3 or dy == 3: radius = 1
                elif dy == -2 or dy == 2: radius = 2
                for dx in range(-radius, radius + 1):
                    if dx == 0 and dy == 0: continue
                    let weight = lookup[center - image[(y + dy) * side + x + dx] + 256]
                    area += weight
                    gx += dx * weight
                    gy += dy * weight
            if area >= 1850 or gx * gx + gy * gy <= area * area // 2: continue
            var ax = gx
            var ay = gy
            if ax < 0: ax = -ax
            if ay < 0: ay = -ay
            var along = 0
            if ay * ay < ax * ax:
                let slope = Float32(gy) / Float32(ax)
                var direction = 1
                if gx < 0: direction = -1
                for step in range(1, 4):
                    let row = y + corner_round(Float32(step) * slope)
                    let col = x + step * direction
                    along += lookup[center - image[row * side + col] + 256]
            else:
                let slope = Float32(gx) / Float32(ay)
                var direction = 1
                if gy < 0: direction = -1
                for step in range(1, 4):
                    let row = y + step * direction
                    let col = x + corner_round(Float32(step) * slope)
                    along += lookup[center - image[row * side + col] + 256]
            if along > 290: response[y * side + x] = 1850 - area

    var corners = InlineArray[Int, 256](fill=0)
    var count = 0
    for y in range(5, side - 5):
        for x in range(5, side - 5):
            let strength = response[y * side + x]
            if strength == 0: continue
            var maximum = True
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if dx == 0 and dy == 0: continue
                    let other = response[(y + dy) * side + x + dx]
                    if dy < 0 or (dy == 0 and dx < 0):
                        if strength <= other: maximum = False
                    elif strength < other: maximum = False
            if maximum:
                corners[count] = y * side + x
                count += 1
    for i in range(count):
        let center = corners[i]
        for dy in range(-1, 2):
            for dx in range(-1, 2): image[center + dy * side + dx] = 255
        image[center] = 0
    for i in range(size): output[i] = UInt8(image[i])
    return Int64(size)
