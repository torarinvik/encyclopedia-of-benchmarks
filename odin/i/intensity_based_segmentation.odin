package intensity_based_segmentation
import "core:c"
@(export)
intensity_based_segmentation :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n<2||n>12{return -1};k:=v[0];if k<0||k>4||n<=c.size_t(k)+1||n>c.size_t(k)+8{return -1}
 for j:=c.size_t(1);j<n;j+=1{if v[j]<0||v[j]>255{return -1}}
 out:=i64(0);place:=i64(1);for p:=c.size_t(k)+1;p<n;p+=1{label:=i64(0);for i:=i64(0);i<k;i+=1{if v[p]>v[c.size_t(i)+1]{label=i+1}};out+=label*place;place*=5};return out
}
