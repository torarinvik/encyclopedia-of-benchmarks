@[export: 'word_ladder']
pub fn word_ladder(input &i64, length usize, mut output &u8, capacity usize) i64 {
 if unsafe { input == nil } || length < 4 { return -1 }
 width_value := unsafe { input[0] }; begin := unsafe { input[1] }; ending := unsafe { input[2] }; count_value := unsafe { input[3] }
 if width_value < 1 || width_value > 5 || count_value < 0 || count_value > 32 { return -1 }
 width := int(width_value); count := int(count_value)
 if length != usize(4 + count) { return -1 }
 mut limit := i64(1); for _ in 0 .. width { limit *= 26 }
 if begin < 0 || begin >= limit || ending < 0 || ending >= limit { return -1 }
 mut dict := [32]i64{}; mut has_end := false
 for i in 0 .. count { code := unsafe { input[4+i] }; if code < 0 || code >= limit { return -1 }; dict[i]=code; if code==ending { has_end=true } }
 if unsafe { output == nil } || capacity < 8 { return -2 }
 mut answer := i64(0)
 if has_end {
  mut queue := [33]i64{}; mut dist := [33]i64{}; mut head:=0; mut tail:=1; queue[0]=begin; dist[0]=1
  for head < tail && answer == 0 {
   word:=queue[head]; depth:=dist[head]; head++
   mut place:=i64(1)
   for _ in 0 .. width {
    if answer != 0 { break }; digit:=(word/place)%26
    for letter in 0 .. 26 { l:=i64(letter); if l==digit { continue }; next:=word+(l-digit)*place
     if next==ending { answer=depth+1; break }
     mut in_dict:=false; for j in 0 .. count { if dict[j]==next { in_dict=true; break } }
     mut seen:=false; for j in 1 .. tail { if queue[j]==next { seen=true; break } }
     if in_dict && !seen && tail<33 { queue[tail]=next; dist[tail]=depth+1; tail++ }
    }; place*=26
   }
  }
 }
 mut bits:=u64(answer); unsafe { for b in 0 .. 8 { output[b]=u8(bits & 255); bits >>= 8 } }
 return 8
}
