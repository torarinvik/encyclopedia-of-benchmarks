package kth_element_in_a_list
import "core:c"
@(export) kth_element_in_a_list :: proc "c"(v:[^]i64,n:c.size_t)->i64{if n<3||n>34{return -1};k,pos:=v[0],v[1];if k<1||k>16||n!=k+2||pos<1||pos>k{return -1};for i:i64=0;i<k;i+=1{if v[i+2]<-10000||v[i+2]>10000{return -1}};return v[pos+1]}
