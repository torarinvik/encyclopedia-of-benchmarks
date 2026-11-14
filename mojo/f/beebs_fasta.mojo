# Independently written bounded FASTA profile. See package LICENSE.txt and NOTICE.txt.
from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("beebs_fasta")
fn beebs_fasta(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    if input[0] < 1 or input[0] > 1000 or input[1] < 0 or input[1] >= 139968: return -1
    let n = Int(input[0])
    let total = 77 + 10*n + (2*n+59)//60 + (3*n+59)//60 + (5*n+59)//60
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(total): return -2

    # The sequence and probability tables are the profile's input constants.
    var alu = List[UInt8]()
    for b in "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG".as_bytes(): alu.append(b)
    for b in "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA".as_bytes(): alu.append(b)
    for b in "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT".as_bytes(): alu.append(b)
    for b in "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA".as_bytes(): alu.append(b)
    for b in "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG".as_bytes(): alu.append(b)
    for b in "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC".as_bytes(): alu.append(b)
    for b in "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA".as_bytes(): alu.append(b)
    var iub = InlineArray[Float32, 15](fill=Float32(0.02))
    iub[0] = Float32(0.27); iub[1] = Float32(0.12)
    iub[2] = Float32(0.12); iub[3] = Float32(0.27)
    var human = InlineArray[Float32, 4](fill=0)
    human[0] = Float32(0.3029549426680); human[1] = Float32(0.1979883004921)
    human[2] = Float32(0.1975473066391); human[3] = Float32(0.3015094502008)
    var sum = Float32(0)
    for i in range(15):
        sum += iub[i]
        iub[i] = sum
    sum = Float32(0)
    for i in range(4):
        sum += human[i]
        human[i] = sum

    var pos = 0
    for b in ">ONE Homo sapiens alu\n".as_bytes():
        output[pos] = b; pos += 1
    for i in range(2*n):
        output[pos] = alu[i % len(alu)]; pos += 1
        if (i+1) % 60 == 0 or i+1 == 2*n:
            output[pos] = 10; pos += 1
    for b in ">TWO IUB ambiguity codes\n".as_bytes():
        output[pos] = b; pos += 1
    var state = Int(input[1])
    let symbols = "acgtBDHKMNRSVWY".as_bytes()
    for i in range(3*n):
        state = (state*3877 + 29573) % 139968
        let value = Float32(state) / Float32(139968)
        var selected = 0
        while selected < 14 and iub[selected] < value: selected += 1
        output[pos] = symbols[selected]; pos += 1
        if (i+1) % 60 == 0 or i+1 == 3*n:
            output[pos] = 10; pos += 1
    for b in ">THREE Homo sapiens frequency\n".as_bytes():
        output[pos] = b; pos += 1
    let bases = "acgt".as_bytes()
    for i in range(5*n):
        state = (state*3877 + 29573) % 139968
        let value = Float32(state) / Float32(139968)
        var selected = 0
        while selected < 3 and human[selected] < value: selected += 1
        output[pos] = bases[selected]; pos += 1
        if (i+1) % 60 == 0 or i+1 == 5*n:
            output[pos] = 10; pos += 1
    return Int64(pos)
