module kth_element_in_a_list;
fn long kth_element_in_a_list(long*v,usz n) @export("kth_element_in_a_list"){if(n<3||n>34)return -1;long k=v[0],pos=v[1];if(k<1||k>16||n!=k+2||pos<1||pos>k)return -1;for(long i=0;i<k;i++)if(v[i+2]<-10000||v[i+2]>10000)return -1;return v[pos+1];}
