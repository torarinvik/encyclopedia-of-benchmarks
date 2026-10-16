module uint53_is;
fn long uint53_is(long*v,usz n) @export("uint53_is"){if(v==null||n!=1)return -1;return v[0]>=0&&v[0]<9007199254740992?1:0;}
