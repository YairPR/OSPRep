  -- Segment Stats
--  IF have_segstats THEN
      print('<A NAME="segstat"></A>');
    IF MK_SEG_LR = 1 THEN
      seg_lr;
    END IF;
    IF MK_SEG_PR = 1 THEN
--      print ('PR_GO_HERE<br>');
      seg_pr;
    END IF;
    print('<HR>');
--  END IF;