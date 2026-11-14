# Bounded Parboil 4x4 SAD and hierarchical block aggregation.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn sad_pixel(input: UnsafePointer[Int64, ImmutAnyOrigin], image: Int, y: Int, x: Int) -> Int:
    return Int((input[64*image+4*y+x//4] >> (8*(x%4))) & 255)

@export("parboil_sad")
fn parboil_sad(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 128: return -1
    for i in range(128):
        if input[i] < 0 or input[i] > 4294967295: return -1
    var sads = List[UInt16](capacity=44772)
    for _ in range(44772): sads.append(0)
    for dy in range(-16,17):
        for dx in range(-16,17):
            let position = (dy+16)*33+dx+16
            for by in range(4):
                for bx in range(4):
                    var sad = 0
                    for y in range(4):
                        for x in range(4):
                            let fy = 4*by+y
                            let fx = 4*bx+x
                            var ry = fy+dy
                            var rx = fx+dx
                            if ry < 0: ry = 0
                            if ry > 15: ry = 15
                            if rx < 0: rx = 0
                            if rx > 15: rx = 15
                            let delta = sad_pixel(input,0,fy,fx)-sad_pixel(input,1,ry,rx)
                            if delta < 0: sad -= delta
                            else: sad += delta
                    sads[(25+4*by+bx)*1092+position] = UInt16(sad)
    for by in range(2):
        for bx in range(4):
            let dst = 17+4*by+bx
            let src = 25+8*by+bx
            for p in range(1089): sads[dst*1092+p] = sads[src*1092+p]+sads[(src+4)*1092+p]
    for by in range(4):
        for bx in range(2):
            let dst = 9+2*by+bx
            let src = 25+4*by+2*bx
            for p in range(1089): sads[dst*1092+p] = sads[src*1092+p]+sads[(src+1)*1092+p]
    for by in range(2):
        for bx in range(2):
            let dst = 5+2*by+bx
            let src = 9+4*by+bx
            for p in range(1089): sads[dst*1092+p] = sads[src*1092+p]+sads[(src+2)*1092+p]
    for bx in range(2):
        let dst = 3+bx
        let src = 5+bx
        for p in range(1089): sads[dst*1092+p] = sads[src*1092+p]+sads[(src+2)*1092+p]
    for by in range(2):
        let dst = 1+by
        let src = 5+2*by
        for p in range(1089): sads[dst*1092+p] = sads[src*1092+p]+sads[(src+1)*1092+p]
    for p in range(1089): sads[p] = sads[1092+p]+sads[2184+p]
    var checksum = Int64(0)
    for block in range(41):
        for p in range(1089): checksum += Int64(sads[block*1092+p])
    return checksum
