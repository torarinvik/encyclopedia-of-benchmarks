# Independent bounded declarator parser; source provenance is in the package README.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cdecl_peek(src: List[Int], mut cursor: List[Int]) -> Int:
    while cursor[0] < len(src):
        let c = src[cursor[0]]
        if c != 32 and c != 9 and c != 10 and c != 13: return c
        cursor[0] += 1
    return -1

fn cdecl_consume(src: List[Int], mut cursor: List[Int], wanted: Int) -> Bool:
    if cdecl_peek(src,cursor) != wanted: return False
    cursor[0] += 1
    return True

fn cdecl_word(src: List[Int], mut cursor: List[Int], mut word: List[Int]) -> Bool:
    let first = cdecl_peek(src,cursor)
    if not ((first >= 65 and first <= 90) or (first >= 97 and first <= 122) or first == 95): return False
    while cursor[0] < len(src):
        let c = src[cursor[0]]
        if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95): break
        if len(word) >= 16: return False
        word.append(c); cursor[0] += 1
    return True

fn cdecl_type_word(word: List[Int]) -> Int:
    if len(word) == 3:
        if word[0] == 105 and word[1] == 110 and word[2] == 116: return 2
    if len(word) == 4:
        if word[0] == 99 and word[1] == 104 and word[2] == 97 and word[3] == 114: return 1
        if word[0] == 118 and word[1] == 111 and word[2] == 105 and word[3] == 100: return 5
    if len(word) == 5:
        if word[0] == 102 and word[1] == 108 and word[2] == 111 and word[3] == 97 and word[4] == 116: return 3
    if len(word) == 6:
        if word[0] == 100 and word[1] == 111 and word[2] == 117 and word[3] == 98 and word[4] == 108 and word[5] == 101: return 4
    return 0

fn cdecl_read_type(src: List[Int], mut cursor: List[Int]) -> Int:
    var word = List[Int](capacity=16)
    if not cdecl_word(src,cursor,word): return 0
    return cdecl_type_word(word)

fn cdecl_parse(src: List[Int], mut cursor: List[Int], mut name: List[Int],
               mut kinds: List[Int], mut values: List[Int], mut args: List[Int], depth: Int) -> Bool:
    if depth > 6: return False
    var stars = 0
    while cdecl_consume(src,cursor,42):
        stars += 1
        if stars > 8: return False
    if cdecl_consume(src,cursor,40):
        if not cdecl_parse(src,cursor,name,kinds,values,args,depth+1) or not cdecl_consume(src,cursor,41): return False
    else:
        if len(name) != 0 or not cdecl_word(src,cursor,name): return False
    while True:
        let c = cdecl_peek(src,cursor)
        if c == 91:
            cursor[0] += 1
            let first = cdecl_peek(src,cursor)
            if first < 48 or first > 57: return False
            var dimension = 0
            while cursor[0] < len(src):
                let digit = src[cursor[0]]
                if digit < 48 or digit > 57: break
                dimension = dimension*10+digit-48
                if dimension > 99: return False
                cursor[0] += 1
            if dimension < 1 or not cdecl_consume(src,cursor,93) or len(kinds) >= 12: return False
            kinds.append(2); values.append(dimension)
            for _ in range(6): args.append(0)
        elif c == 40:
            cursor[0] += 1
            var types = List[Int](capacity=3)
            var pointers = List[Int](capacity=3)
            if not cdecl_consume(src,cursor,41):
                while True:
                    if len(types) >= 3: return False
                    let typ = cdecl_read_type(src,cursor)
                    if typ == 0: return False
                    var ptrs = 0
                    while cdecl_consume(src,cursor,42):
                        ptrs += 1
                        if ptrs > 8: return False
                    types.append(typ); pointers.append(ptrs)
                    if cdecl_consume(src,cursor,41): break
                    if not cdecl_consume(src,cursor,44): return False
            if len(types) == 1 and types[0] == 5 and pointers[0] == 0:
                _ = types.pop(); _ = pointers.pop()
            else:
                for i in range(len(types)):
                    if types[i] == 5 and pointers[i] == 0: return False
            if len(kinds) >= 12: return False
            kinds.append(3); values.append(len(types))
            for i in range(3):
                if i < len(types): args.append(types[i]); args.append(pointers[i])
                else: args.append(0); args.append(0)
        else: break
    for _ in range(stars):
        if len(kinds) >= 12: return False
        kinds.append(1); values.append(0)
        for _ in range(6): args.append(0)
    return True

@export("prolangs_c_cdecl")
fn prolangs_c_cdecl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 96: return -1
    var src = List[Int](capacity=Int(length))
    for i in range(Int(length)):
        if input[i] <= 0 or input[i] > 127: return -1
        src.append(Int(input[i]))
    var cursor = List[Int](length=1, fill=0)
    let base = cdecl_read_type(src,cursor)
    if base == 0: return -1
    var name = List[Int](capacity=16)
    var kinds = List[Int](capacity=12)
    var values = List[Int](capacity=12)
    var args = List[Int](capacity=72)
    if not cdecl_parse(src,cursor,name,kinds,values,args,0) or cdecl_peek(src,cursor) != -1: return -1
    if cdecl_type_word(name) != 0 or (base == 5 and len(kinds) == 0): return -1
    var current = 0
    var is_void = base == 5
    for reverse_i in range(len(kinds)):
        let kind = kinds[len(kinds)-1-reverse_i]
        if kind == 2:
            if current == 3 or (current == 0 and is_void): return -1
            current = 2; is_void = False
        elif kind == 3:
            if current == 2 or current == 3: return -1
            current = 3; is_void = False
        else:
            current = 1; is_void = False
    var encoded = List[UInt8](capacity=128)
    encoded.append(UInt8(base)); encoded.append(UInt8(len(name)))
    for c in name: encoded.append(UInt8(c))
    encoded.append(UInt8(len(kinds)))
    for i in range(len(kinds)):
        encoded.append(UInt8(kinds[i]))
        if kinds[i] == 2: encoded.append(UInt8(values[i]))
        elif kinds[i] == 3:
            encoded.append(UInt8(values[i]))
            for j in range(2*values[i]): encoded.append(UInt8(args[6*i+j]))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(encoded)): return -2
    for i in range(len(encoded)): output[i] = encoded[i]
    return Int64(len(encoded))
