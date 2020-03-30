# Neuron Density Analysis

Neuron density and heatmap analysis tools used for sensory neuron analysis in **Integrins protect nociceptive neurons in models of paclitaxel-mediated peripheral sensory neuropathy** 

doi: https://doi.org/10.1101/829655

Step 1 and 2 (Fiji/ImageJ macros):
  - Use 1_Neuron_Density_Heatmap_Creation_Kernel.ijm on a folder containing proprocessed thresholded neuron images
      - For each neuron image, the soma will be detected and removed before density calculations are performed on the remaining arbours using the defined area size (e.g. 50 x 50 microns)
      - A distance map from the soma is also calculated
      - Final output is a image containing 4 channels: 1) soma, 2) density heatmap, 3) neuron, 4) distance map
      - ~ 30 seconds / neuron image (2048 x 2048)
       
  - Use 2_Density_Measurements.ijm on the same folder
    - This step creates a table for each neuron in a subfolder \Density_plots containing mean and standard deviations of density measurements based on distance from the soma (10 micron bins)
    
Step 3 (Python Jupyter Notebook):
- Use 3_Density and convex hull summary on the \Density_Heatmap subfolder
  - This notebook will generate a histogram for each density image and a summary table for the full dataset (convex hull area, peak density, total pixels with density zero)

![Example output](https://github.com/lahammond/Neuron_Density_Analysis/blob/master/Example_output.jpg)
