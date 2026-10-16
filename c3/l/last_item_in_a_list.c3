module last_item_in_a_list;
fn long last_item_in_a_list(long*v,usz n) @export("last_item_in_a_list"){if(n>64)return -1;for(usz i=0;i<n;i++)if(v[i]<0||v[i]>100000)return -1;if(n==0)return -1;return v[n-1];}
