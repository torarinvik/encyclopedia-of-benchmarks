#include <stddef.h>
#include <stdint.h>
int64_t paranthesis_matching(const int64_t *v,size_t n){if(!v||n<2||n>100)return -1;int64_t count=v[0];if(count<1||count>99||n!=(size_t)count+1)return -1;int stack[99],sp=0;for(size_t i=1;i<n;i++){int64_t x=v[i];if(x<33||x>126)return -1;if(x=='('||x=='{'||x=='['||x=='<')stack[sp++]=(int)x;else if(x==')'||x=='}'||x==']'||x=='>'){int want=x==')'?'(':x=='}'?'{':x==']'?'[':'<';if(!sp||stack[--sp]!=want)return 0;}else return 0;}return sp==0;}
