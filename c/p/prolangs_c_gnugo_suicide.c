/* GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
   Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
   Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1. */
#include <stddef.h>
#include <stdint.h>

static int group_liberties(const uint8_t board[361], int start, uint8_t color) {
    uint8_t seen[361] = {0}, lib_seen[361] = {0};
    int stack[361], top = 0, count = 0;
    stack[top++] = start; seen[start] = 1;
    while (top) {
        int at = stack[--top], r = at / 19, c = at % 19;
        int nb[4], n = 0;
        if (r > 0) nb[n++] = at - 19;
        if (r < 18) nb[n++] = at + 19;
        if (c > 0) nb[n++] = at - 1;
        if (c < 18) nb[n++] = at + 1;
        for (int j = 0; j < n; ++j) {
            int next = nb[j];
            if (board[next] == 0) { if (!lib_seen[next]) { lib_seen[next] = 1; ++count; } }
            else if (board[next] == color && !seen[next]) { seen[next] = 1; stack[top++] = next; }
        }
    }
    return count;
}

int64_t prolangs_c_gnugo_suicide(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > 246) return -1;
    int64_t row=input[0], col=input[1], own=input[2], opponent=input[3], ko=input[4], count=input[5];
    if (row<0 || row>=19 || col<0 || col>=19 || (own!=1 && own!=2) || (opponent!=1 && opponent!=2) || own==opponent ||
        ko < -1 || ko >= 361 || count < 0 || count > 120 || length != 6 + 2*(size_t)count) return -1;
    uint8_t board[361] = {0};
    for (int64_t k=0; k<count; ++k) {
        int64_t at=input[6+2*(size_t)k], stone=input[7+2*(size_t)k];
        if (at<0 || at>=361 || (stone!=1 && stone!=2) || board[at]) return -1;
        board[at]=(uint8_t)stone;
    }
    int target=(int)(row*19+col);
    if (board[target]) return -1;
    board[target]=(uint8_t)opponent;
    if (group_liberties(board,target,(uint8_t)opponent)>0) return 0;
    int dead=0;
    for (int i=0;i<361;++i) if (board[i]==own && group_liberties(board,i,(uint8_t)own)==0) ++dead;
    return (dead==0 || (dead==1 && ko==target)) ? 1 : 0;
}
