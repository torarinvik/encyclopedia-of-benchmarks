module phonetic_alphabet_converter

const words = ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliett', 'Kilo', 'Lima', 'Mike', 'November', 'Oscar', 'Papa', 'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X-ray', 'Yankee', 'Zulu', 'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine']!

@[export: 'phonetic_alphabet_converter']
pub fn phonetic_alphabet_converter(v &i64, n usize, out &u8, cap usize) i64 {
    unsafe {
        if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != usize(v[0]) + 1 { return -1 }
        if out == nil || cap < 576 { return -2 }
        mut at := 0
        mut emitted := false
        for i in 0 .. int(v[0]) {
            raw := v[i + 1]
            if !((raw == 9 || raw == 10 || raw == 11 || raw == 12 || raw == 13 || raw == 32) || (raw >= 33 && raw <= 126)) { return -1 }
            if raw == 9 || raw == 10 || raw == 11 || raw == 12 || raw == 13 || raw == 32 { continue }
            mut c := int(raw)
            if c >= int(`a`) && c <= int(`z`) { c -= 32 }
            if emitted { out[at] = ` `; at++ }
            emitted = true
            if c >= int(`A`) && c <= int(`Z`) {
                word := words[c - int(`A`)]
                for j in 0 .. word.len { out[at] = word[j]; at++ }
            } else if c >= int(`0`) && c <= int(`9`) {
                word := words[26 + c - int(`0`)]
                for j in 0 .. word.len { out[at] = word[j]; at++ }
            } else { out[at] = u8(c); at++ }
        }
        return i64(at)
    }
}
