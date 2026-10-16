package number_to_words

import "core:c"

SMALL :: [20]string{"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"}
TENS :: [10]string{"","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"}
SCALES :: [5]string{"","Thousand","Million","Billion","Trillion"}
add :: proc(s: ^string, word: string) { if len(s^) > 0 do s^ += " "; s^ += word }
chunk :: proc(s: ^string, value: int) {
	x := value
	if x >= 100 { add(s, SMALL[x/100]); add(s,"Hundred"); x %= 100 }
	if x >= 20 { add(s,TENS[x/10]); x %= 10 }
	if x > 0 && x < 20 { add(s,SMALL[x]) }
}
@(export)
number_to_words :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 9 || values[0] < -1 || values[0] > 1 || values[1] < 0 || values[1] > 999999999999999 || values[2] < 0 || values[2] > 6 || length != c.size_t(values[2]+3) do return -1
	nonzero := values[1] != 0
	for i := 3; i < int(length); i += 1 { if values[i] < 0 || values[i] > 9 do return -1; if values[i] != 0 do nonzero = true }
	if (nonzero && values[0] == 0) || (!nonzero && values[0] != 0) do return -1
	result := ""
	if values[0] < 0 do add(&result,"Negative")
	whole := u64(values[1]); groups: [5]int
	for i := 0; i < 5; i += 1 { groups[i] = int(whole % 1000); whole /= 1000 }
	any := false
	for i := 4; i >= 0; i -= 1 { if groups[i] != 0 { chunk(&result,groups[i]); if i > 0 do add(&result,SCALES[i]); any = true } }
	if !any do add(&result,"Zero")
	frac_nonzero := false
	for i := 3; i < int(length); i += 1 { if values[i] != 0 do frac_nonzero = true }
	if frac_nonzero { add(&result,"Point"); for i := 3; i < int(length); i += 1 { add(&result,SMALL[values[i]]) } }
	if c.size_t(len(result)) > capacity || (len(result) > 0 && output == nil) do return -2
	for i := 0; i < len(result); i += 1 { output[i] = result[i] }
	return i64(len(result))
}
