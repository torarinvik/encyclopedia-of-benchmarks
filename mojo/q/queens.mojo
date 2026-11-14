# McGill count-only N-queens search and launcher-shaped text output.
from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn queens_search(n: Int, level: Int, mut files: List[Int], mut forward: List[Int], mut backward: List[Int]) -> Int64:
    if level == n: return 1
    var solutions = Int64(0)
    for file in range(n):
        let f = file+level
        let b = level-file+n-1
        if files[file] >= level and forward[f] >= level and backward[b] >= level:
            files[file] = level; forward[f] = level; backward[b] = level
            solutions += queens_search(n,level+1,files,forward,backward)
            files[file] = 101; forward[f] = 101; backward[b] = 101
    return solutions

fn queens_text(mut buffer: List[UInt8], text: String):
    for byte in text.as_bytes(): buffer.append(byte)

fn queens_number(mut buffer: List[UInt8], value: Int64):
    var digits = List[UInt8](capacity=20)
    var remaining = value
    while True:
        digits.append(UInt8(48+remaining%10))
        remaining //= 10
        if remaining == 0: break
    var i = len(digits)
    while i > 0:
        i -= 1
        buffer.append(digits[i])

@export("queens")
fn queens(nv: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if nv < 1 or nv > 14: return -1
    let n = Int(nv)
    var files = List[Int](capacity=n)
    var forward = List[Int](capacity=2*n-1)
    var backward = List[Int](capacity=2*n-1)
    for _ in range(n): files.append(101)
    for _ in range(2*n-1):
        forward.append(101); backward.append(101)
    let count = queens_search(n,0,files,forward,backward)
    var text = List[UInt8](capacity=80)
    queens_number(text,nv)
    if n == 1: queens_text(text," queen on a ")
    else: queens_text(text," queens on a ")
    queens_number(text,nv)
    text.append(120)
    queens_number(text,nv)
    queens_text(text," board...\n")
    if count == 1: queens_text(text,"...there is 1 solution\n")
    else:
        queens_text(text,"...there are ")
        queens_number(text,count)
        queens_text(text," solutions\n")
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(text)): return -2
    for i in range(len(text)): output[i] = text[i]
    return Int64(len(text))
