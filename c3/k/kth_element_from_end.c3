module kth_element_from_end;
fn long kth_element_from_end(long*v,usz n) @export("kth_element_from_end"){if(v==null||n<1||n>65)return -1;long k=v[0];if(k<=0||k>=n)return -1;for(usz i=1;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return v[n-usz(k)];}
