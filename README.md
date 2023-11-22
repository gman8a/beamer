# beamer
Solve structural beams for moments and shears

You can run beamer at this URL:
   http://174.83.15.115:8090/civilsoft/html/beamer.html

SAMPLE INPUT DATA

BEAM CALCULATOR  By: Gary Argraves - 8712.03       Page 1

I N P U T   D A T A    NO DATE FUNC.
==================================================

:: W16x36 Beam over garage for House on Great Quarter Road, Newtown CT
3             CASE  1=Fix-Fix 2=Pin-Fix 3=Pin-Pin 4=Pin-Pin-Pin 2-Cantilever
22            L  Beam Length Over All (feet)
000           D  Distance to Intermediate Support from Left End of Beam (feet)
30e6          E  Modulus of Elasticity   Steel=30.0E6 psi  Wood=1.76E6
448           I  Moment of Inertia   (in^4)   used in deflexsion computations
56.5          S  Section Modulus     (in^3)
1.00          t  Tabulation Interval (feet) Output is in tabulated form
0 22 1.100    A =Distance to Load from Left, C =Load Length, Q =Load Intensity
0 0 0.000     NEXT Loading (Q units are Kips/ft.) repeat for all loads;  END of Loading (must be here)
Y    Make Plot Y or N; Using 96 dpi for Video monitor; Printers are 300 dpi,600 or higher
10   Length scale factor
100  Moment/shear scale factor 
10   Loading scale factor

       Case 1. Fixed-Fixed              Case 2. Pinned-Fixed

      ||<--A--><--C-->   ||              <--A--><--C-->   ||
      ||       #######-Q ||                     #######-Q ||
      ||=================||              =================||
      ||                 ||              <--D-->^         ||
      ||<-------L------->||              <-------L------->||


       Case 3. Pinned-Pinned            Case 4. Pin-Pin-Pin

        <--A--><--C-->                   <--A--><--C-->
               #######-Q                        #######-Q
        =================                =================
        <--D-->^        ^                ^<--D-->^       ^
        <-------L------->                <-------L------->


       Case 2. Cantilever (D=L)          Variable Explanation
                                     -----------------------------
        <--A--><--C-->   ||          L = Over All Length (feet)
               #######-Q ||          D = Distance to Support
        =================||          A = Distance to Start of Load
        <-------D------->||          C = Length of Load
        <-------L------->||          Q = Load Intensity (kips/ft.)

    For Concentrated Loads:
    Set C = 0.1' or 0.01' and Increase Q accordingly by a factor of 10 or 100


   W16x36
   Live Load=50 psf + Dead Load=20 psf = 70 psf x 16'= 1120 p/f say 1100
:: END OF INPUT

