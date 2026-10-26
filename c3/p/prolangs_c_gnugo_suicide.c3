module prolangs_c_gnugo_suicide;

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
fn int group_liberties(u8* board, int start, u8 color) {
	bool[361] seen = zeroed; bool[361] lib_seen = zeroed; int[361] stack = zeroed;
	usz top=1; int total=0; stack[0]=start; seen[start.usz()]=true;
	while(top>0){top--;int at=stack[top],r=at/19,c=at%19;int[4] nb=zeroed;usz n=0;
		if(r>0){nb[n]=at-19;n++;}if(r<18){nb[n]=at+19;n++;}if(c>0){nb[n]=at-1;n++;}if(c<18){nb[n]=at+1;n++;}
		for(usz j=0;j<n;j++){usz next=nb[j].usz();if(board[next]==0){if(!lib_seen[next]){lib_seen[next]=true;total++;}}
			else if(board[next]==color&&!seen[next]){seen[next]=true;stack[top]=nb[j];top++;}}
	}
	return total;
}

fn long prolangs_c_gnugo_suicide(long* input, usz length) @export("prolangs_c_gnugo_suicide") {
	if(input==null||length<6||length>246)return -1;
	long row=input[0],col=input[1],own=input[2],opponent=input[3],ko=input[4],count=input[5];
	if(row<0||row>=19||col<0||col>=19||(own!=1&&own!=2)||(opponent!=1&&opponent!=2)||own==opponent||ko < -1||ko>=361||count<0||count>120)return -1;
	if(length!=6+2*count.usz())return -1;
	u8[361] board=zeroed;
	for(usz k=0;k<count.usz();k++){long at=input[6+2*k],stone=input[7+2*k];if(at<0||at>=361||(stone!=1&&stone!=2)||board[at.usz()]!=0)return -1;board[at.usz()]=stone.u8();}
	int target=(row*19+col).int();if(board[target.usz()]!=0)return -1;board[target.usz()]=opponent.u8();
	if(group_liberties(&board[0],target,opponent.u8())>0)return 0;
	long dead=0;for(int i=0;i<361;i++){if(board[i.usz()]==own.u8()&&group_liberties(&board[0],i,own.u8())==0)dead++;}
	if(dead==0||(dead==1&&ko==target.long()))return 1;return 0;
}
