/** NucJ
 * Author: Teva Bracha
 * Date: 6/16/21
 * 
 * This macro counts the number of cells in all images in a single directory by processing
 * the images as a stack.
 * 
 */
macro "NucJ" {

// Function to count cells in slices
function Count(cellMin, cellMax, slices) {
	setSlice(1);
	for (i = 0; i < slices; i++) {
		// Gets the cell count of the entire image
		run("Analyze Particles...", "size=cellMin-cellMax summarize");
		run("Next Slice [>]");
	}	
}

// Getting directory and list of images
dir = getDirectory("Choose a Directory");
list = getFileList(dir);

// Initializing variables
count = 0;
cellMin = 0;
cellMax = 1/0;

// Opening the first image for ROIs
open(dir + list[0]);

// Creating a Dialog to setup the macro running configurations
optionCell = newArray("Entry", "Calibration");
optionThresh = newArray("Otsu", "Huang", "Manual");

Dialog.create("Setup Conditions");
Dialog.addChoice("Entry or Calibration?", optionCell);
Dialog.addChoice("Thresholding Algorithm?", optionThresh);
Dialog.show();
choiceCell = Dialog.getChoice();
choiceThresh = Dialog.getChoice();


// Determining cell size through either manual or automatic means
if (choiceCell == "Entry") {
	Dialog.create("Cell Size Range");
	Dialog.addNumber("Min", 0);
	Dialog.addNumber("Max", 1/0);
	Dialog.show();

	cellMin = Dialog.getNumber();
	cellMax = Dialog.getNumber();
	step = 0; // indicates we are in Entry mode rather than Calibration
}
else if (choiceCell == "Calibration") {
	Dialog.create("Cell Size Range");
	Dialog.addNumber("Begin", 0);
	Dialog.addNumber("End", 25);
	Dialog.addNumber("Step", 5);
	Dialog.show();

	cellMin = Dialog.getNumber();
	cellMax = Dialog.getNumber();
	step = Dialog.getNumber();

}


// Opening the directory as a stack 
open(dir);


// Thresholding/Processing the images
slices = nSlices();

// Subtract Background
for (i = 0; i < slices; i++) {
	run("Subtract Background...", "rolling=50 sliding");
	run("Next Slice [>]");
}

if (choiceThresh == "Otsu") {
	// Threshold with Otsu	
	setSlice(1);
	setAutoThreshold("Otsu dark");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Otsu background=Dark calculate black");
	run("Watershed");
}
else if (choiceThresh == "Huang") {
	// Threshold with Huang
	setSlice(1);
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Huang background=Dark calculate black");
	run("Watershed");
}
else {
	// Manual Threshold
	run("Threshold...");
	waitForUser("Set the threshold. You can apply the threshold to all images at once, or set them indiviudally.");
	run("Watershed");
}


// If step = 0 just count once with given parameters
if (step == 0) {
	Count(cellMin, cellMax, slices);
}
// Otherwise count once for each cellMin specified
else {
	CSC = cellMin;
	while (CSC <= cellMax) {
		Count(CSC, 1/0, slices);
		CSC += step;
	}
}

// Saving the results to the directory
image = getTitle;
selectWindow("Summary of " + image);
IJ.renameResults("Results");


name = getString("What would you like to name your file?", "Results");
IJ.renameResults(name);
saveAs("results", dir + name + ".csv");
}