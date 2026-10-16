package gcounter
import "core:c"
hash_value :: proc "contextless" (h0:u64,value:i64)->u64 { h:=h0; bits:=transmute(u64)value; for i:=u32(0);i<8;i+=1 { h=(h ~ ((bits>>(8*i))&255))*0x100000001b3 }; return h }
@(export)
gcounter :: proc "c" (a:[^]i64,n:c.size_t)->i64 {
 if a==nil||n<2||n>386||a[0]<1||a[0]>8||a[1]<0||a[1]>128||n!=c.size_t(2+3*a[1]) do return -1
 nodes:=int(a[0]); s:[8][8]i64; h:=u64(0xcbf29ce484222325)
 for i:=0;i<int(a[1]);i+=1 { op:=a[2+3*i];aa:=a[3+3*i];bb:=a[4+3*i];if aa<0||aa>=i64(nodes) do return -1;ai:=int(aa)
  if op==0 { if bb!=0||s[ai][ai]>=1000000 do return -1;s[ai][ai]+=1 }
  else if op==1 { if bb!=0 do return -1;total:=i64(0);for j:=0;j<nodes;j+=1{total+=s[ai][j]};h=hash_value(h,total) }
  else if op==2 { if bb<0||bb>=i64(nodes) do return -1;yes:=true;bi:=int(bb);for j:=0;j<nodes;j+=1{if s[ai][j]>s[bi][j] do yes=false};if yes{h=hash_value(h,1)}else{h=hash_value(h,0)} }
  else if op==3 { if bb<0||bb>=i64(nodes) do return -1;bi:=int(bb);for j:=0;j<nodes;j+=1{if s[bi][j]>s[ai][j]{s[ai][j]=s[bi][j]}} }
  else { return -1 }
 }
 for i:=0;i<nodes;i+=1{for j:=0;j<nodes;j+=1{h=hash_value(h,s[i][j])}}
 return transmute(i64)h
}
