module length_of_list;
fn long length_of_list(long*v,usz n) @export("length_of_list"){if(n>64)return -1;for(usz i=0;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return n;}
