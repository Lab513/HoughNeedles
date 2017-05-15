This is the very first version of the linear hough transform for needles detection in MATLAB.

To run the program, launch HoughNeedlesGUI.m
Matlab will first ask you to select a transmitted light image on which to process the Hough transform. It will then ask for a second image, the corresponding fluorescence image from which to process the fluorescence level per needle. Note that this second image is optional and that you can proceed to the main GUI by clicking cancel in the file selection interface.

After the image(s) file(s) have been selected, the program proceeds to the main GUI. Note that, if the window is too small or too large for your screen, you can resize it.
At this point, the GUI asks that you select a background region. Draw a region in the image without needles and then double click on it to launch the image processing.

Once the reference background region has been provided, the program launches the Hough needles processing. This operation may take a while depending on your machine, although it should not last more than a couple minutes.


Once the hough operation is over, the GUI displays the identified needles, and allows you to select them and perform operations on them.

On the right hand side of the GUI window, a cheat sheet of the keyboard shortcuts and a info text are present. The keyboard shortcuts allow you to switch between the different possible operations to perform on the needles to correct the result of the Hough processing step. It is also possible to change parameters and redo the processing, and finally to save the data.

The different possible operations are:

- Add segment mode ('a' key): 
- Move segment mode ('m' key): 
- Cut segment mode ('c' key):
- Fuse segments mode ('f' key):
- Delete segments mode ('d' key):
- Reload needles map ('r' key):
- Nothing mode ('0' key):
- Hide/Un-hide segments ('h' key):
- Toggle between images ('b' key):
- Change threshold value ('t' key):
- Update Hough processing ('u' key):
- Save data to csv file ('s' key):
- Save image file ('i' key):

