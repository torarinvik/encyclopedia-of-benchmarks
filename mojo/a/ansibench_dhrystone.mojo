from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

# Bounded public-domain Dhrystone core; see package LICENSE.
fn dh_copy(mut dst: InlineArray[UInt8, 31], text: String):
    var i = 0
    for byte in text.as_bytes():
        dst[i] = byte
        i += 1
    dst[i] = 0

fn dh_compare(a: InlineArray[UInt8, 31], b: InlineArray[UInt8, 31]) -> Int:
    for i in range(31):
        if a[i] < b[i]: return -1
        if a[i] > b[i]: return 1
        if a[i] == 0: return 0
    return 0

fn dh_func1(a: Int, b: Int, inout ch1: Int) -> Int:
    if a != b: return 0
    ch1 = a
    return 1

fn dh_func2(a: InlineArray[UInt8, 31], b: InlineArray[UInt8, 31],
             inout ch1: Int, inout glob: Int) -> Bool:
    var loc = 2
    var ch = 0
    while loc <= 2:
        if dh_func1(Int(a[loc]), Int(b[loc+1]), ch1) == 0:
            ch = 65
            loc += 1
    if ch >= 87 and ch < 90: loc = 7
    if ch == 82: return True
    if dh_compare(a, b) > 0:
        loc += 7
        glob = loc
        return True
    return False

fn dh_proc6(value: Int, glob: Int) -> Int:
    var result = value
    if value != 2: result = 3
    if value == 0: result = 0
    elif value == 1: result = 0 if glob > 100 else 3
    elif value == 2: result = 1
    elif value == 4: result = 2
    return result

@export("ansibench_dhrystone")
fn ansibench_dhrystone(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let passes = input[0]
    if passes < 1 or passes > 8: return -1
    var glob = 0; var boolean = 0; var ch1 = 0; var ch2 = 0
    var arr1 = InlineArray[Int, 50](fill=0)
    var arr2 = InlineArray[Int, 2500](fill=0)
    # Each record has pointer index, discriminator, enum, integer and text.
    var fields = InlineArray[Int, 8](fill=0)
    fields[0] = 1; fields[2] = 2; fields[3] = 40
    var record_text = InlineArray[UInt8, 31](fill=0)
    var next_text = InlineArray[UInt8, 31](fill=0)
    var str1 = InlineArray[UInt8, 31](fill=0)
    var str2 = InlineArray[UInt8, 31](fill=0)
    dh_copy(record_text, "DHRYSTONE PROGRAM, SOME STRING")
    dh_copy(str1, "DHRYSTONE PROGRAM, 1'ST STRING")
    arr2[8*50+7] = 10
    var a = 0; var b = 0; var c = 0; var en = 0; var false_flag = 0
    for run in range(1, Int(passes)+1):
        ch1 = 65; boolean = 0
        if ch1 == 65: boolean |= 1
        ch2 = 66
        a = 2; b = 3
        dh_copy(str2, "DHRYSTONE PROGRAM, 2'ND STRING")
        en = 1
        false_flag = 0 if dh_func2(str1, str2, ch1, glob) else 1
        while a < b:
            c = 5*a-b
            c = b+(a+2)
            a += 1
        let pos = a+5
        arr1[pos] = c; arr1[pos+1] = arr1[pos]; arr1[pos+30] = pos
        for i in range(pos,pos+2): arr2[pos*50+i] = pos
        arr2[pos*50+pos-1] += 1; arr2[(pos+20)*50+pos] = arr1[pos]
        glob = 5
        let next = fields[0]
        for i in range(4): fields[4*next+i] = fields[i]
        for i in range(31): next_text[i] = record_text[i]
        fields[3] = 5; fields[4*next+3] = fields[3]; fields[4*next] = fields[0]
        if fields[0] >= 0: fields[4*next] = fields[0]
        fields[3] = glob+12
        if fields[4*next+1] == 0:
            fields[4*next+3] = 6
            fields[4*next+2] = dh_proc6(fields[2], glob)
            fields[4*next] = fields[0]
            fields[4*next+3] = 10+(fields[4*next+3]+2)
        else:
            for i in range(4): fields[i] = fields[4*next+i]
            for i in range(31): record_text[i] = next_text[i]
        for ch in range(65,ch2+1):
            if en == dh_func1(ch, 67, ch1):
                en = dh_proc6(0, glob)
                dh_copy(str2, "DHRYSTONE PROGRAM, 3'RD STRING")
                b = run; glob = run
        b = b*a; a = b//c; b = 7*(b-c)-a
        var local = a+10
        while True:
            if ch1 == 65:
                local -= 1
                a = local-glob
                break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 19: return -2
    var result = InlineArray[Int, 19](fill=0)
    result[0]=glob; result[1]=boolean; result[2]=ch1; result[3]=ch2
    result[4]=arr1[8]; result[5]=arr2[8*50+7]
    result[6]=fields[1]; result[7]=fields[2]; result[8]=fields[3]; result[9]=fields[0]
    result[10]=fields[5]; result[11]=fields[6]; result[12]=fields[7]; result[13]=fields[4]
    result[14]=a; result[15]=b; result[16]=c; result[17]=en; result[18]=false_flag
    for i in range(19): output[i] = UInt8(result[i] & 255)
    return 19
