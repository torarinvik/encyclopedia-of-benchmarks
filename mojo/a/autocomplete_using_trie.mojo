from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn autocomplete_word_compare(words: List[Int64], lens: List[Int], first: Int, second: Int) -> Bool:
    let shared = min(lens[first], lens[second])
    for i in range(shared):
        let a = words[first * 16 + i]
        let b = words[second * 16 + i]
        if a < b: return True
        if a > b: return False
    return lens[first] < lens[second]

fn autocomplete_put(output: List[Int64], value: Int64):
    output.append(value)

fn autocomplete_write(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[word * 8 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("autocomplete_using_trie")
fn autocomplete_using_trie(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 32: return -1
    let count = Int(input[0])
    var words = List[Int64](length=512, fill=0)
    var lens = List[Int](length=32, fill=0)
    var pos = 1
    var unique = 0
    for w in range(count):
        if pos >= Int(length): return -1
        let n = input[pos]
        pos += 1
        if n < 1 or n > 16 or pos + Int(n) > Int(length): return -1
        for i in range(Int(n)):
            if input[pos + i] < 97 or input[pos + i] > 122: return -1
        var duplicate = False
        for old in range(unique):
            if lens[old] != Int(n): continue
            var same = True
            for i in range(Int(n)):
                if words[old * 16 + i] != input[pos + i]: same = False
            if same: duplicate = True
        if not duplicate:
            lens[unique] = Int(n)
            for i in range(Int(n)): words[unique * 16 + i] = input[pos + i]
            unique += 1
        pos += Int(n)
    if pos >= Int(length): return -1
    let query_count = input[pos]
    pos += 1
    if query_count < 0 or query_count > 16: return -1
    var queries = List[Int64](length=256, fill=0)
    var qlens = List[Int](length=16, fill=0)
    for q in range(Int(query_count)):
        if pos >= Int(length): return -1
        let n = input[pos]
        pos += 1
        if n < 0 or n > 16 or pos + Int(n) > Int(length): return -1
        qlens[q] = Int(n)
        for i in range(Int(n)):
            let ch = input[pos + i]
            if ch < 97 or ch > 122: return -1
            queries[q * 16 + i] = ch
        pos += Int(n)
    if pos != Int(length): return -1
    var encoded = List[Int64](capacity=9000)
    encoded.append(query_count)
    for q in range(Int(query_count)):
        var matches = List[Int](capacity=32)
        for w in range(unique):
            if lens[w] < qlens[q]: continue
            var match = True
            for i in range(qlens[q]):
                if words[w * 16 + i] != queries[q * 16 + i]: match = False
            if match: matches.append(w)
        for i in range(1, len(matches)):
            let item = matches[i]
            var j = i
            while j > 0 and autocomplete_word_compare(words, lens, item, matches[j - 1]):
                matches[j] = matches[j - 1]
                j -= 1
            matches[j] = item
        encoded.append(Int64(len(matches)))
        for j in range(len(matches)):
            let w = matches[j]
            encoded.append(Int64(lens[w]))
            for c in range(lens[w]): encoded.append(words[w * 16 + c])
    let bytes = len(encoded) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(encoded)): autocomplete_write(output, i, encoded[i])
    return Int64(bytes)
