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
# Independent bounded edge detector draft; see package README for restrictions.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn edge_maximum(response: InlineArray[Int, 256], side: Int, y: Int, x: Int,
                dy: Int, dx: Int) -> Bool:
    let center = response[y * side + x]
    return (center > response[(y + dy) * side + x + dx] and
            center >= response[(y - dy) * side + x - dx] and
            center > response[(y + 2 * dy) * side + x + 2 * dx] and
            center >= response[(y - 2 * dy) * side + x - 2 * dx])

fn edge_response(image: InlineArray[Int, 256], side: Int,
                 mut response: InlineArray[Int, 256], mut middle: InlineArray[Int, 256]):
    var brightness = InlineArray[Int, 513](fill=0)
    for i in range(513):
        var d = i - 256
        if d < 0: d = -d
        let scaled = Float64(d) / 20.0
        let squared = scaled * scaled
        brightness[i] = Int(100.0 * exp(-(squared * squared * squared)))
    for y in range(3, side - 3):
        for x in range(3, side - 3):
            let center = image[y * side + x]
            var area = 100
            for dy in range(-3, 4):
                var radius = 3
                if dy == -3 or dy == 3: radius = 1
                elif dy == -2 or dy == 2: radius = 2
                for dx in range(-radius, radius + 1):
                    if dy == 0 and dx == 0: continue
                    area += brightness[center - image[(y + dy) * side + x + dx] + 256]
            if area <= 2650: response[y * side + x] = 2650 - area
    for y in range(4, side - 4):
        for x in range(4, side - 4):
            let index = y * side + x
            let strength = response[index]
            if strength <= 0: continue
            let area = 2650 - strength
            var gx = 0
            var gy = 0
            var mx = 0
            var my = 0
            var cross = 0
            let center = image[index]
            for dy in range(-3, 4):
                var radius = 3
                if dy == -3 or dy == 3: radius = 1
                elif dy == -2 or dy == 2: radius = 2
                for dx in range(-radius, radius + 1):
                    if dy == 0 and dx == 0: continue
                    let weight = brightness[center - image[(y + dy) * side + x + dx] + 256]
                    gx += dx * weight
                    gy += dy * weight
                    mx += dx * dx * weight
                    var absolute_dy = dy
                    if absolute_dy < 0: absolute_dy = -absolute_dy
                    my += dy * absolute_dy * weight
                    cross += dx * dy * weight
            var use_symmetry = True
            if area > 600:
                let magnitude = sqrt(Float32(gx * gx + gy * gy))
                if magnitude > Float32(0.9) * Float32(area):
                    use_symmetry = False
                    var slope = Float32(1000000.0)
                    if gx != 0: slope = Float32(gy) / Float32(gx)
                    var sign = 1
                    if slope < 0.0:
                        sign = -1
                        slope = -slope
                    var dy = 1
                    var dx = 1
                    if slope < 0.5: dy = 0
                    elif slope > 2.0: dx = 0
                    else: dy = sign
                    if edge_maximum(response, side, y, x, dy, dx): middle[index] = 1
            if use_symmetry:
                var slope = Float32(1000000.0)
                if my != 0: slope = Float32(mx) / Float32(my)
                var dy = 1
                var dx = 1
                if slope < 0.5: dy = 0
                elif slope > 2.0: dx = 0
                elif cross > 0: dy = -1
                if edge_maximum(response, side, y, x, dy, dx): middle[index] = 2

fn edge_active(middle: InlineArray[Int, 256], side: Int, y: Int, x: Int) -> Bool:
    return middle[y * side + x] < 8

fn edge_active_int(middle: InlineArray[Int, 256], side: Int, y: Int, x: Int) -> Int:
    if edge_active(middle, side, y, x): return 1
    return 0

fn edge_thin(response: InlineArray[Int, 256], side: Int,
             mut middle: InlineArray[Int, 256]):
    var y = 4
    while y < side - 4:
        var x = 4
        while x < side - 4:
            let center = y * side + x
            if middle[center] < 8:
                var neighbors = InlineArray[Bool, 9](fill=False)
                var count = 0
                var active_index = -1
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        if dx == 0 and dy == 0: continue
                        let index = (dy + 1) * 3 + dx + 1
                        neighbors[index] = edge_active(middle, side, y + dy, x + dx)
                        if neighbors[index]:
                            count += 1
                            if active_index < 0: active_index = index
                if count == 0: middle[center] = 100
                if count == 1 and middle[center] < 6:
                    # Weights favor continuation opposite the existing edge.
                    var weights = InlineArray[Int, 9](fill=1)
                    if active_index == 0: weights = InlineArray[Int, 9](0, 0, 2, 0, 1, 3, 2, 3, 4)
                    elif active_index == 1: weights = InlineArray[Int, 9](0, 0, 0, 2, 0, 2, 3, 4, 3)
                    elif active_index == 2: weights = InlineArray[Int, 9](2, 0, 0, 3, 1, 0, 4, 3, 2)
                    elif active_index == 3: weights = InlineArray[Int, 9](0, 2, 3, 0, 1, 4, 0, 2, 3)
                    elif active_index == 5: weights = InlineArray[Int, 9](3, 2, 0, 4, 1, 0, 3, 2, 0)
                    elif active_index == 6: weights = InlineArray[Int, 9](2, 3, 4, 0, 1, 3, 0, 0, 2)
                    elif active_index == 7: weights = InlineArray[Int, 9](3, 4, 3, 2, 1, 2, 0, 0, 0)
                    elif active_index == 8: weights = InlineArray[Int, 9](4, 3, 2, 3, 1, 0, 2, 0, 0)
                    var best = 0
                    var best_row = 0
                    var best_col = 0
                    for row in range(3):
                        for col in range(3):
                            let index = row * 3 + col
                            var strength = 0
                            if index != 4: strength = response[(y + row - 1) * side + x + col - 1]
                            let candidate = strength * weights[index]
                            if candidate > best:
                                best = candidate
                                best_row = row
                                best_col = col
                    if best > 0:
                        var value = middle[center] + 1
                        if middle[center] < 4: value = 4
                        middle[(y + best_row - 1) * side + x + best_col - 1] = value
                        if 2 * best_row + best_col < 3:
                            y += best_row - 1
                            x += best_col - 2
                            if y < 4: y = 4
                            if x < 4: x = 4
                if count == 2:
                    let nw = edge_active_int(middle, side, y - 1, x - 1)
                    let ne = edge_active_int(middle, side, y - 1, x + 1)
                    let sw = edge_active_int(middle, side, y + 1, x - 1)
                    let se = edge_active_int(middle, side, y + 1, x + 1)
                    if nw + ne + sw + se == 2 and ((nw | se) & (ne | sw)) != 0:
                        var move_x = 0
                        var move_y = 0
                        if nw != 0:
                            if ne != 0: move_y = -1
                            else: move_x = -1
                        elif ne != 0: move_x = 1
                        else: move_y = 1
                        let neighbor = response[(y + move_y) * side + x + move_x]
                        if Float32(neighbor) / Float32(response[center]) > Float32(0.7):
                            var clear = True
                            for offset in range(-1, 2):
                                if move_x == 0:
                                    if edge_active(middle, side, y + 2 * move_y, x + offset): clear = False
                                else:
                                    if edge_active(middle, side, y + offset, x + 2 * move_x): clear = False
                            if clear:
                                middle[center] = 100
                                middle[(y + move_y) * side + x + move_x] = 3
                    else:
                        let n = edge_active_int(middle, side, y - 1, x)
                        let e = edge_active_int(middle, side, y, x + 1)
                        let s = edge_active_int(middle, side, y + 1, x)
                        let w = edge_active_int(middle, side, y, x - 1)
                        var angled = False
                        if n != 0 and (edge_active(middle, side, y - 2, x - 1) or edge_active(middle, side, y - 2, x + 1)): angled = True
                        if w != 0 and (edge_active(middle, side, y - 1, x - 2) or edge_active(middle, side, y + 1, x - 2)): angled = True
                        if e != 0 and (edge_active(middle, side, y - 1, x + 2) or edge_active(middle, side, y + 1, x + 2)): angled = True
                        if s != 0 and (edge_active(middle, side, y + 2, x - 1) or edge_active(middle, side, y + 2, x + 1)): angled = True
                        if n + e + s + w == 2 and ((w | e) & (n | s)) != 0 and angled:
                            middle[center] = 100
                            y -= 1
                            x -= 2
                            if y < 4: y = 4
                            if x < 4: x = 4
                if count > 2:
                    let n = edge_active_int(middle, side, y - 1, x)
                    let e = edge_active_int(middle, side, y, x + 1)
                    let s = edge_active_int(middle, side, y + 1, x)
                    let w = edge_active_int(middle, side, y, x - 1)
                    if n + e + s + w > 1:
                        let nw = edge_active_int(middle, side, y - 1, x - 1)
                        let ne = edge_active_int(middle, side, y - 1, x + 1)
                        let sw = edge_active_int(middle, side, y + 1, x - 1)
                        let se = edge_active_int(middle, side, y + 1, x + 1)
                        let p1 = nw | n
                        let p2 = ne | e
                        let p3 = se | s
                        let p4 = sw | w
                        let connected = p1 + p2 + p3 + p4 - (n & p2) - (e & p3) - (s & p4) - (w & p1)
                        if connected < 2:
                            middle[center] = 100
                            y -= 1
                            x -= 2
                            if y < 4: y = 4
                            if x < 4: x = 4
            x += 1
        y += 1

@export("cbench_automotive_susan_e")
fn cbench_automotive_susan_e(input: UnsafePointer[Int64, ImmutAnyOrigin],
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
    var response = InlineArray[Int, 256](fill=0)
    var middle = InlineArray[Int, 256](fill=100)
    edge_response(image, side, response, middle)
    edge_thin(response, side, middle)
    for y in range(side):
        for x in range(side):
            if middle[y * side + x] < 8:
                for dy in range(-1, 2):
                    for dx in range(-1, 2): image[(y + dy) * side + x + dx] = 255
    for i in range(size):
        if middle[i] < 8: image[i] = 0
        output[i] = UInt8(image[i])
    return Int64(size)
