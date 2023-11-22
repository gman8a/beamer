# beamer
Solve structural beams for moments and shears

You can run Beamer at this URL:
   http://174.83.15.115:8090/civilsoft/html/beamer.html

4 beam configuration cases:

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

