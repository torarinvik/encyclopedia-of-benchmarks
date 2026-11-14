# Bounded MISR simulation; source provenance is recorded in the package README.
from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn misr_random(mut state: UInt64) -> UInt64:
    let low = state & 0xffffff
    let upper = state >> 24
    let partial = (upper * 0xece66d) & 0xffffff
    state = (low * 0x5deece66d + (partial << 24) + 11) & 0xffffffffffff
    return state >> 17

fn misr_unsigned(mut result: List[UInt8], number: Int):
    var digits = InlineArray[UInt8, 20](fill=0)
    var n = number
    var count = 0
    while True:
        digits[count] = UInt8(48 + n % 10); count += 1; n //= 10
        if n == 0: break
    while count > 0:
        count -= 1; result.append(digits[count])

@export("mcgill_misr")
fn mcgill_misr(experiments: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if experiments < 1 or experiments > 1000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var state = UInt64(1)
    var clean = InlineArray[UInt8, 10](fill=1)
    clean[0] = 0
    var different = 0
    for _ in range(Int(experiments)):
        var faulty = clean
        for _ in range(10):
            let saved_clean = clean[0]; let saved_faulty = faulty[0]
            var bits = misr_random(state)
            for cell in range(9):
                clean[cell] = UInt8((UInt64(clean[cell+1]) + bits) & 1)
                if misr_random(state) % 1000 < 250: bits ^= 1
                faulty[cell] = UInt8((UInt64(faulty[cell+1]) + bits) & 1)
                bits >>= 1
            bits = misr_random(state)
            clean[9] = UInt8((UInt64(saved_clean) + bits) & 1)
            if misr_random(state) % 10000 < 2500: bits ^= 1
            faulty[9] = UInt8((UInt64(saved_faulty) + bits) & 1)
        var differs = False
        for cell in range(10):
            if clean[cell] != faulty[cell]: differs = True
        if differs: different += 1
    var staged = List[UInt8]()
    for b in "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n 10 10 2.500e-01 ".as_bytes(): staged.append(b)
    misr_unsigned(staged, Int(experiments))
    for b in " 1000000000 1 0 0 ".as_bytes(): staged.append(b)
    let same = Int(experiments) - different
    var mantissa = 0; var exponent = 0
    if same != 0:
        var scale = 1
        while same*scale < Int(experiments):
            scale *= 10; exponent -= 1
        let numerator = same*scale*100000000
        mantissa = numerator // Int(experiments)
        let rem = numerator % Int(experiments)
        if 2*rem > Int(experiments) or (2*rem == Int(experiments) and (mantissa & 1) != 0): mantissa += 1
        if mantissa == 1000000000:
            mantissa = 100000000; exponent += 1
    staged.append(UInt8(48 + mantissa // 100000000)); staged.append(46)
    var fraction = mantissa % 100000000
    var place = 10000000
    for _ in range(8):
        staged.append(UInt8(48 + fraction // place))
        fraction %= place; place //= 10
    staged.append(101)
    if exponent < 0: staged.append(45); exponent = -exponent
    else: staged.append(43)
    staged.append(UInt8(48 + exponent // 10)); staged.append(UInt8(48 + exponent % 10)); staged.append(10)
    if capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
