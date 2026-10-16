@[export: 'permutation_cipher']
pub fn permutation_cipher(v &i64, n usize) i64 {
 unsafe {
  if v==nil || n<2 || n>74 || v[0]<0 || v[0]>64 { return -1 }
  length:=int(v[0]); if int(n)<length+2 { return -1 }; kp:=length+1
  if v[kp]<1 || v[kp]>8 { return -1 }; k:=int(v[kp]); if int(n)!=kp+k+1 { return -1 }
  mut seen:=[8]bool{}; for i in 0..k { x:=v[kp+1+i]; if x<1 || x>i64(k) || seen[int(x-1)] { return -1 }; seen[int(x-1)]=true }
  mut text:=[128]u8{}; mut m:=0
  for i in 0..length { x:=v[i+1]; if x<0||x>127 { return -1 }; mut c:=int(x); if c==32||c==9||c==10||c==11||c==12||c==13 { continue }; if c>=97&&c<=122 { c-=32 }; text[m]=u8(c); m++ }
  for m%k!=0 { text[m]=u8(88); m++ }; mut h:=u64(0)
  for b:=0;b<m;b+=k { for j:=0;j<k;j++ { h=(h*257+u64(text[b+int(v[kp+1+j]-1)]))%1000000007 } }; return i64(h)
 }
}

