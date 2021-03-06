// Neuron Density Heatmap Tool
 
// Author: 	Luke Hammond (lh2881@columbia.edu)
// Cellular Imaging | Zuckerman Institute, Columbia University
// Date:	30th January 2019
	
// This macro measures the density at each pixel and maps this relative to the soma.
// Note: Expects scaling information to be included in the metadata. 
 			
// Usage:

//	1. Run on folder containing preprocessed (filtered and thresholded) 2d neuron images
//  Images should be skeletonized or processed so all cells thresholded consistently 
//  - over or under thresholded data will affect density calculations.

// Updates:
// updated to use kernal for density calulation - faster and samples every pixel

// Initialization

requires("1.52p");
run("Options...", "iterations=3 count=1 black do=Nothing");
run("Set Measurements...", "fit redirect=None decimal=3");
run("Colors...", "foreground=white background=black selection=yellow");
run("Clear Results"); 
run("Close All");

Ver ="Branch Density Heatmap v0.3.0";
ReleaseDate= "January 30, 2019."

// Select input directories

#@ File[] listOfPaths(label="Select folders containing thresholded neuron images:", style="both")
//Add a message line - 
#@ Integer(label="Width of square region for performing density analysis (in um):", value = 50, style="spinner", description="") BoxDim

print("\\Clear");
print("- - - " +Ver+ " - - -");
print("Version release date: " +ReleaseDate);
print("  ");

setBatchMode(true);

for (FolderNum=0; FolderNum<listOfPaths.length; FolderNum++) {
	starttime = getTime();
	inputdir=listOfPaths[FolderNum];
	
	if (File.exists(inputdir)) {
    	if (File.isDirectory(inputdir) == 0) {
        	print(input + "is a file, please select only directories containing neuron datasets");
        } else {
        	
        	print("\\Update2:Processing folder "+FolderNum+1+": " + inputdir + " ");
        	
        	input = inputdir + "/";
			
        	File.mkdir(input + "Density_Heatmaps");
        	Heat_out = input + "Density_Heatmaps/";
        	
        	// List Files
        	files = sorted_image_array(input);	

 	    	// interate over each Neuron     	
			for (Neuron=0; Neuron<files.length; Neuron++) {				
				print(" ");
				print("Processing neuron number "+(Neuron+1)+" of "+files.length+".");		
				print(" Measuring density and creating heatmap...");

				//open neuron
				open(input + files[Neuron]);
				rawfilename =  getTitle();
				neuron_out_title = tif_title(rawfilename);
				rename("Raw");

				//get info
				getPixelSize(unit, W, H);
				getDimensions(width, height, ChNum, slices, frames);


			


				
				print(" Image size: "+width+" x "+height+". Resolution: "+W+" microns/pixel.");
				if (W == 1) {
					print("*** Image resolution = 1! Please ensure the scaling information for this image is correct.");
				}
				
				
				// Determine Kernel Size
				KernelSz = round(BoxDim/W);
				if (KernelSz%2 != 0) {
					KernelSz = KernelSz +1;
				}			 
		
				print(" Density width selected: "+BoxDim+"um. Density width used ("+KernelSz+"px): "+(KernelSz*W)+" x "+(KernelSz*W)+"um ("+((KernelSz*W)*(KernelSz*W))+" um2)");

				//Create Kernel
				Kernel = "";
				for (i = 1; i < KernelSz; i++) {
					Kernel = Kernel + "1 "; 
				}		
				KernelLine = Kernel + "\n"; 
				Kernel = ""; 
				for (i = 1; i < KernelSz; i++) {
					Kernel = Kernel + KernelLine; 
				}


				// Detect Soma and create distance map
				run("Duplicate...", "title=Soma");

				makeRectangle(parseInt(width/2-width/6), parseInt(height/2-height/6), parseInt(width/3), parseInt(height/3));
				setBackgroundColor(0, 0, 0);
				run("Clear Outside");
				run("Select None");
				run("Morphological Filters", "operation=Opening element=Square radius=6");
				close("Soma");
				selectWindow("Soma-Opening");
				rename("Soma");
				run("Auto Threshold", "method=Otsu white");
				
				
				run("Duplicate...", "title=Fill");
				run("Select All");
				setForegroundColor(255, 255, 255);
				run("Fill", "slice");
				run("Select None");
				run("Geodesic Distance Map", "marker=Soma mask=Fill distances=[Chessknight (5,7,11)] output=[16 bits] normalize");
				rename("Distance");
				close("Fill");

				
				//Threshold image
				//*** Option for setting threshold Manualy?

				selectWindow("Soma");
				run("16-bit");
				

				selectWindow("Raw");
				run("Auto Threshold", "method=Otsu white");
				imageCalculator("Subtract create", "Raw","Soma");


				// Measure density
				run("Set Measurements...", "area_fraction redirect=None decimal=1");
				
				run("Clear Results");
				selectWindow("Result of Raw");
				run("16-bit");
				run("Divide...", "value=255");
				run("Multiply...", "value=1000");
				run("Convolve...", "text1=["+Kernel+"] normalize");

				rename("Density");
				setMinAndMax(0, 150);
				run("gem");

				selectWindow("Raw");
				run("16-bit");

				selectWindow("Soma");
				run("16-bit");
						
				run("Merge Channels...", "c1=Soma c2=Density c3=Raw c4=Distance create");
				run("Canvas Size...", "width=2048 height=2048 position=Center");
				rename("Merged");
				
				save(Heat_out + neuron_out_title);
				close("*");
			}
        }
	}
	endtime = getTime();
	dif = (endtime-starttime)/1000;
	print("  ");
	print("----------------------------------------------------------------");
	print("Density Analysis Complete. Processing time =", (dif/60), "minutes. ", (dif/files.length), "seconds per image.");
	print("----------------------------------------------------------------");
	
	selectWindow("Log");
	saveAs("txt", input+"/Density_Analysis_Log.txt");
}





function sorted_image_array(folder) {
	sortedimages = getFileList(folder);	
	sortedimages = ImageFilesOnlyArray(sortedimages);		
	sortedimages = Array.sort( sortedimages );
	return sortedimages;
}


function rescale300x300() {
	getDimensions(width, height, channels, slices, frames);
	if (width > height) {
		run("Size...", "width=300 constrain average interpolation=Bilinear");
		run("Canvas Size...", "width=300 height=300 position=Center zero");
	
	} else {
		newwidth = parseInt(width / (height/300));
		run("Size...", "width="+ newwidth +" constrain average interpolation=Bilinear");
		run("Canvas Size...", "width=300 height=300 position=Center zero");	
	}
}
			
        	
function DeleteDir(Dir){
	listDir = getFileList(Dir);
  	//for (j=0; j<listDir.length; j++)
      //print(listDir[j]+": "+File.length(myDir+list[i])+"  "+File. dateLastModified(myDir+list[i]));
 // Delete the files and the directory
	for (j=0; j<listDir.length; j++)
		ok = File.delete(Dir+listDir[j]);
	ok = File.delete(Dir);
	if (File.exists(Dir))
	    print("\\Update13: Unable to delete temporary directory"+ Dir +".");
	else
	    print("\\Update13: Temporary directory "+ Dir +" and files successfully deleted.");
}      

function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg")  || endsWith(arr[i], ".lsm") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}

function NumberedArray(maxnum) {
	//use to create a numbered array from 1 to maxnum, returns numarr
	//e.g. ChArray = NumberedArray(ChNum);
	numarr = newArray(maxnum);
	for (i=0; i<numarr.length; i++){
		numarr[i] = (i+1);
	}
	return numarr;
}

function tif_title(imagename){
	new = split(imagename, "/");
	if (new.length > 1) {
		imagename = new[new.length-1];
	} 
	nl=lengthOf(imagename);
	nl2=nl-3;
	Sub_Title=substring(imagename,0,nl2);
	Sub_Title = replace(Sub_Title, "(", "_");
	Sub_Title = replace(Sub_Title, ")", "_");
	Sub_Title = replace(Sub_Title, "-", "_");
	Sub_Title = replace(Sub_Title, "+", "_");
	Sub_Title = replace(Sub_Title, " ", "_");
	Sub_Title = replace(Sub_Title, "%", "_");
	Sub_Title = replace(Sub_Title, "&", "_");
	Sub_Title=Sub_Title+"tif";
	return Sub_Title;
}

  function append(arr, value) {
     arr2 = newArray(arr.length+1);
     for (i=0; i<arr.length; i++)
        arr2[i] = arr[i];
     arr2[arr.length] = value;
     return arr2;
  }