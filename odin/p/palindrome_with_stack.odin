package palindrome_with_stack
import "core:c"
@(export)
palindrome_with_stack :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != c.size_t(v[0]+1) do return -1
 length:=int(v[0]); stack:[128]u8
 for i:=0;i<length;i+=1 { x:=v[i+1]; if x<0||x>127 do return -1; c0:=u8(x); if c0>='A'&&c0<='Z' do c0+=32; stack[i]=c0 }
 for i:=0;i<length;i+=1 { if stack[i]!=stack[length-1-i] do return 0 }; return 1
}

