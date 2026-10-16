export fn word_ladder(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const wv=input[0]; const begin=input[1]; const end=input[2]; const cv=input[3];
    if (wv<1 or wv>5 or cv<0 or cv>32) return -1;
    const width:usize=@intCast(wv); const count:usize=@intCast(cv);
    if(length!=4+count)return -1;
    var limit:i64=1;for(0..width)|_|{limit*=26;}
    if(begin<0 or begin>=limit or end<0 or end>=limit)return -1;
    var dict:[32]i64=@splat(0);var has_end=false;
    for(0..count)|i|{const code=input[4+i];if(code<0 or code>=limit)return -1;dict[i]=code;if(code==end)has_end=true;}
    if(output==null or capacity<8)return -2;
    var answer:i64=0;
    if(has_end){var queue:[33]i64=@splat(0);var dist:[33]i64=@splat(0);var head:usize=0;var tail:usize=1;queue[0]=begin;dist[0]=1;
      while(head<tail and answer==0){const word=queue[head];const depth=dist[head];head+=1;var place:i64=1;
       for(0..width)|_|{if(answer!=0)break;const digit=@rem(@divTrunc(word, place), 26);
        for(0..26)|letter_u|{const letter:i64=@intCast(letter_u);if(letter==digit)continue;const next=word+(letter-digit)*place;
         if(next==end){answer=depth+1;break;}
         var in_dict=false;for(0..count)|j|{if(dict[j]==next){in_dict=true;break;}}
         var seen=false;for(1..tail)|j|{if(queue[j]==next){seen=true;break;}}
         if(in_dict and !seen and tail<33){queue[tail]=next;dist[tail]=depth+1;tail+=1;}
        }place*=26;
       }
      }
    }
    const bits:u64=@bitCast(answer);for(0..8)|b|output[b]=@truncate(bits>>@intCast(8*b));return 8;
}
