{ Copyright 1983 - 1988  By: CompuRight Industries
      Written by: Gary Argraves 1983
      Up-Graded to Turbo Pascal V4.0 - 8712.24  }

{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

uses dos,crt;

type
  all_char = set of ' '..'}';

var
  fn             : string[25];
  in_f,out_f     : text;
  strln,descrip  : string[85];
  time           : string[50];
  response       : char;     { quest response character }

  o,r,p          : array[0..400,1..2] of real;
  s              : array[0..400] of real;         { shear storage array }
  max            : array[1..4,1..2] of real;
  load           : array[1..30,1..3] of real;     { Input Loading array }
  l,d,a,c,q      : real;     { beam length, dist to support, Load Vars }
  E,I,Sx,j       : real;     { j is the beam TAB interval }
  z,k,J1         : integer;  { Beam Case, Index to storage arrays, TAB var }
  v3,v4,v5       : real;     { combined effects support reactions }
  va,vb          : real;     { support reactions }
  ma,mb,mx,sh    : real;     { moments, shear }
  df,x,w         : real;     { deflexion vars, TABed distance along beam }

  nl             : integer;  { number of loads in input file }
  load_cnt       : integer;  { load count }
  ce_flag        : boolean;  { combine effect flag }


const
  page_msg = 'BEAM CALCULATOR  By: Gary Argraves - 8712.03';

function  when:string;
  Const
    DayName: Array [1..7] Of String[3]=
      ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    MonName: Array [1..12] Of String[3]=
      ('Jan','Feb','Mar','Apr','May','Jun','Jul',
       'Aug','Sep','Oct','Nov','Dec');
  Var
    h,m,s,sh,
    y,mon,d,dw : word;
    ap         : string[2];
    i          : string[4];

   Function V2(I:Integer):String;
      Begin V2:=Chr(48+I Div 10)+Chr(48+I Mod 10); End;

  begin
    gettime(h,m,s,sh);
    getdate(y,mon,d,dw);
    AP:='am';
    If H>11 Then AP:='pm';
    H:=H Mod 12;
    If H=0 Then H:=12;
    str(y:4,i);
    when:=v2(h)+':'+v2(m)+ap+' '+
      dayname[dw+1]+', '+monname[mon]+' '+v2(d)+', '+i;
  End;

procedure quest(s:string; op_set:all_char);
    begin
      write(s);
      repeat
        write(^G);
        repeat until keypressed;
        response:=upcase(readkey);
      until response in op_set;
      writeln(response);
    end;

procedure error(s:string);
  begin
    writeln(out_f);
    writeln(out_f,s);
    write(out_f,^L);
    close(out_f);
    erase(in_f);
    rename(out_f,fn);
    writeln(^G,'*** Error: Program HALTED ***');
    halt;
  end;

procedure get_input_data;
  begin
     if paramCount>0 then fn:=paramStr(1)
     else begin write('Enter Input File Name: ',^G); readln(fn); writeln; end;
     assign(in_f,fn);
     {$I-} reset(in_f); {$I+}
     if IoResult>0 then
       begin
         writeln(^G,'*** Error: Can NOT Find File: ',fn,' ***');
         halt;
       end;
     repeat readln(in_f,strln); until copy(strln,1,2)='::';
     writeln(strln); descrip:=strln;
     writeln('=====================================================');
     write('...Reading ');
     readln(in_f,z);   { Case (Beam Type) }
     readln(in_f,l);   { Beam Length }
     readln(in_f,d);   { Distance to intermediate support }
     readln(in_f,e);   { Modulus of Elasticity }
     readln(in_f,i);   { Moment of Inertia }
     readln(in_f,sx);  { Section Modulus }
     readln(in_f,j);   { Tabulation Interval }
     if (z in [2,3,4]) and (d>0) then
       begin J1:=1; IF INT(D/J)<>0 THEN J1:=trunc(D/J); J:=D/J1; end;
     nl:=0;
     repeat
       nl:=nl+1;
       readln(in_f,load[nl,1],load[nl,2],load[nl,3]);
       load[nl,3]:=load[nl,3]*1000;
     until load[nl,3]=0;
     nl:=nl-1;
  end;

procedure get_load(i:integer; var a,c,q:real);
  begin a:=load[i,1]; c:=load[i,2]; q:=load[i,3]; end;

procedure chk_input_load;
  var i : integer;
  begin
    write('...Checking ');
    for i:=1 to nl do
      begin
        get_load(i,a,c,q);
        IF (A+C>L) OR (D>L) THEN error('ERROR A+C>L OR D>L');
        IF (D=L) AND (Z=3) THEN error('ERROR D=L BEAM NOT STACTIC');
        IF ((D=L) OR (D=0)) AND (Z=4) THEN error('ERROR D=L OR D=0 FOR PIN-PIN BEAM USE CASE 3');
      end;
  end;

procedure sign_on;
  begin
     DirectVideo:=false; { Crt variable }
     clrscr;
     writeln('Civil Engineering Systems - BEAMER V2.00 - BEAM ANALYSIS');
     writeln('    COPYRIGHT 1983-1988  ALL RIGHTS RESERVED BY:');
     writeln('CompuRight Industries  P.O. Box 719, Newtown CT 06482');
     writeln;
     time:=when;
  end;

procedure dup_input_file;
  begin
    write('...Copying ');
    assign(out_f,'$temp.dat');
    rewrite(out_f);
    writeln(out_f,page_msg,'       Page 1');
    writeln(out_f);
    writeln(out_f,'I N P U T   D A T A   ',time);
    writeln(out_f,'==================================================');
    writeln(out_f);
    reset(in_f);
    repeat readln(in_f,strln); until copy(strln,1,2)='::';
    writeln(out_f,strLn);
    repeat
      readln(in_f,strln); writeln(out_f,strLn);
    until copy(strln,1,2)='::';
    writeln(out_f,^L);
    writeln(out_f,page_msg,'       Page 2');
    close(in_f);
    writeln(out_f);
    writeln(out_f,'O U T P U T   D A T A   ',time);
    writeln(out_f,'==================================================');
    write(out_f,'BEAM CASE: ');
    case z of
      1:write(out_f,'FIXED-FIXED');
      2:write(out_f,'PINED-FIXED');
      3:write(out_f,'PINED-PINED');
      4:write(out_f,'PIN-PIN-PIN');
    end{case};
    writeln(out_f,'  L=',l:6:2,' ft.  D=',d:6:2,' ft.');
    writeln(out_f,'E=',e:8,' psi   I=',i:7:1,' in^4    Sx=',Sx:6:1,' in^3');
  end;

function cub (x:real):real; begin cub:=x*x*x; end;
function quad(x:real):real; begin quad:=x*x*x*x; end;

procedure init_var;
  var i : integer;
  begin
    for i:= 1 to 200 do
      begin o[i,1]:=0; o[i,2]:=0;
            r[i,1]:=0; r[i,2]:=0;
            p[i,1]:=0; p[i,2]:=0;
            s[i]:=0;
      end;
    v3:=0; v4:=0; v5:=0;  { cumlative shears }
    for i:=1 to 4 do max[i,1]:=0;
    ce_flag:=false;
  end;

procedure output_react;
  var a,c,q : real;
  begin
    if ce_flag then
      begin
        writeln(out_f,'COMBINED EFFECT OF ALL LOADS');
        writeln(out_f);
        write(out_f,'V1=',v3/1000:9:3,' Kips    V2=',v4/1000:9:3);
        if Z=4 then writeln(out_f,'    V3=',v5/1000:9:3) else writeln(out_f);
      end
    else
      begin
        get_load(load_cnt,a,c,q);
        writeln(out_f,'LOAD: A=',a:6:2,' ft. C=',c:6:2,' ft. Q=',q/1000:8:3,' Kips/ft');
        writeln(out_f);
        if Z=4 then
          writeln(out_f,'V1=',va/1000:9:3,' Kips    V2=',vb/1000:9:3,'    V3=',(w-va-vb)/1000:9:3)
        else writeln(out_f,'V1=',va/1000:9:3,' Kips    V2=',(Q*C-VA)/1000:9:3);
      end;
  end;

procedure output_head;
  begin
    writeln(out_f,'==================================================');
    output_react;
    writeln(out_f);
    if ce_flag then begin
      writeln(out_f,' TAB         MOMENT        DEFLECTION        SHEAR         STRESS');
      writeln(out_f,'(FEET)     (KIP-FEET)        (FEET)          (KIPS)         (KSI)');
      writeln(out_f,'------     ----------      ----------       ---------      -------');
    end
    else begin
      writeln(out_f,' TAB         MOMENT        DEFLECTION       STRESS');
      writeln(out_f,'(FEET)     (KIP-FEET)        (FEET)         (KSI)');
      writeln(out_f,'------     ----------      ----------       ------');
    end;
  end;

procedure output_data;
  var
    dff : real;
  begin
    if abs(df)<1.0e-09 then dff:=0 else DFF:=-DF*144/E/I;
    if not ce_flag then
      begin
        R[K,1]:=R[K,1]+MX;
        if abs(r[k,1])>abs(max[2,1]) then
          begin max[2,1]:=r[k,1]; max[2,2]:=x; end;
        R[K,2]:=R[K,2]+DF;
        if abs(r[k,2])>abs(max[3,1]) then
          begin max[3,1]:=r[k,2]; max[3,2]:=x; end;
      end;
    
    if ce_flag then
      writeln(out_f,X:6:2,MX/1000:15:4,DFF:16:6,SH/1000:16:4,MX*12/SX/1000:13:4)
    else
      writeln(out_f,X:6:2,MX/1000:15:4,DFF:16:6,MX*12/SX/1000:13:4);
  end;

function end_chk:boolean;
  begin
    IF ABS(X-J-L)>=0.001 THEN
      begin X:=L; end_chk:=false; end
    else end_chk:=true;
  end;

procedure fix_fix;
  begin
    D:=0;
    D:=A+C;
    MA:=-Q/12/L/L*(6*L*L*(D*D-A*A)-8*L*(cub(D)-cub(A))+3*(quad(D)-quad(A)));
    MB:=-Q/12/L/L*(4*L*(cub(D)-cub(A))-3*(quad(D)-quad(A)));
    VA:=Q*C/L*(L-A-C/2)+(MB-MA)/L;
    VB:=Q*C-VA;
    output_head;
    X:=0;
    repeat
      repeat
        DF:=VA*cub(X)/6+MA*sqr(X)/2;
        MX:=VA*X+MA;
        IF (X>A) and (X<=A+C) THEN
          begin
            MX:=MX-Q/2*sqr(X-A);
            DF:=DF-Q/2*(quad(X)/12-cub(X)*A/3+A*A*X*X/2+quad(A)/12-cub(A)*X/3)
          end;
        IF X>A+C THEN
          begin
            MX:=(Q*C-VA)*(L-X)+MB;
            DF:=VB/2*(L*sqr(X)-cub(X)/3-sqr(L)*X+cub(L)/3)+MB*(-L*X+X*X/2+L*L/2);
          end;
        K:=K+1;
        output_data;
        X:=X+J;
      until X>L;
    until end_chk;
  end;

procedure pin_fix;
  var
    TR     : integer;
    T,Y,D1 : real;

  procedure pro1;
    begin
      IF D>=A+C THEN T:=C*Q*sqr(L-D)*((L-D)/3-A/2-C/4+D/2)
      else begin
        IF D<A+0 THEN D:=A;
        Y:=A+C-D;
        T:=Q/2*Y*Y*(Y*Y/4+2*(D-A)*Y/3+sqr(D-A)/2);
        Y:=L-D;
        T:=T+C*Q*Y*Y*(Y/3-A/2-C/4+D/2);
        Y:=A+C-D;
        T:=T-C*Q*Y*Y*(Y/3-A/2-C/4+D/2);
      end;
      D:=D1;
      IF TR=1 THEN D:=X;
      IF D<A+0 THEN T:=T+(A-D)*C/2*Q*((A-L)*(A-L+C)+sqr(C)/3);
    end;

  begin
    VA:=C*Q;
    D1:=D;
    TR:=0;
    IF D<L THEN pro1;
    IF D<L THEN VA:=T*3/cub(L-D);
    TR:=1;
    IF Z=2 THEN output_head;
    X:=0;
    repeat
      repeat
        MX:=0;
        IF X>A+0 THEN MX:=-Q/2*sqr(X-A);
        IF X>A+C THEN MX:=-C*Q*(X-A-C/2);
        IF X>D THEN   MX:=MX+VA*(X-D);
        IF X<=D THEN  DF:=VA*sqr(L-D)/6*(3*L-3*X-L+D);
        IF X>D THEN   DF:=VA*sqr(L-X)/6*(3*(L-D)-L+X);
        D:=X;
        pro1;
        DF:=DF-T;
        K:=K+1;
        IF Z<>2 THEN
          begin
            O[K,1]:=MX;
            O[K,2]:=DF;
          end
        else output_data;
        D:=D1;
        X:=X+J;
      until x>l;
    until end_chk;
  end;

procedure pin_pin;
 var
   V2 : real;
  begin
    pin_fix;
    V2:= O[K,1] /(L-D);
    K:=0;
    X:=0;
    repeat
      repeat
        K:=K+1;
        IF X>D+0 THEN O[K,1]:=O[K,1]-V2*(X-D);
        IF X<D+0 THEN DF:=(cub(L-X)-cub(D-X))/3+(X-D)/2*(sqr(L-X)-sqr(D-X));
        IF X>=D THEN  DF:=sqr(L-X)*(L/3-D/2+X/6);
        DF:=V2*(sqr(L-D)/3*(L-X)-DF);
        O[K,2]:=O[K,2]+DF;
        X:=X+J;
      until x>l;
    until end_chk;
    VA:=VA-V2;
    IF Z=4 THEN exit;
    output_head;
    K:=0;
    X:=0;
    repeat
      repeat
        K:=K+1;
        MX:=O[K,1];
        DF:=O[K,2];
        output_data;
        X:=X+J;
      until x>l;
    until end_chk;
  end;

procedure pin_pin_pin;
  var
    V1,D2 : real;
  begin
    W:=C*Q;
    D2:=D;
    D:=0;
    pin_pin;
    V1:=VA;
    VB:=-O[J1+1,2]*3*L/sqr(D2)/sqr(L-D2);
    C:=0.001;
    A:=D2-0.0005;
    D:=0;
    Q:=VB*1000;
    K:=0;
    X:=0;
    repeat
      repeat
        K:=K+1;
        P[K,1]:=O[K,1];
        P[K,2]:=O[K,2];
        X:=X+J;
      until x>l;
    until end_chk;
    K:=0;
    pin_pin;
    VA:=V1-VA;
    D:=D2;
    output_head;
    K:=0;
    X:=0;
    repeat
      repeat
        K:=K+1;
        MX:=P[K,1]-O[K,1];
        DF:=P[K,2]-O[K,2];
        output_data;
        X:=X+J;
      until x>l;
    until end_chk;
  end;

procedure combined_effects;

  procedure compute_shears;
    var i : integer;

     procedure tab_shears;
       var vx : real;
         begin
           x:=0; k:=0;
           repeat
             repeat
               k:=k+1;
               vx:=0;
               if (x>a) and (x<=a+c) then vx:=(x-a)*q
               else if x>a+c then vx:=c*q;
               s[k]:=s[k]-vx;
               if abs(s[k])>abs(max[1,1]) then
                 begin max[1,1]:=s[k]; max[1,2]:=x; end;
               x:=x+j;
             until x>l;
           until end_chk;
         end;

      begin
        k:=0;
        x:=0;
        repeat
          repeat
            k:=k+1;
            case z of
                1:s[k]:=v3;
              2,3:if x>=d then s[k]:=v3 else s[k]:=0;
                4:begin s[k]:=v3; if x>=d then s[k]:=s[k]+v4; end;
            end{case};
            x:=x+j;
          until x>l;
        until end_chk;
        for i:=1 to nl do begin get_load(i,a,c,q); tab_shears; end;
      end;

  begin { combined effects }
    compute_shears;
    writeln(out_f);
    ce_flag:=true; output_head;
    K:=0;
    X:=0;
    repeat
      repeat
        K:=K+1;
        MX:=R[K,1];
        DF:=R[K,2];
        SH:=S[K];
        output_data;
        X:=X+J;
      until x>l;
    until end_chk;
  end;

procedure solve_beam;

  procedure sum_reaction;
    begin
      V3:=V3+VA;
      if z=4 then
        begin V4:=V4+VB; V5:=V5+W-VA-VB; end
      else V4:=V4+C*Q-VA;
    end;

  begin
    writeln('...Computing');
    init_var;
    load_cnt:=1;
    while load_cnt<=nl do
      begin
        K:=0; get_load(load_cnt,a,c,q);
        case z of
          1:fix_fix;
          2:pin_fix;
          3:pin_pin;
          4:pin_pin_pin;
        end{case};
        sum_reaction;
        load_cnt:=load_cnt+1;
      end;
    combined_effects;
    max[3,1]:=max[3,1]*144.0e3/E/I*12; { maximum deflexsion in inches }
  end;

procedure plot;
  var
    ox,oy      : integer;   { origin x,y }
    px,py,pl   : integer;   { plot x,y,length of beam }
    psl,psm    : integer;   { plot scale length, moment }
    psq        : integer;
    chart      : integer;   { shear, moment or deflexsion chart type }
    plot_file  : text;      { output handle }
    q2,c2      : real;

  const
    puf = 254; { plotter unit factor (per inch) }
    des : array[1..4] of string[10] = ('SHEAR','MOMENT','DEFLECT','LOADING');
    un  : array[1..4] of string[15] = ('Kips','Ft-Kips','Inches','Kips/Ft & Kips');

  procedure draw_beam(i:integer);
    var pd : integer;
    begin
      pl:=round(l/psl*puf);
      pd:=round(d/psl*puf);
      writeln(plot_file,'MA ',ox:4,',',oy:4);
      writeln(plot_file,'DA ',ox:4,',',oy+pl:4);
      if i=4 then { fixed at far end }
        begin
          case z of
             1,2:begin
                    writeln(plot_file,'MA ',ox+50:4,',',oy+pl:4);
                    writeln(plot_file,'DA ',ox-50:4,',',oy+pl:4);
                    writeln(plot_file,'DA ',ox+50:4,',',oy+pl+4:4);
                    writeln(plot_file,'DA ',ox-50:4,',',oy+pl+4:4);
                 end;
             3,4:begin { pinned at far end }
                    writeln(plot_file,'DA ',ox+25:4,',',oy+pl-20:4);
                    writeln(plot_file,'DA ',ox+25:4,',',oy+pl+20:4);
                    writeln(plot_file,'DA ',ox:4,',',oy+pl:4);
                 end;
           end{case};
           case z of
                1:begin
                    writeln(plot_file,'MA ',ox+50:4,',',oy:4);
                    writeln(plot_file,'DA ',ox-50:4,',',oy:4);
                    writeln(plot_file,'DA ',ox+50:4,',',oy-4:4);
                    writeln(plot_file,'DA ',ox-50:4,',',oy-4:4);
                  end;
            2,3,4:begin
                    writeln(plot_file,'MA ',ox:4,',',oy+pd:4);
                    writeln(plot_file,'DA ',ox+25:4,',',oy+pd-20:4);
                    writeln(plot_file,'DA ',ox+25:4,',',oy+pd+20:4);
                    writeln(plot_file,'DA ',ox:4,',',oy+pd:4);
                    if z=4 then
                      begin
                        pd:=round(0.0/psl*puf);
                        writeln(plot_file,'MA ',ox:4,',',oy+pd:4);
                        writeln(plot_file,'DA ',ox+25:4,',',oy+pd-20:4);
                        writeln(plot_file,'DA ',ox+25:4,',',oy+pd+20:4);
                        writeln(plot_file,'DA ',ox:4,',',oy+pd:4);
                      end;
                  end;
            end{case};
         end{if i=4};
      writeln(plot_file,'MA ',ox:4,',',10:4);
      writeln(plot_file,'SI 27 27');   { set character height }
      writeln(plot_file,'DI 900');     { set character draw angle }
      writeln(plot_file,'LA ',des[i]);
      writeln(plot_file,'SI 23 23');   { set character height }
      writeln(plot_file,'MA ',ox:4,',',oy+pl+50:4);
      case i of
        1,2:writeln(plot_file,'LA ','Scale: 1"=',psm,' ',un[i]);
          3:writeln(plot_file,'LA ','Scale: 1"= 1 ',un[i]);
          4:writeln(plot_file,'LA ','Scale: 1"=',psq,' ',un[i]);
      end{case};
      if i<4 then
        begin
          writeln(plot_file,'MA ',ox+50:4,',',oy+pl+50:4);
          writeln(plot_file,'LA Max.=',max[i,1]/1000:7:3,' at ',max[i,2]:5:2,' ft.');
          if i=2 then { stress }
            begin
              writeln(plot_file,'MA ',ox+100:4,',',oy+pl+50:4);
              writeln(plot_file,'LA STRESS =',max[i,1]*12/1000/Sx:7:3,' KSI');
            end;
        end
      else
        begin
          writeln(plot_file,'MA ',ox+50:4,',',oy+pl+50:4);
          writeln(plot_file,'LA SUPPORT REACTIONS');
          writeln(plot_file,'MA ',ox+100:4,',',oy+pl+50:4);
          writeln(plot_file,'LA   V1=',v3/1000:9:3,' Kips   (Left Side)');
          writeln(plot_file,'MA ',ox+150:4,',',oy+pl+50:4);
          writeln(plot_file,'LA   V2=',v4/1000:9:3);
          writeln(plot_file,'MA ',ox+200:4,',',oy+pl+50:4);
          if Z=4 then writeln(plot_file,'LA   V3=',v5/1000:9:3);
        end;
      writeln(plot_file,'MA ',ox:4,',',oy:4);
    end;

  begin
    writeln; quest('Make Plotted Output (Y/N) ? ',['Y','N']);
    if response='Y' then begin
      quest('  Send Plot Data to DOS Handle  [A]ux1  [F]ile ? ',['A','F']);
      case response of
        'A':assign(plot_file,'COM1');
        'F':begin
              assign(plot_file,'PLOT.OUT');
              writeln('    Plot Output File Name: PLOT.OUT');
            end;
      end{case};
      rewrite(plot_file);

      psl:=1; psm:=1; (*** modify scale as required ***)
      while l/psl>4.5{inches} do begin psl:=psl*2; psm:=psm*2; end;
      write('  Plot Scale: Length =',psl:3,' ? '); readln(psl);
      write('  Plot Scale: Moment =',psm:3,' ? '); readln(psm);

      q2:=0;        { see if we to to change plot scale for loading }
      load_cnt:=1;
      repeat        { get max load }
        get_load(load_cnt,a,c,q);
        if abs(q)>abs(q2) then begin q2:=q; c2:=c; end;
        load_cnt:=load_cnt+1;
      until load_cnt>nl;
      psq:=1200;
      px:=0;
      while px<20 do
        begin       { decrease plot scale as required }
          if c2=0.01 then px:=round(q2/1.0e5/psq*puf)
          else if c2=0.1 then px:=round(q2/1.0e4/psq*puf)
               else px:=round(q2/1.0e3/psq*puf);
          psq:=trunc(psq/2);
          if psq=150 then psq:=200 else if psq=25 then psq:=40;
        end;
      write('  Plot Scale: Loading =',psq:3,' ? '); readln(psq);

      if response='A' then
        quest('  Put New Paper in Plotter.  ...Press <SPACE BAR>',[' ']);
      writeln(plot_file,'IN');    { plot initialize }
      writeln(plot_file,'SP 1');  { select pen #1 }
      oy:=round(1.0*puf);
      ox:=round(2.0*puf);

      draw_beam(4);
      load_cnt:=1;
      repeat
        get_load(load_cnt,a,c,q);
        py:=oy+round(a/psl*puf);
        px:=ox;
        writeln(plot_file,'MA ',px:4,',',py:4);
        if c=0.01 then px:=ox-round(q/1.0e5/psq*puf)
        else if c=0.1 then px:=ox-round(q/1.0e4/psq*puf)
             else px:=ox-round(q/1.0e3/psq*puf);
        writeln(plot_file,'DA ',px:4,',',py:4);
        py:=oy+round((a+c)/psl*puf);
        writeln(plot_file,'DA ',px:4,',',py:4);
        px:=ox;
        writeln(plot_file,'DA ',px:4,',',py:4);
        load_cnt:=load_cnt+1;
      until load_cnt>nl;

      for chart:=1 to 3 do
        begin
          case chart of
            1:ox:=round(4.0*puf); (****  S H E A R  ****) { inches }
            2:ox:=round(6.5*puf); (****  M O M E N T  ****)
            3:ox:=round(9.0*puf); (****  D E F L E X S I O N  ****)
          end{case};
          draw_beam(chart);
          x:=0;
          k:=0;
          repeat
            repeat
              k:=k+1;
              case chart of
                1:px:=ox-round(s[k]/1000/psm*puf);
                2:px:=ox-round(r[k,1]/1000/psm*puf);
                3:if abs(r[k,2])<1.0e-09 then px:=ox
                  else px:=ox-round(r[k,2]*12*144/E/I*puf);
              end{case};
              py:=oy+round(x/psl*puf);
              writeln(plot_file,'DA ',px:4,',',py:4);
              x:=x+j;
            until x>l;
          until end_chk;
          writeln(plot_file,'DA ',ox:4,',',oy+pl:4);
          if chart in [1,2] then begin { fill shear and moment diagram }
            x:=0;
            k:=0;
            repeat
              repeat
                k:=k+1;
                case chart of
                  1:px:=ox-round(s[k]/1000/psm*puf);
                  2:px:=ox-round(r[k,1]/1000/psm*puf);
                end{case};
                py:=oy+round(x/psl*puf);
                writeln(plot_file,'MA ',ox:4,',',py:4);
                writeln(plot_file,'DA ',px:4,',',py:4);
                x:=x+j;
              until x>l;
            until end_chk;
          end{if chart}
        end;
      writeln(plot_file,'SI 38 38');   { set character height }
      writeln(plot_file,'MA 50 300');
      writeln(plot_file,'LA BEAMER V2.0 ');
      writeln(plot_file,'SI 24 24');   { set character height }
      writeln(plot_file,'LA By: G.L.A. - 8801.01');
      writeln(plot_file,'SI 24 24');   { set character height }
      writeln(plot_file,'MA 100 300');
      write(plot_file,'LA  BEAM CASE: ');
      case z of
        1:write(plot_file,'FIXED-FIXED');
        2:write(plot_file,'PINED-FIXED');
        3:write(plot_file,'PINED-PINED');
        4:write(plot_file,'PIN-PIN-PIN');
      end{case};
      writeln(plot_file,'  L=',l:6:2,' ft.  D=',d:6:2,' ft.');
      writeln(plot_file,'MA 140 300');
      writeln(plot_file,'LA  E=',e:8,' psi   I=',i:7:1,' in^4    Sx=',Sx:6:1,' in^3');
      writeln(plot_file,'MA 180 300');
      writeln(plot_file,'LA  Horz.Scale: ',psl,' Ft/In  FILE: ',fn,'  ',time);
      writeln(plot_file,'MA 220 300');
      writeln(plot_file,'LA  JOB',descrip);
      writeln(plot_file,'MA 0,0');
      writeln(plot_file,'DA 0 1910 2500 1910 2500 0 0 0');
      writeln(plot_file,'MA 0,0');
      close(plot_file);
    end{if plot YES};
  end;

procedure done;
  begin
    writeln;
    writeln('BEAMER''s Solution has been Appended to the Input File: ',fn);
    writeln;
    writeln('*** BEAMER IS DONE ***',^G);
    write(out_f,^L);
    close(out_f);
    erase(in_f);
    rename(out_f,fn);
  end;

begin    (******   M A I N    L I N E   *******)
   sign_on;
   get_input_data;
   dup_input_file;
   chk_input_load;
   solve_beam;
   plot;
   done;
end.
