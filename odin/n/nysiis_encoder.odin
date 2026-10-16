package nysiis_encoder

import "core:c"

vowel :: proc(c: u8) -> bool { return c == 'A' || c == 'E' || c == 'I' || c == 'O' || c == 'U' }
matches :: proc(s: [^]u8, n, at: int, p: string) -> bool {
	if at + len(p) > n do return false
	for i := 0; i < len(p); i += 1 { if s[at+i] != p[i] do return false }
	return true
}
replace_at :: proc(s: [^]u8, n: ^int, at, old: int, to: string) {
	if len(to) > old { for i := n^; i > at+old; i -= 1 { s[i-old+len(to)-1] = s[i-1] } }
	else { for i := at+old; i < n^; i += 1 { s[i-old+len(to)] = s[i] } }
	for i := 0; i < len(to); i += 1 { s[at+i] = to[i] }
	n^ = n^ - old + len(to)
}
@(export)
nysiis_encoder :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length < 2 || length > 65 || values == nil do return -1
	count := values[0]; if count < 1 || count > 64 || length != c.size_t(count+1) do return -1
	buf: [256]u8; n := 0
	for i := 0; i < int(count); i += 1 { x := values[i+1]; if x >= 97 && x <= 122 do x -= 32; if x < 65 || x > 90 do return -1; buf[n] = u8(x); n += 1 }
	starts := [6][2]string{{"MAC","MCC"},{"KN","NN"},{"K","C"},{"PH","FF"},{"PF","FF"},{"SCH","SSS"}}
	for pair in starts { if matches(&buf[0],n,0,pair[0]) { replace_at(&buf[0],&n,0,len(pair[0]),pair[1]); break } }
	ends := [6][2]string{{"EE","Y"},{"IE","Y"},{"DT","D"},{"RT","D"},{"NT","D"},{"ND","D"}}
	for pair in ends { if n >= len(pair[0]) && matches(&buf[0],n,n-len(pair[0]),pair[0]) { replace_at(&buf[0],&n,n-len(pair[0]),len(pair[0]),pair[1]); break } }
	rules := [12][2]string{{"EV","AF"},{"E","A"},{"I","A"},{"O","A"},{"U","A"},{"Q","G"},{"Z","S"},{"M","N"},{"KN","NN"},{"K","C"},{"SCH","SSS"},{"PH","FF"}}
	for i := 1; i < n; i += 1 { changed := false; for pair in rules { if matches(&buf[0],n,i,pair[0]) { replace_at(&buf[0],&n,i,len(pair[0]),pair[1]); changed = true; break } }; if !changed { if buf[i]=='H' && (!vowel(buf[i-1]) || (i+1<n && !vowel(buf[i+1]))) { buf[i]=buf[i-1] } else if buf[i]=='W' && vowel(buf[i-1]) { buf[i]=buf[i-1] } } }
	w := 0; for i := 0; i < n; i += 1 { if i == 0 || buf[i] != buf[i-1] { buf[w]=buf[i]; w+=1 } }; n=w
	if n>0 && buf[n-1]=='S' { n-=1 } else if n>=2 && buf[n-2]=='A' && buf[n-1]=='Y' { buf[n-2]='Y'; n-=1 } else if n>0 && buf[n-1]=='A' { n-=1 }
	if c.size_t(n)>capacity || (n>0 && output==nil) do return -2
	for i := 0; i < n; i += 1 { output[i]=buf[i] }; return i64(n)
}
