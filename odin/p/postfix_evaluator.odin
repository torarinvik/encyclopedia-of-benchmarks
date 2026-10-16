package postfix_evaluator
import "core:c"
@(export)
postfix_evaluator :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 if v == nil || n < 2 || n > 129 || v[0] < 1 || v[0] > 128 || n != c.size_t(v[0]+1) do return -1
 st: [128]i32; sp:=0
 for i:=1;i<int(n);i+=1 { t:=v[i]
  if t == -9000000000000000001 || t == -9000000000000000002 || t == -9000000000000000003 || t == -9000000000000000004 {
   if sp<2 do return -1
   b,a:=st[sp-1],st[sp-2];sp-=2; z:i32
   if t == -9000000000000000001 {z=i32(u32(a)+u32(b))} else if t == -9000000000000000002 {z=i32(u32(a)-u32(b))} else if t == -9000000000000000003 {z=i32(u32(a)*u32(b))} else {if b==0 do return -1;z=if a==i32(-2147483648)&&b == -1 {i32(-2147483648)} else {a/b}}
   st[sp]=z;sp+=1
  } else {if t < -2147483648 || t > 2147483647 || sp>=128 do return -1;st[sp]=i32(t);sp+=1}
 }
 if sp==1 do return i64(st[0]);return -1
}
