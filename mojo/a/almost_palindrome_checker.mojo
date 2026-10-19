from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("almost_palindrome_checker")
fn almost_palindrome_checker(text: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 100000 or (length > 0 and text == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(length):
        if text[i] < 97 or text[i] > 122:
            return -1
    var left = 0
    var right = Int(length)
    while left < right:
        if text[left] != text[right - 1]:
            var ok_left = True
            var a = left + 1
            var b = right
            while a < b:
                if text[a] != text[b - 1]:
                    ok_left = False
                    break
                a += 1
                b -= 1
            if ok_left:
                return 1
            var ok_right = True
            a = left
            b = right - 1
            while a < b:
                if text[a] != text[b - 1]:
                    ok_right = False
                    break
                a += 1
                b -= 1
            if ok_right:
                return 1
            return 0
        left += 1
        right -= 1
    return 1
