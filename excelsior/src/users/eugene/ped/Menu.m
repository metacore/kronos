IMPLEMENTATION MODULE Menu; (*$N+ 13-Oct-88. (c) KRONOS *)

FROM SYSTEM     IMPORT  ADDRESS, WORD;
FROM ASCII      IMPORT  NL;
FROM pedMouse   IMPORT  wait, first, drop, Read;
FROM cdsHeap    IMPORT  Allocate, Deallocate;
FROM Windows    IMPORT  window, create, open, close, read_point, remove,
                        ontop, refresh, ref_box, lsno, lock_window,
                        release_window;
FROM pedVG      IMPORT  rep, or, xor, bic, frame, mode, color, write_str,
                        sign_w, sign_h, char_w, char_h, inverse, off;
IMPORT  dkb: defKeyboard;
IMPORT  str: Strings;
IMPORT  mcd: defCodes;
IMPORT  vg : pedVG;
IMPORT  ex : ModelPbl;
IMPORT  sch: osKernel;
IMPORT  scr: SCRtty;

PROCEDURE ALLOC(n: INTEGER): ADDRESS; CODE mcd.alloc END ALLOC;
PROCEDURE MOVE(from,to: ADDRESS; n: INTEGER); CODE mcd.move END MOVE;
PROCEDURE BBP(a: ADDRESS; x,s: INTEGER; v: BITSET); CODE 0EDh END BBP;

TYPE menu_info=POINTER TO RECORD
       sel : BITSET;
       job : menu_proc;
     END;

CONST del = 0c;
      move= 1c;

PROCEDURE menu_job(w: window; x,y: INTEGER; ch: CHAR);
  VAR n: BITSET; inf: menu_info; i,j,nx,ny,sl: INTEGER;
BEGIN
  IF (x<w^.x*32+1) OR (x>=(w^.x+w^.sx)*32-1) OR
     (y<w^.y+1) OR (y>=w^.y+w^.sy-1-(2+vg.sign_h)) THEN n:={}
  ELSE
    sl:=(y-w^.y-1) DIV vg.char_h;
    n:={sl};
  END;
  inf:=w^.info;
  IF n#inf^.sel THEN
    vg.color(w,1); vg.mode(w,vg.rep);
    FOR i:=1 TO 31 DO
      IF i IN (n/inf^.sel) THEN
        IF i IN n THEN
          vg.patt_box(w,1,w^.sy-2-i*vg.char_h,w^.sx*32-2,
                          w^.sy-1-(i+1)*vg.char_h,4);
        ELSE
          vg.patt_box(w,1,w^.sy-2-i*vg.char_h,w^.sx*32-2,
                          w^.sy-1-(i+1)*vg.char_h,0);
        END;
      END;
    END;
    inf^.sel:=n;
    refresh(w);
  END;
  IF (ch=15c) OR (ch=226c) OR (ch=227c) OR (ch=215c) OR (ch=266c) THEN
    IF n#{} THEN
      inf^.job(w,sl,0);
    ELSIF (y>=w^.y+w^.sy-2-(vg.sign_h)) & (y<w^.y+w^.sy-2) THEN
      IF (x>=w^.x*32+4) & (x<w^.x*32+(4+vg.sign_w)) THEN
        read_point(1,w,nx,ny,ch);
        close(w); w^.x:=(nx+2) DIV 32; w^.y:=ny-w^.sy+7; open(w);
      ELSE
        ontop(w);
      END;
    END;
  END;
END menu_job;

PROCEDURE menu(x,y: INTEGER; s: ARRAY OF CHAR; sel: menu_proc);
  TYPE str=ARRAY [0..79] OF CHAR;
  VAR lns  : ARRAY [0..19] OF str;
      cnt  : INTEGER;
      i,j  : INTEGER;
      sx,sy: INTEGER;
      w    : window;
      inf  : menu_info;
BEGIN
  cnt:=0; i:=0; j:=0; sx:=0;
  LOOP
    IF s[i]='|' THEN
      lns[cnt][j]:=0c; INC(cnt); j:=0;
    ELSIF s[i]=0c THEN
      IF j#0 THEN lns[cnt][j]:=0c; INC(cnt); j:=0 END;
      EXIT;
    ELSE
      lns[cnt][j]:=s[i]; INC(j);
    END;
    IF j>sx THEN sx:=j END;
    INC(i);
  END;
  sx:=((sx+2)*vg.char_w+31) DIV 32;
  sy:=cnt*vg.char_h+2+vg.sign_h;
  Allocate(inf,SIZE(inf^));
  w:=create(sx,sy);
  w^.info:=inf; inf^.sel:={}; inf^.job:=sel;
  vg.mode(w,vg.rep); vg.inverse(w,vg.off);
  vg.color(w,8);
  vg.frame(w,0,0,sx*32-1,sy-1);
  vg.color(w,4);
  vg.box(w,1,w^.sy-2,w^.dsx-2,w^.sy-1-vg.char_h);
  vg.box(w,1,1,w^.dsx-2,2+vg.sign_h);
  vg.color(w,2);
  FOR i:=0 TO cnt-1 DO
    vg.write_str(w,10,w^.sy-(i+1)*vg.char_h,lns[i]);
  END;
  vg.color(w,4);
  vg.sign(w,4,2,move);
  w^.job:=menu_job; w^.x:=x; w^.y:=y;
  open(w);
END menu;

PROCEDURE panel(x,y: INTEGER; s: ARRAY OF CHAR; sel: menu_proc);
END panel;

PROCEDURE cre_tmp_menu(s: ARRAY OF CHAR): window;
  TYPE str=ARRAY [0..79] OF CHAR;
  VAR lns  : ARRAY [0..31] OF str;
      cnt  : INTEGER;
      i,j  : INTEGER;
      sx,sy: INTEGER;
      w    : window;
      inf  : menu_info;

BEGIN
  cnt:=0; i:=0; j:=0; sx:=0;
  LOOP
    IF s[i]='|' THEN
      lns[cnt][j]:=0c; INC(cnt); j:=0;
    ELSIF s[i]=0c THEN
      IF j#0 THEN lns[cnt][j]:=0c; INC(cnt); j:=0 END;
      EXIT;
    ELSE
      lns[cnt][j]:=s[i]; INC(j);
    END;
    IF j>sx THEN sx:=j END;
    INC(i);
  END;
  sx:=((sx+2)*vg.char_w+31) DIV 32;
  sy:=cnt*vg.char_h+2;
  Allocate(inf,SIZE(inf^));
  w:=create(sx,sy);
  w^.info:=inf; inf^.sel:={};
  vg.color(w,3); vg.mode(w,vg.rep); vg.inverse(w,vg.off);
  vg.frame(w,0,0,w^.dsx-1, w^.sy-1);
  vg.color(w,2);
  --vg.prop_font(TRUE);
  FOR i:=0 TO cnt-1 DO
    vg.write_str(w,10,w^.sy-1-(i+1)*vg.char_h,lns[i]);
  END;
  RETURN w;
END cre_tmp_menu;

PROCEDURE tmp_menu(w: window; x,y: INTEGER; sel: menu_proc; info: WORD);
  VAR ch   : CHAR;
      wx,wy: INTEGER;
      sl,i : INTEGER;
      n    : BITSET;
      inf  : menu_info;
      e    : ex.Reaction;
      r    : BOOLEAN;
BEGIN
  w^.x:=x; w^.y:=y;
  open(w);
  LOOP
    read_point(2,w,x,y,ch);
    wx:=x-w^.x*32;
    wy:=y-w^.y;
    inf:=w^.info;
    IF (wx<=0) OR (wx>=(w^.dsx-1)) OR
       (wy<=0) OR (wy>=(w^.sy -1)) THEN n:={};
    ELSE
      sl:=(wy-1) DIV vg.char_h;
      n:={sl};
    END;
    IF n#inf^.sel THEN
      vg.color(w,1); vg.mode(w,vg.rep);
      FOR i:=1 TO 31 DO
        IF i IN (n/inf^.sel) THEN
          IF i IN n THEN
            vg.patt_box(w,1,w^.sy-2-i*vg.char_h,w^.sx*32-2,
                            w^.sy-1-(i+1)*vg.char_h,4);
          ELSE
            vg.patt_box(w,1,w^.sy-2-i*vg.char_h,w^.sx*32-2,
                            w^.sy-1-(i+1)*vg.char_h,0);
          END;
        END;
      END;
      inf^.sel:=n;
      refresh(w);
    END;
    IF (ch=267c) THEN
      IF n#{} THEN
        r:=ex.Exception?(e);
        IF r THEN close(w); ex.RaiseInMe(r)
        ELSE sel(w,sl,info); ex.KillReaction(e) END;
      END;
      close(w); EXIT;
    END;
  END;
  vg.color(w,1); vg.mode(w,vg.rep);
  FOR i:= 1 TO 31 DO
    IF i IN inf^.sel THEN
      vg.patt_box(w,1,w^.sy-i*vg.char_h-2,w^.dsx-2,w^.sy-(i+1)*vg.char_h-2,0);
    END;
  END;
  close(w);
END tmp_menu;

PROCEDURE qwest(rx,ry: INTEGER; pmt: ARRAY OF CHAR): BOOLEAN;
  VAR n,x,y: INTEGER; w: window; ch: CHAR;
BEGIN
  n:=0; WHILE pmt[n]#0c DO INC(n) END;
  n:=((n+2)*vg.char_w+31) DIV 32;
  w:=create(n,(vg.char_h+1)*3); w^.x:=rx; w^.y:=ry;
  vg.color(w,3); vg.mode(w,vg.rep); vg.inverse(w,vg.off);
  vg.frame(w,0,0,w^.dsx-1,w^.sy-1);
  vg.color(w,2);
  vg.print(w,vg.char_w,w^.sy-1-vg.char_h,'%s',pmt);
  vg.print(w,3*vg.char_w,vg.char_h DIV 2,'Yes');
  vg.frame(w,3*vg.char_w-2,vg.char_h DIV 2-2,
             6*vg.char_w+2,vg.char_h DIV 2+vg.char_h+2);
  vg.color(w,1);
  vg.print(w,w^.dsx-1-(5*vg.char_w),vg.char_h DIV 2,'No');
  vg.frame(w,w^.dsx-1-(5*vg.char_w)-2,vg.char_h DIV 2-2,
             w^.dsx-1-(3*vg.char_w)+2,vg.char_h DIV 2+vg.char_h+2);
  open(w);
  LOOP
    read_point(2,w,x,y,ch);
    IF (ch=266c) THEN
      x:=x-w^.x*32; y:=y-w^.y;
      IF (y>=(w^.sy-1-(vg.char_h DIV 2+vg.char_h))) &
         (y<(w^.sy-1-vg.char_h DIV 2)) THEN
        IF (x>=(3*vg.char_w)) & (x<(6*vg.char_w)) THEN
          remove(w); RETURN TRUE
        END;
        IF (x<=(w^.dsx-1-3*vg.char_w)) & (x>(w^.dsx-1-(5*vg.char_w))) THEN
          remove(w); RETURN FALSE
        END;
      END;
    END;
  END;
END qwest;

PROCEDURE messjob(w: window; x,y: INTEGER; ch: CHAR);
  VAR nx,ny: INTEGER;
BEGIN
  ASSERT(w#NIL);
  IF (ch=266c) THEN
    IF ((y-w^.y)>=(w^.sy-1-(2+sign_h))) & ((y-w^.y)<(w^.sy-1-2)) THEN
      IF (x>=w^.x*32+4) & (x<w^.x*32+4+sign_w) THEN
        read_point(1,w,nx,ny,ch);
        close(w); w^.x:=(nx+2) DIV 32; w^.y:=ny-21; open(w);
      ELSIF (x>=w^.x*32+24) & (x<w^.x*32+(24+sign_w)) THEN
        remove(w);
      ELSE
        ontop(w);
      END;
    END;
  END;
END messjob;

PROCEDURE message(x,y: INTEGER; s: ARRAY OF CHAR);
  VAR i,n: INTEGER; w: window;
BEGIN
  i:=0; WHILE s[i]#0c DO INC(i) END;
  IF i<20 THEN i:=20 END;
  i:=((i+2)*char_w+31) DIV 32;
  w:=create(i,4+2+sign_h+2+char_h);
  color(w,4); mode(w,rep);
  vg.patt_box(w,1,sign_h+2,i*32-2,2*sign_h+2,1);
  color(w,8);
  frame(w,0,0,w^.dsx-1,w^.sy-1);
  color(w,8); vg.print(w,4,5+sign_h,'%s',s);
  color(w,4); vg.sign(w,4,2,move);
  vg.sign(w,4,2,del);
  w^.job:=messjob; w^.x:=x; w^.y:=y;
  open(w);
END message;

PROCEDURE readln(rx,ry: INTEGER; pmt: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR n,i,m,x,y: INTEGER; bf: ARRAY [0..3] OF CHAR; w: window; ch: CHAR;
BEGIN
  n:=0; WHILE pmt[n]#0c DO INC(n) END;
  IF HIGH(s)+1>n THEN n:=HIGH(s)+1 END;
  n:=((n+2)*vg.char_w+31) DIV 32;
  w:=create(n,(vg.char_h+1)*2); w^.x:=rx; w^.y:=ry;
  vg.color(w,4); vg.mode(w,vg.rep); vg.inverse(w,vg.off);
  vg.vect(w,0,0,n*32-1,0);             vg.vect(w,n*32-1,0,n*32-1,w^.sy-1);
  vg.vect(w,n*32-1,w^.sy-1,0,w^.sy-1); vg.vect(w,0,w^.sy-1,0,0);
  vg.print(w,vg.char_h,w^.sy-1-vg.char_h,'%s',pmt);
  open(w);
  i:=0;
  IF s[0]=0c THEN str.print(s,'') END;
  WHILE (s[i]#0c)&(i<HIGH(s)) DO INC(i) END;
  m:=i;
  vg.color(w,2);
  vg.print(w,vg.char_w,2,'%s',s);
  LOOP
    vg.print(w,vg.char_w*(i+1),2,'%c',177c);
    vg.print(w,vg.char_w*(i+2),2,'%c',40c);
    refresh(w);
    read_point(3,w,x,y,ch); --wait; first(x,y,ch); drop;
    IF ch=dkb.cr THEN EXIT END;
    IF (ch>=' ')&(ch<200c) OR (ch>300c)&(ch<=377c) THEN
      bf[0]:=ch; bf[1]:=0c;
      vg.print(w,vg.char_w*(i+1),2,'%s',bf);
      s[i]:=ch;
      IF i<HIGH(s) THEN INC(i); IF m<i THEN m:=i END END;
    END;
    IF ((ch=dkb.left)OR(ch=dkb.back))&(i>0) THEN DEC(i) END;
    IF ( ch=dkb.right)&(i<m) THEN
      bf[0]:=s[i]; bf[1]:=0c;
      vg.print(w,vg.char_w*(i+1),2,'%s',bf);
      INC(i)
    END;
  END;
  s[i]:=0c;
  remove(w);
END readln;

PROCEDURE read_string(w: window; x,y,sz: INTEGER; VAR s: ARRAY OF CHAR);
  VAR i,j,m,xx,yy,last_i: INTEGER;
      ch: CHAR;
BEGIN
  ASSERT(w#NIL);
  i:=0;
  WHILE (s[i]#0c)&(i<HIGH(s)) DO INC(i) END;
  IF s[0]=0c THEN str.print(s,'  ') END;
  m:=i;
  lock_window(w);
  vg.color(w,2); vg.mode(w,vg.rep);
  last_i:=-1;
  LOOP
    IF i#last_i THEN
      vg.print(w,x,y,'%s ',s);
      vg.mode(w,vg.xor); vg.print(w,x+vg.char_w*i,y,'%c',253c);
      vg.mode(w,vg.rep);
      ref_box(w,w^.sy-1-y-vg.char_h+1,vg.char_h);
      last_i:=i;
    END;
    read_point(3,w,xx,yy,ch);
    IF ch=dkb.cr THEN EXIT END;
    IF (ch>=' ')&(ch<200c) OR (ch>300c)&(ch<=377c) THEN
      vg.print(w,x+vg.char_w*i,y,'%c',ch);
      IF (i<=HIGH(s)) & (i<(sz-1)) THEN
        s[i]:=ch; INC(i);
        IF i>m THEN
          IF i<=HIGH(s) THEN s[i]:=0c END;
          m:=i;
        END;
      END;
    END;
    IF ((ch=dkb.left)OR(ch=dkb.back))&(i>0) THEN DEC(i) END;
    IF ( ch=dkb.right)&(i<m)                THEN INC(i) END;
  END;
  release_window(w);
  IF i<HIGH(s) THEN s[i]:=0c END;
  i:=0; WHILE (i<=HIGH(s))&(s[i]=40c) DO INC(i) END;
  IF i>HIGH(s) THEN s[0]:=0c; RETURN END;
  j:=0;
  REPEAT s[j]:=s[i]; INC(i); INC(j)
  UNTIL (s[i-1]=0c) OR (s[i-1]=40c) OR (i>HIGH(s));
  s[j-1]:=0c;
END read_string;

PROCEDURE alarm(VAL s: ARRAY OF CHAR);
  VAR sx,sy,sz,i,j,k: INTEGER; w: window; c: CHAR;
      ln: ARRAY [0..79] OF CHAR;
      nx,ny: INTEGER;
BEGIN
  i:=0; sx:=0; sy:=0; j:=0;
  WHILE s[i]#0c DO
    c:=s[i];
    IF (c=NL) OR (c=12c) THEN
      INC(sy); j:=0;
    ELSIF (c>=' ') THEN
      INC(j); IF j>sx THEN sx:=j END;
    END;
    INC(i);
  END;
  IF j#0 THEN INC(sy) END;
  IF sx<10 THEN sx:=10 END;
  sx:=((sx+2)*char_w+31) DIV 32; sy:=(sy+1)*char_h+2;
  sz:=sx*sy*lsno;
  w:=ALLOC(SIZE(w^));
  w^.mem:=ALLOC(sz);
  w^.sx:=sx; w^.sy:=sy;
  w^.open:=FALSE; w^.fwd:=w; w^.bck:=w;
  w^.mem^:=0; MOVE(w^.mem+1,w^.mem,sz-1);
  w^.cx:=0; w^.cy:=0; w^.cl:=w^.mem;
  w^.x:=2; w^.y:=50;
  w^.dsx:=sx*32;
  w^.fwd:=w; w^.bck:=w;
  w^.patt:={0..31};
  vg.color(w,1); vg.mode(w,vg.rep);
  vg.box(w,0,0,sx*32-1,sy-1);
  i:=0; k:=0;
  color(w,8); mode(w,rep); inverse(w,off);
  WHILE s[i]#0c DO
    j:=0;
    LOOP
      c:=s[i];
      IF c=0c THEN EXIT END;
      IF c=12c THEN INC(i); EXIT END;
      IF c=NL  THEN INC(i); EXIT END;
      IF c>=' ' THEN ln[j]:=c; INC(j) END;
      INC(i);
    END;
    ln[j]:=0c;
    vg.print(w,char_w,w^.sy-1-((k+1)*char_h+1),'%s',ln); INC(k);
  END;
  vg.color(w,15);
  vg.sign(w,w^.dsx-(10+sign_w),1,del);
  open(w);
  REPEAT read_point(2,w,nx,ny,c); nx:=nx-w^.x*32; ny:=ny-w^.y
  UNTIL  (nx<w^.dsx-10)&(nx>=w^.dsx-(10+sign_w))&
         (ny>=(sy-1-sign_h))&(ny<(sy-1))&(c=266c);
  close(w);
END alarm;

TYPE tty_rec=RECORD
       wnd  : window;
       x,y  : INTEGER;
       sx,sy: INTEGER;
       beg  : INTEGER;
       end  : INTEGER;
       buf  : ARRAY [0..255] OF CHAR;
       sig  : sch.signal_rec;
     END;
     tty=POINTER TO tty_rec;

PROCEDURE tty_job(w: window; x,y: INTEGER; ch: CHAR);
  VAR t: tty; i: INTEGER;
BEGIN
  IF ch=0c THEN RETURN END;
  t:=w^.info;
  IF t=NIL THEN RETURN END;
  i:=(t^.end+1) MOD (HIGH(t^.buf)+1);
  IF i=t^.end THEN RETURN END;
  t^.buf[t^.end]:=ch;
  t^.end:=i;
  sch.send(t^.sig);
END tty_job;

PROCEDURE read_tty(t: tty): CHAR;
  VAR ch: CHAR;
BEGIN
  sch.wait(t^.sig);
  ch:=t^.buf[t^.beg];
  t^.beg:=(t^.beg+1) MOD (HIGH(t^.buf)+1);
  RETURN ch;
END read_tty;

PROCEDURE create_tty(sx,sy: INTEGER): tty;
  VAR w: window; t: tty;
BEGIN
  Allocate(t,SIZE(t^));
  t^.sx:=sx; t^.sy:=sy; t^.x:=0; t^.y:=0;
  t^.beg:=0;
  t^.end:=0;
  sch.ini_signal(t^.sig,{},0);
  sx:=((sx+2)*char_w+31) DIV 32;
  sy:=sy*char_h+2;
  w:=create(sx,sy);
  w^.info:=t;
  w^.job:=tty_job;
  vg.color(w,10); vg.mode(w,vg.rep);
  vg.frame(w,0,0,sx*32-1,sy-1);
  t^.wnd:=w;
  scr.init(w);
  open(w);
  RETURN t;
END create_tty;

PROCEDURE print(t: tty; fmt: ARRAY OF CHAR; SEQ arg: WORD);
  VAR ln: ARRAY [0..255] OF CHAR; w: window; s: ARRAY [0..79] OF CHAR;
      i,j: INTEGER; c: CHAR; a: ADDRESS;
BEGIN
(*
  str.print(ln,fmt,arg);
  i:=0; j:=0;
  w:=t^.wnd;
  color(w,1);
  inverse(w,vg.off);
  mode(w,vg.xor);
  vg.box(w,(t^.x+1)*char_w,w^.sy-(t^.y+1)*char_h-1,
           (t^.x+2)*char_w-1,w^.sy-(t^.y)*char_h-2);     -- cursor off
  mode(w,rep);
  LOOP
    c:=ln[i]; INC(i);
    IF (c=0c) OR (c=12c) OR (c=NL) OR (c=15c) THEN
      IF j>0 THEN
        IF t^.x+j>t^.sx THEN j:=t^.sx-t^.x END;
        IF j<0 THEN j:=0 END;
        s[j]:=0c;
        write_str(w,(t^.x+1)*char_w,w^.sy-(t^.y+1)*char_h-1,s);
--        ref_box(w,t^.y*12+1,12);
        INC(t^.x,j); j:=0;
      END;
    END;
    IF (c=0c) THEN EXIT END;
    IF (c=12c) OR (c=NL) THEN
      IF t^.y=t^.sy-1 THEN
        a:=w^.mem+w^.sx;
        MOVE(a,a+w^.sx*char_h,w^.sx*(w^.sy-char_h-2));
        a:=w^.mem+w^.sx*(w^.sy-char_h-1); a^:=0;
        MOVE(a+1,a,w^.sx*char_h-1);
--        refresh(w);
      ELSE
        INC(t^.y);
      END;
      IF c=NL THEN t^.x:=0 END;
    END;
    IF c=15c THEN t^.x:=0 END;
    IF c>=' ' THEN s[j]:=c; INC(j) END;
  END;
  mode(w,vg.xor);
  vg.box(w,(t^.x+1)*char_w,w^.sy-(t^.y+1)*char_h-1,
           (t^.x+2)*char_w-1,w^.sy-(t^.y)*char_h-2);     -- cursor on
  refresh(w);
*)
  str.print(ln,fmt,arg);
  i:=0;
  WHILE (ln[i]#0c)&(i<HIGH(ln)) DO i:=i+1 END;
  scr.write(ln,i);
--  refresh(t^.wnd);
END print;

PROCEDURE remove_tty(t: tty);
BEGIN
  IF t=NIL THEN RETURN END;
  t^.wnd^.info:=NIL;
  remove(t^.wnd);
  Deallocate(t,SIZE(t^));
END remove_tty;

VAR term: tty;

PROCEDURE prt_mem(a: ADDRESS; sz: INTEGER);
BEGIN
  print(term,'%$8h %7d\n',a,sz);
END prt_mem;

PROCEDURE free_mem(x,y: INTEGER);
  VAR i,j: INTEGER; c: CHAR;
BEGIN
  term:=create_tty(20,22);
  print(term,'press ESC');
  REPEAT wait; first(i,j,c); drop UNTIL c=33c;
  remove_tty(term);
END free_mem;

END Menu.
