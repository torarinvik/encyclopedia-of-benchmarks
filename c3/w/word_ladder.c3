module word_ladder;
fn long word_ladder(long* input, usz length, char* output, usz capacity) @export("word_ladder") {
 if (input == null || length < 4) return -1;
 long width_v=input[0]; long begin=input[1]; long end=input[2]; long count_v=input[3];
 if(width_v<1||width_v>5||count_v<0||count_v>32) return -1;
 usz width=(usz)width_v; usz count=(usz)count_v;
 if(length!=4+count) return -1;
 long limit=1; for(usz i=0;i<width;i++) limit*=26;
 if(begin<0||begin>=limit||end<0||end>=limit) return -1;
 long[32] dict; bool has_end=false;
 for(usz i=0;i<count;i++){long code=input[4+i];if(code<0||code>=limit)return -1;dict[i]=code;if(code==end)has_end=true;}
 if(output==null||capacity<8)return -2;
 long answer=0;
 if(has_end){long[33] queue;long[33] dist;usz head=0; usz tail=1;queue[0]=begin;dist[0]=1;
 while(head<tail&&answer==0){long word=queue[head];long depth=dist[head];head++;
  long place=1;
  for(usz pos=0;pos<width&&answer==0;pos++){long digit=(word/place)%26;
   for(long letter=0;letter<26;letter++){if(letter==digit)continue;long next=word+(letter-digit)*place;
    if(next==end){answer=depth+1;break;}
    bool in_dict=false;for(usz j=0;j<count;j++)if(dict[j]==next){in_dict=true;break;}
    bool seen=false;for(usz j=1;j<tail;j++)if(queue[j]==next){seen=true;break;}
    if(in_dict&&!seen&&tail<33){queue[tail]=next;dist[tail]=depth+1;tail++;}
   } place*=26;
  }
 }
 }
 ulong bits=(ulong)answer;for(usz b=0;b<8;b++){output[b]=(char)(bits&255);bits>>=8;}return 8;
}
