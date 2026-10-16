module number_to_words

const small_words = ['Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen']
const tens_words = ['','','Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety']
const scales = ['','Thousand','Million','Billion','Trillion']
fn add(mut s string, word string) { if s.len > 0 { s += ' ' }; s += word }
fn chunk(mut s string, value int) {
	mut x := value
	if x >= 100 { add(mut s, small_words[x / 100]); add(mut s, 'Hundred'); x %= 100 }
	if x >= 20 { add(mut s, tens_words[x / 10]); x %= 10 }
	if x > 0 && x < 20 { add(mut s, small_words[x]) }
}
@[export: 'number_to_words']
pub fn number_to_words(values &i64, length usize, output &u8, capacity usize) i64 {
	if length < 3 || length > 9 { return -1 }
	if unsafe { values[0] < -1 || values[0] > 1 || values[1] < 0 || values[1] > 999999999999999 || values[2] < 0 || values[2] > 6 || length != usize(values[2] + 3) } { return -1 }
	mut nonzero := unsafe { values[1] != 0 }
	for i in 3 .. int(length) { x := unsafe { values[i] }; if x < 0 || x > 9 { return -1 }; if x != 0 { nonzero = true } }
	if unsafe { (nonzero && values[0] == 0) || (!nonzero && values[0] != 0) } { return -1 }
	mut result := ''
	if unsafe { values[0] < 0 } { add(mut result, 'Negative') }
	mut whole := u64(unsafe { values[1] }); mut groups := [5]int{}
	for i in 0 .. 5 { groups[i] = int(whole % 1000); whole /= 1000 }
	mut any := false
	for i := 4; i >= 0; i-- { if groups[i] != 0 { chunk(mut result, groups[i]); if i > 0 { add(mut result, scales[i]) }; any = true } }
	if !any { add(mut result, 'Zero') }
	mut fraction_nonzero := false
	for i in 3 .. int(length) { if unsafe { values[i] != 0 } { fraction_nonzero = true } }
	if fraction_nonzero { add(mut result, 'Point'); for i in 3 .. int(length) { add(mut result, small_words[int(unsafe { values[i] })]) } }
	if usize(result.len) > capacity || (result.len > 0 && isnil(output)) { return -2 }
	for i in 0 .. result.len { unsafe { output[i] = result[i] } }
	return i64(result.len)
}
