@[export: 'palindrome_singly_linked_list']
pub fn palindrome_singly_linked_list(v &i64,n usize)i64{unsafe{if v==nil||n<1||n>65||v[0]<0||v[0]>64||n!=usize(v[0]+1){return -1};len:=int(v[0]);for i in 1..int(n){if v[i]<-2147483648||v[i]>2147483647{return -1}};mut slow:=0;mut fast:=0;for fast+1<len{slow++;fast+=2};suffix:=len-slow;for i in 0..suffix{if v[i+1]!=v[len-i]{return 0}};return 1}}

