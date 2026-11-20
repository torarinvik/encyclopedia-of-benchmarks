from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias CV2_MAX_TEXT = 64
alias CV2_SCRATCH = 128
alias CV2_BYTES = 10

fn cv2_match(text: InlineArray[UInt8, CV2_SCRATCH], at: Int, length: Int,
        a: Int, b: Int, c: Int, d: Int, old_len: Int) -> Bool:
    if at + old_len > length: return False
    if old_len > 0 and text[at] != UInt8(a): return False
    if old_len > 1 and text[at + 1] != UInt8(b): return False
    if old_len > 2 and text[at + 2] != UInt8(c): return False
    if old_len > 3 and text[at + 3] != UInt8(d): return False
    return True

fn cv2_match5(text: InlineArray[UInt8, CV2_SCRATCH], at: Int, length: Int,
        a: Int, b: Int, c: Int, d: Int, e: Int) -> Bool:
    return at + 5 <= length and cv2_match(text, at, length, a, b, c, d, 4) and text[at + 4] == UInt8(e)

fn cv2_match6(text: InlineArray[UInt8, CV2_SCRATCH], at: Int, length: Int,
        a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) -> Bool:
    return at + 6 <= length and cv2_match5(text, at, length, a, b, c, d, e) and text[at + 5] == UInt8(f)

fn cv2_replace_all(inout text: InlineArray[UInt8, CV2_SCRATCH], inout length: Int,
        a: Int, b: Int, c: Int, d: Int, old_len: Int,
        x: Int, y: Int, z: Int, w: Int) -> None:
    var next = InlineArray[UInt8, CV2_SCRATCH](fill=0)
    var out = 0
    var at = 0
    while at < length:
        if cv2_match(text, at, length, a, b, c, d, old_len):
            next[out] = UInt8(x)
            if old_len > 1: next[out + 1] = UInt8(y)
            if old_len > 2: next[out + 2] = UInt8(z)
            if old_len > 3: next[out + 3] = UInt8(w)
            out += old_len
            at += old_len
        else:
            next[out] = text[at]
            out += 1
            at += 1
    text = next
    length = out

fn cv2_prefix(inout text: InlineArray[UInt8, CV2_SCRATCH], inout length: Int,
        a: Int, b: Int, c: Int, d: Int, old_len: Int,
        x: Int, y: Int, z: Int, w: Int) -> None:
    if not cv2_match(text, 0, length, a, b, c, d, old_len): return
    if old_len > 0: text[0] = UInt8(x)
    if old_len > 1: text[1] = UInt8(y)
    if old_len > 2: text[2] = UInt8(z)
    if old_len > 3: text[3] = UInt8(w)

fn cv2_suffix(inout text: InlineArray[UInt8, CV2_SCRATCH], length: Int,
        a: Int, b: Int, old_len: Int, x: Int, y: Int) -> None:
    if length < old_len: return
    let at = length - old_len
    if not cv2_match(text, at, length, a, b, 0, 0, old_len): return
    text[at] = UInt8(x)
    if old_len > 1: text[at + 1] = UInt8(y)

fn cv2_char(inout text: InlineArray[UInt8, CV2_SCRATCH], length: Int, old: Int, replacement: Int) -> None:
    for i in range(length):
        if text[i] == UInt8(old): text[i] = UInt8(replacement)

fn cv2_squeeze(inout text: InlineArray[UInt8, CV2_SCRATCH], inout length: Int, letter: Int, marker: Int) -> None:
    var out = 0
    for i in range(length):
        if text[i] == UInt8(letter) and out > 0 and text[out - 1] == UInt8(marker): continue
        if text[i] == UInt8(letter): text[out] = UInt8(marker)
        else: text[out] = text[i]
        out += 1
    length = out

fn cv2_encode(input: UnsafePointer[Int64, ImmutAnyOrigin]) -> InlineArray[UInt8, CV2_BYTES]:
    var text = InlineArray[UInt8, CV2_SCRATCH](fill=0)
    var n = Int(input[0])
    for i in range(n):
        var code = Int(input[i + 1])
        if code >= 65 and code <= 90: code += 32
        text[i] = UInt8(code)
    var result = InlineArray[UInt8, CV2_BYTES](fill=UInt8(49))
    if n == 0: return result
    if text[n - 1] == UInt8(101): n -= 1
    if cv2_match5(text, 0, n, 99,111,117,103,104):
        text[0]=99; text[1]=111; text[2]=117; text[3]=50; text[4]=102
    elif cv2_match5(text, 0, n, 114,111,117,103,104):
        text[0]=114; text[1]=111; text[2]=117; text[3]=50; text[4]=102
    elif cv2_match5(text, 0, n, 116,111,117,103,104):
        text[0]=116; text[1]=111; text[2]=117; text[3]=50; text[4]=102
    elif cv2_match6(text, 0, n, 101,110,111,117,103,104):
        text[0]=101; text[1]=110; text[2]=111; text[3]=117; text[4]=50; text[5]=102
    elif cv2_match6(text, 0, n, 116,114,111,117,103,104):
        text[0]=116; text[1]=114; text[2]=111; text[3]=117; text[4]=50; text[5]=102
    if cv2_match(text, 0, n, 103,110,0,0,2): text[0]=50; text[1]=110
    cv2_suffix(text, n, 109,98,2, 109,50)
    cv2_replace_all(text,n,99,113,0,0,2,50,113,0,0); cv2_replace_all(text,n,99,105,0,0,2,115,105,0,0)
    cv2_replace_all(text,n,99,101,0,0,2,115,101,0,0); cv2_replace_all(text,n,99,121,0,0,2,115,121,0,0)
    cv2_replace_all(text,n,116,99,104,0,3,50,99,104,0)
    cv2_char(text,n,99,107); cv2_char(text,n,113,107); cv2_char(text,n,120,107); cv2_char(text,n,118,102)
    cv2_replace_all(text,n,100,103,0,0,2,50,103,0,0); cv2_replace_all(text,n,116,105,111,0,3,115,105,111,0)
    cv2_replace_all(text,n,116,105,97,0,3,115,105,97,0); cv2_char(text,n,100,116)
    cv2_replace_all(text,n,112,104,0,0,2,102,104,0,0); cv2_char(text,n,98,112)
    cv2_replace_all(text,n,115,104,0,0,2,115,50,0,0); cv2_char(text,n,122,115)
    if n > 0 and (text[0]==UInt8(97) or text[0]==UInt8(101) or text[0]==UInt8(105) or text[0]==UInt8(111) or text[0]==UInt8(117)): text[0]=UInt8(65)
    for i in range(n):
        if text[i]==UInt8(97) or text[i]==UInt8(101) or text[i]==UInt8(105) or text[i]==UInt8(111) or text[i]==UInt8(117): text[i]=UInt8(51)
    cv2_char(text,n,106,121)
    if cv2_match(text,0,n,121,51,0,0,2): text[0]=UInt8(89)
    else: cv2_prefix(text,n,121,0,0,0,1,65,0,0,0)
    cv2_char(text,n,121,51)
    cv2_replace_all(text,n,51,103,104,51,4,51,107,104,51); cv2_replace_all(text,n,103,104,0,0,2,50,50,0,0)
    cv2_char(text,n,103,107)
    cv2_squeeze(text,n,115,83); cv2_squeeze(text,n,116,84); cv2_squeeze(text,n,112,80); cv2_squeeze(text,n,107,75)
    cv2_squeeze(text,n,102,70); cv2_squeeze(text,n,109,77); cv2_squeeze(text,n,110,78)
    cv2_replace_all(text,n,119,51,0,0,2,87,51,0,0); cv2_replace_all(text,n,119,104,51,0,3,87,104,51,0)
    cv2_suffix(text,n,119,0,1,51,0); cv2_char(text,n,119,50)
    if n > 0 and text[0]==UInt8(104): text[0]=UInt8(65)
    cv2_char(text,n,104,50)
    cv2_replace_all(text,n,114,51,0,0,2,82,51,0,0); cv2_suffix(text,n,114,0,1,51,0); cv2_char(text,n,114,50)
    cv2_replace_all(text,n,108,51,0,0,2,76,51,0,0); cv2_suffix(text,n,108,0,1,51,0); cv2_char(text,n,108,50)
    var out = 0
    for i in range(n):
        if text[i] != UInt8(50): text[out] = text[i]; out += 1
    n = out
    if n > 0 and text[n-1]==UInt8(51): text[n-1]=UInt8(65)
    out = 0
    for i in range(n):
        if text[i] != UInt8(51): text[out] = text[i]; out += 1
    for i in range(min(out,CV2_BYTES)): result[i]=text[i]
    return result

@export("caverphone_2_encoder")
fn caverphone_2_encoder(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(CV2_MAX_TEXT + 1): return -1
    let count = input[0]
    if count < 0 or count > CV2_MAX_TEXT or length != c_size_t(count + 1): return -1
    for i in range(Int(count)):
        let code = input[i + 1]
        if not ((code >= 65 and code <= 90) or (code >= 97 and code <= 122)): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(CV2_BYTES): return -2
    let result = cv2_encode(input)
    for i in range(CV2_BYTES): output[i] = result[i]
    return Int64(CV2_BYTES)
