// Neuron Density Heatmap tool
 
// Author: 	Luke Hammond (lh2881@columbia.edu)
// Cellular Imaging | Zuckerman Institute, Columbia University
// Date:	30th January 2019
//	
//	This macro measures the density at each pixel and maps this relative to the soma.
// 			
// 	Usage:
//		1. Run on folder containing cleaned 2d neuron images
//		2. 

// Updates:
// 

// Initialization

run("Options...", "iterations=3 count=1 edm=Overwrite");
//run("Set Measurements...", "mean standard limit redirect=DistanceMap decimal=1");
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=3 count=1 black do=Nothing");
run("Clear Results");

// Select input directories

#@ File[] listOfPaths(label="Select files or folders", style="both")
//Add a message line - 

//tempfolder = "Y:/Luke/_ZI Projects/2019_02 GS Sensory Neuron Density Heatmap Analysis/Full set"
//listOfPaths = newArray(1);
//listOfPaths[0] = tempfolder;

print("\\Clear");
print("\\Update0:Processing neurons...");
setBatchMode(true);


for (FolderNum=0; FolderNum<listOfPaths.length; FolderNum++) {
	starttime = getTime();
	inputdir=listOfPaths[FolderNum];
	
	if (File.exists(inputdir)) {
    	if (File.isDirectory(inputdir) == 0) {
        	print(input + "Is a file, please select only directories containing Neuron datasets");
        } else {
        	
        	print("\\Update2:Processing folder "+FolderNum+1+": " + inputdir + " ");
        	
        	input = inputdir + "/";
			heatmapfolder = input + "Density_Heatmaps/";
        	File.mkdir(input + "Density_Plots");
        	DensityPlotsOut = input + "Density_Plots/";
        	
        	// List Files
        	files = sorted_image_array(heatmapfolder);	

 	    	// interate over each Neuron
        	
			for (Neuron=0; Neuron<files.length; Neuron++) {				

				print("Update:Processing neuron number "+(Neuron+1)+".");
				
				print(" Measuring density...");
				print(heatmapfolder + files[Neuron]);
				open(heatmapfolder + files[Neuron]);
				rawfilename =  getTitle();
				neuron_out_title = tif_title(rawfilename);
				rename("Raw");
				run("Split Channels");
				closewindow("C3-Raw");
				closewindow("C1-Raw");
				selectWindow("C2-Raw");
				rename("Density");
				selectWindow("C4-Raw");
				rename("DistanceMap");

				getPixelSize(unit, W, H);
				
				getDimensions(width, height, ChNum, slices, frames);
		
				tablename1 =  files[Neuron] + "Volume table";
				tablename2 = "[" + tablename1 +"]";
				run("New... ", "name="+tablename2+" type=Table");
				f = tablename2;
				print(f, "\\Headings:Distance from soma (um)\tMean Intensity\tStandard Deviation");

				//make measurements in 10micron intervals
				if (W != 1) {
					print("resolution = "+W +"microns per pixel");
					PxFor10 = parseInt(10/W);
					ActualStep = W*PxFor10;
					print("measurements made in "+ActualStep+" size bins");
				}
				//set measurements
				run("Set Measurements...", "mean standard limit redirect=Density decimal=3");
				
				for(m=0; m<=PxFor10*45; m++) {	
					run("Clear Results");
					//n = round(((m+99)/10));
					//print(m);
					//print(m*W);
					n = m+PxFor10;
					//print("m="+m);
					//print("n="+n);
					
					//measure other image based on Threshold doesnt work need to make selection on mask
					selectWindow("DistanceMap");
					run("Duplicate...", "title=DistanceMap-ROI");
					setThreshold(m, n);
					setOption("BlackBackground", true);
					run("Convert to Mask");
					run("Create Selection");
					selectWindow("Density");
					run("Restore Selection");
					
					run("Measure");
					MeanIntT = getResultString("Mean", 0);
					StdDevIntT = getResultString("StdDev", 0);
					
					print(f,  n*W+ "\t" + MeanIntT + "\t" + StdDevIntT );
					m = n-1;
					close("DistanceMap-ROI");
				}
				selectWindow(tablename1);
				run("Text...", "save=["+ DensityPlotsOut + files[Neuron]+".csv]");
				closewindow(tablename1);
				closewindow("Density");
				closewindow("DistanceMap");
			
			}
        }
	}
	endtime = getTime();
	dif = (endtime-starttime)/1000;
	print("  ");
	print("----------------------------------------------------------------");
	print("Mean Density Measurments Complete. Processing time =", (dif/60), "minutes. ", (dif/files.length), "seconds per image.");
	print("----------------------------------------------------------------");
	selectWindow("Log");
	saveAs("txt", input+"/Mean_Density_Measurements_Complete.txt");
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

function closewindow(windowname) {
	if (isOpen(windowname)) { 
      		 selectWindow(windowname); 
       		run("Close"); 
  		} 

  		
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