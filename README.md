# Neuron Density Analysis

Neuron density and heatmap analysis tools used for sensory neuron analysis in **Integrins protect nociceptive neurons in models of paclitaxel-mediated peripheral sensory neuropathy** 
doi: https://doi.org/10.1101/829655

Step 1 and 2 (Fiji/ImageJ macros):
  - Use 1_Neuron_Density_Heatmap_Creation_Kernel.ijm on a folder containing proprocessed thresholded neuron images
      - This step will detect and remove the soma, then calculate the density on the remaining arbours using the selected area size
      - Distance from soma is also calculated
      - Final output is a image containing 4 channels: 1) soma, 2) density heatmap, 3) neuron, 4) distance map
       
  - Use 2_Density_Measurements.ijm on the same folder
    - This step will m
