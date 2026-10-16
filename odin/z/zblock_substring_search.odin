package zblock_substring_search
import "core:c"
@(export)
zblock_substring_search :: proc "c" (a:[^]i64,length:c.size_t)->i64{
 if a==nil||length<3 do return -1;tn:=a[0];pn:=a[1];if tn<0||tn>256||pn<1||pn>64||length!=c.size_t(tn+pn+2)do return -1;for i:=c.size_t(2);i<length;i+=1{if a[i]<0||a[i]>127||a[i]==36 do return -1}
 text_len:=int(tn);pat_len:=int(pn);n:=text_len+pat_len+1;s:[321]i64;z:[321]int;for i:=0;i<pat_len;i+=1{s[i]=a[2+tn+i]};s[pat_len]=-1;for i:=0;i<text_len;i+=1{s[pat_len+1+i]=a[2+i]};left:=0;right:=0
 for i:=1;i<n;i+=1{z[i]=0;if i<=right{z[i]=min(right-i+1,z[i-left])};for i+z[i]<n&&s[z[i]]==s[i+z[i]]{z[i]+=1};if i+z[i]>0&&i+z[i]-1>right{left=i;right=i+z[i]-1}}
 found:=i64(0);for i:=pat_len+1;i<n;i+=1{if z[i]>=pat_len{found+=1}};return found
}
