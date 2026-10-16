package phonetic_alphabet_converter

import "core:c"

words: [36]string = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu", "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"}

@(export)
phonetic_alphabet_converter :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
    if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != c.size_t(v[0] + 1) do return -1
    if out == nil || cap < 576 do return -2
    at := 0
    emitted := false
    for i := 0; i < int(v[0]); i += 1 {
        raw := v[i + 1]
        if !((raw == 9 || raw == 10 || raw == 11 || raw == 12 || raw == 13 || raw == 32) || (raw >= 33 && raw <= 126)) do return -1
        if raw == 9 || raw == 10 || raw == 11 || raw == 12 || raw == 13 || raw == 32 do continue
        c := int(raw)
        if c >= int('a') && c <= int('z') do c -= 32
        if emitted { out[at] = 32; at += 1 }
        emitted = true
        if c >= int('A') && c <= int('Z') { word := words[c - int('A')]; for j := 0; j < len(word); j += 1 { out[at] = word[j]; at += 1 } }
        else if c >= int('0') && c <= int('9') { word := words[26 + c - int('0')]; for j := 0; j < len(word); j += 1 { out[at] = word[j]; at += 1 } }
        else { out[at] = u8(c); at += 1 }
    }
    return i64(at)
}
