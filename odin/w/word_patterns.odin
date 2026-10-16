package word_patterns
import "core:c"

@(export) word_patterns :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 1 || input[0] < 0 || input[0] > 256 || length != uint(input[0])+1 do return -1
    n := uint(input[0])
    first: [128]int; for i := 0; i < 128; i += 1 { first[i] = -1 }; next:=0; pos:=uint(0)
    for i:=uint(0); i<n; i+=1 { ch:=input[i+1]; if ch<0 || ch>127 do return -1; if ch>=97 && ch<=122 do ch-=32; cidx:=int(ch); if first[cidx]<0 {first[cidx]=next;next+=1}; }
    if output == nil || capacity < 4*n+1 do return -2
    for i:=uint(0); i<n; i+=1 { ch:=input[i+1]; if ch>=97 && ch<=122 do ch-=32; cidx:=int(ch); if i>0 {output[pos]='.';pos+=1}; value:=first[cidx]; divisor:=100; started:=false; for divisor>0 {digit:=value/divisor; if digit>0 || started || divisor==1 {output[pos]=u8('0'+digit);pos+=1;started=true}; value%=divisor;divisor/=10;} }
    output[pos]=0; return i64(pos)
}
