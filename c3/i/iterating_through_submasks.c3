module iterating_through_submasks;
fn long iterating_through_submasks(long*v,usz n) @export("iterating_through_submasks"){if(v==null||n!=1||v[0]<1||v[0]>4095)return -1;long mask=v[0];long count=0;long submask=mask;while(submask!=0){count++;submask=(submask-1)&mask;}return count;}
