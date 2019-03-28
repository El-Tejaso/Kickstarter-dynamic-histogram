# Kickstarter dynamic histogram visualisation

This was a project that I worked on in 2018 for a first year university course (UofA Grand Challenges in Computer Science).

The full .csv file is available from here: https://www.kaggle.com/kemical/kickstarter-projects \
I am unable to include it here due to my poor upload speeds, and perhaps some github filesize restrictions, but downloading it from there
and then replacing it should work.

The project works with Processing, and much of the UI was from ControlP5. The code for the dynamic histogram is my own though.
That said, it could be a lot better. Moving the histogram shouldn't require a total recalculation of all of the bins, just of the parts that haven't already been calculated.
Only zooming in/out should recalculate them due to the bins resizing, and then it should only recalculate the bins that are 
currently being looked at if they haven't already been calculated yet.

Maybe I'll do a full rewrite at some point?
