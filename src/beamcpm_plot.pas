program beamer;

uses sysutils;

type
  all_char = set of ' '..'}';
  str50    = string[50];
  str70    = string[70];

var
  strln,descrip  : string[85];
  time           : string[50];
  response       : char;     { quest response character }

  o,r,p          : array[0..200,1..2] of real;
  s              : array[0..200] of real;         { shear storage array }
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
	page_width = 1000; { plot svg size}  
	page_height= 1200;


function  when:string;
  begin
	when:=DateTimeToStr(Now)
  End;

procedure error(s:str70);
  begin
    writeln;
    writeln(s);
    writeln;
    writeln('*** Error: Program HALTED ***');
    halt;
  end;

procedure get_input_data; { from OS standard input }
  begin
     repeat readln(strln); until (copy(strln,1,2)='::');
     writeln(strln); descrip:=strln;
     writeln('=====================================================');
     write('...Reading ');
     readln(z);   { Case (Beam Type) }
     readln(l);   { Beam Length }
     readln(d);   { Distance to intermediate support }
     readln(e);   { Modulus of Elasticity }
     readln(i);   { Moment of Inertia }
     readln(sx);  { Section Modulus }
     readln(j);   { Tabulation Interval }
     if (z in [2,3,4]) and (d>0) then
       begin J1:=1; IF INT(D/J)<>0 THEN J1:=trunc(D/J); J:=D/J1; end;
     nl:=0;
     repeat
       nl:=nl+1;
       readln(load[nl,1],load[nl,2],load[nl,3]);
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
        writeln('COMBINED EFFECT OF ALL LOADS');
        writeln;
        write('V1=',v3/1000:9:3,' Kips    V2=',v4/1000:9:3);
        if Z=4 then writeln('    V3=',v5/1000:9:3) else writeln;
      end
    else
      begin
        get_load(load_cnt,a,c,q);
        writeln('LOAD: A=',a:6:2,' ft. C=',c:6:2,' ft. Q=',q/1000:8:3,' Kips/ft');
        writeln;
        if Z=4 then
          writeln('V1=',va/1000:9:3,' Kips    V2=',vb/1000:9:3,'    V3=',(w-va-vb)/1000:9:3)
        else writeln('V1=',va/1000:9:3,' Kips    V2=',(Q*C-VA)/1000:9:3);
      end;
  end;

procedure output_head;
  begin
    writeln('==================================================');
    output_react;
    writeln;
    if ce_flag then begin
      writeln(' TAB         MOMENT        DEFLECTION        SHEAR         STRESS');
      writeln('(FEET)     (KIP-FEET)        (FEET)          (KIPS)         (KSI)');
      writeln('------     ----------      ----------       ---------      -------');
    end
    else begin
      writeln(' TAB         MOMENT        DEFLECTION       STRESS');
      writeln('(FEET)     (KIP-FEET)        (FEET)         (KSI)');
      writeln('------     ----------      ----------       ------');
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
      writeln(X:6:2,MX/1000:15:4,DFF:16:6,SH/1000:16:4,MX*12/SX/1000:13:4)
    else
      writeln(X:6:2,MX/1000:15:4,DFF:16:6,MX*12/SX/1000:13:4);
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
 label L1;
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
    IF Z=4 THEN goto L1;
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
L1:
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
    writeln;
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
    q2,c2      : real;

  const
    puf = 96; { plotter unit factor (dots per inch), Epson mini plotter was 254 units/dots per inch, 
					Video screen is 96 dots per inch (dpi)  see: https://www.pixelto.net/px-to-inches-converter 
					laser printer dpi is high: 300, 600 or even 2400
			  }
    des : array[1..4] of string[10] = ('SHEAR','MOMENT','DEFLECT','LOADING');
    un  : array[1..4] of string[15] = ('Kips','Ft-Kips','Inches','Kips/Ft & Kips');

	page_width = 1000;
	page_height= 1200;

  var 
	cur_x:integer;
	cur_y:integer;
	char_height:integer;
	char_width:integer;
	char_draw_angle:integer;

	procedure MA(x:integer; y:integer);
	begin
		cur_x:=x;
		cur_y:=y;
	end;

	procedure DA(x:integer; y:integer);
	begin
		writeln( format('<line x1="%d" y1="%d" x2="%d" y2="%d"  stroke="red" /> ' ,[cur_y, cur_x, y, x]) );
		cur_x:=x;
		cur_y:=y;
	end;

	procedure LA( text:string);
	begin
		writeln( format('<text x="%d" y="%d">%s</text>', [cur_y, cur_x, text]));
	end;

	procedure SI(h:integer; w:integer); { set char height width }
	begin
		char_height:=h;
		char_width:=w;
	end;

	procedure DI(a:integer); { set char draw angle }
	begin
		char_draw_angle:=a;
	end;

  procedure draw_beam(i:integer);
    var pd : integer;
    begin
      pl:=round(l/psl*puf);
      pd:=round(d/psl*puf);
      MA(ox,oy);
      DA(ox,oy+pl);
      if i=4 then { fixed at far end }
        begin
          case z of
             1,2:begin
                    MA(ox+50,oy+pl);
                    DA(ox-50,oy+pl);
                    DA(ox+50,oy+pl+4);
                    DA(ox-50,oy+pl+4);
                 end;
             3,4:begin { pinned at far end }
                    DA(ox+25,oy+pl-20);
                    DA(ox+25,oy+pl+20);
                    DA(ox,oy+pl);
                 end;
           end{case};
           case z of
                1:begin
                    MA(ox+50,oy);
                    DA(ox-50,oy);
                    DA(ox+50,oy-4);
                    DA(ox-50,oy-4);
                  end;
            2,3,4:begin
                    MA(ox,oy+pd);
                    DA(ox+25,oy+pd-20);
                    DA(ox+25,oy+pd+20);
                    DA(ox,oy+pd);
                    if z=4 then
                      begin
                        pd:=round(0.0/psl*puf);
                        MA(ox,oy+pd);
                        DA(ox+25,oy+pd-20);
                        DA(ox+25,oy+pd+20);
                        DA(ox,oy+pd);
                      end;
                  end;
            end{case};
         end{if i=4};
      MA(ox,10);
      SI(27,27);   { set character height }
      DI(900);     { set character draw angle }
      LA(des[i]);
      SI(23,23);   { set character height }
      MA(ox,oy+pl+50);
      case i of
        1,2:LA( 'Scale: 1 in='    + format('%3d %s', [psm, un[i]]) );
          3:LA( 'Scale: 1 in= 1 ' + format('%s', [un[i]]) );
          4:LA( 'Scale: 1 in='    + format('%3d %s', [psq, un[i]]) );
      end{case};
      if i<4 then
        begin
          MA(ox+50, oy+pl+50);
          LA( format( 'Max.=%7.3f %s at %5.2f ft.', [max[i,1]/1000, un[i], max[i,2]]));
          if i=2 then { stress }
            begin
              MA(ox+100, oy+pl+50);
			  LA( format('STRESS = %7.3f KSI', [max[i,1]*12/1000/Sx]));
            end;
        end
      else
        begin
          MA(ox+50, oy+pl+50);
          LA('SUPPORT REACTIONS');
          MA(ox+100, oy+pl+50);
          LA( format('V1=%9.3f Kips  (Left Side)', [v3/1000]));
          MA(ox+150, oy+pl+50);
          LA( format('V2=%9.3f', [v4/1000]));
          MA(ox+200, oy+pl+50);
          if Z=4 then LA( format('V3=%9.3f', [v5/1000]));
        end;
      MA(ox, oy);
    end;

  begin


    { Make Plotted Output }
	writeln;
	readln(response);
    writeln('Make Plotted Output: ',response);
	if response='Y' then begin

      psl:=1; psm:=1; (*** modify scale as required ***)
      while l/psl>4.5{inches} do begin psl:=psl*2; psm:=psm*2; end;
      writeln('  Plot Scale: Length =',psl:3); 
      writeln('  Plot Scale: Moment =',psm:3); 
	  { user can adjust scaling }
	  readln(psl); 
	  readln(psm); 
      writeln('  Plot Scale: Length =',psl:3); 
      writeln('  Plot Scale: Moment =',psm:3); 

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
      writeln('  Plot Scale: Loading =',psq:3);
	  { user can adjust scaling }
	  readln(psq); 
      writeln('  Plot Scale: Loading =',psq:3);

	  writeln( format( '<svg width="%d" height="%d">', [page_width, page_height]));
      oy:=round(1.0*puf);
      ox:=round(3.0*puf); { <<------ Separate charts here by changing factors }

	  { draw beam with all loadings }
      draw_beam(4);
      load_cnt:=1;
      repeat
        get_load(load_cnt,a,c,q);
        py:=oy+round(a/psl*puf);
        px:=ox;
        MA(px,py);

        if c=0.01 then px:=ox-round(q/1.0e5/psq*puf)
        else if c=0.1 then px:=ox-round(q/1.0e4/psq*puf)
             else px:=ox-round(q/1.0e3/psq*puf);
        DA(px,py);
        py:=oy+round((a+c)/psl*puf);
        DA(px,py);
        px:=ox;
        DA(px,py);
        load_cnt:=load_cnt+1;
      until load_cnt>nl;

      for chart:=1 to 3 do
        begin
          case chart of
            1:ox:=round(5.0*puf); (****  S H E A R  ****) { inches } { <<------ Separate charts here by changing factors }
            2:ox:=round(7.5*puf); (****  M O M E N T  ****)
            3:ox:=round(10.0*puf); (****  D E F L E X S I O N  ****)
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
        	  DA(px,py);
              x:=x+j;
            until x>l;
          until end_chk;
          DA(ox,oy+pl);
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
                MA(ox,py);
                DA(px,py);
                x:=x+j;
              until x>l;
            until end_chk;
          end{if chart}
        end;
      SI(38,38);   { set character height }
	  MA(30,50);
      LA(' BEAMER V2.0 ');

      SI(24,24);   { set character height }
	  MA(30,250);
      LA(' By: GaryArgraves - 8801.01');
   
	  SI(24,24);   { set character height }
	  MA(80,50);
      case z of
        1:LA(' BEAM CASE: FIXED-FIXED  ' + format('L=%6.2f ft.  D=%6.2f ft.',[l,d]));
        2:LA(' BEAM CASE: PINED-FIXED  ' + format('L=%6.2f ft.  D=%6.2f ft.',[l,d]));
        3:LA(' BEAM CASE: PINED-PINED  ' + format('L=%6.2f ft.  D=%6.2f ft.',[l,d]));
        4:LA(' BEAM CASE: PIN-PIN-PIN  ' + format('L=%6.2f ft.  D=%6.2f ft.',[l,d]));
      end{case};

      MA(110, 50);
      LA(format(' E=%8f psi   I=%7.1f in^4    Sx=%6.1f in^3', [e,i,Sx])) ;

      MA(140, 50);
      LA( format('Horz.Scale: %3d Ft/In ; dots per inch = %3d ;  when: %s', [psl, puf, time]));

      MA(170, 50);
      LA(' JOB '+descrip);

      MA(0,0);
      DA(0,page_width);
	  DA(page_height,page_width);
	  DA(page_height,0);
	  DA(0,0);
      MA(0,0);

	  writeln('</svg>');
    end{if plot YES};
  end;

begin    (******   M A I N    L I N E   *******)
   writeln('BEAM CALCULATOR  By: Gary Argraves - 8712.03');
   writeln;
   writeln('Civil Engineering Systems - BEAMER V2.00 - BEAM ANALYSIS');
   writeln('    COPYRIGHT 1983-1988  ALL RIGHTS RESERVED BY:');
   writeln('CompuRight Industries  P.O. Box ???, Newtown CT 06484');
   writeln;
   time := when();

   get_input_data;

   writeln;
   writeln('O U T P U T   D A T A   ',time);
   writeln('==================================================');
   write('BEAM CASE: ');
   case z of
     1:write('FIXED-FIXED');
     2:write('PINED-FIXED');
     3:write('PINED-PINED');
     4:write('PIN-PIN-PIN');
   end{case};
   writeln(' L=',l:6:2,' ft.  D=',d:6:2,' ft.');
   writeln('E=',e:8,' psi   I=',i:7:1,' in^4    Sx=',Sx:6:1,' in^3');

   chk_input_load;
   solve_beam;
   plot;

   writeln;
   writeln('*** BEAMER IS DONE ***');

end.
