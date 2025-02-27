#!/bin/bash

#Alli Hickman
#ahickman@epicypher.com
#Last Updated: 6/7/2024

#version notes
#v2 update: added functionality to allow for input of custom bed files

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo ""
   echo "Bash script that generates side-by-side deepTOOLS heatmaps of samples described in input file. Recommend 6 samples max."
   echo "Run in 4_deepTOOLS/b20chase directory"
   echo
   echo "Syntax: sh side-by-side-deeptools_v2.sh [-h|i|r|b|s]"
   echo "options:"
   echo "-h      Print this Help."
   echo "-i      Name of input file." 
   echo "           One column that designates the bigwigs you'd like to include. "
   echo "           Order of samples in heatmap is determined by order of samples in input file."
   echo "           File is required."
   echo "-r      Region of heatmaps. Options are: 'start_site', 'region', or 'both'. Required."
   echo "-b      Tab-delimited bed file containing regions in which to compare bigwigs. Three columns: chrom, start, stop. No header. Required"
   echo "-s      The input file's line number of the sample you'd like to sort the heatmap rows by. Required."
   echo "           Example: First sample would be -s 1."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hi:r:b:s:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter a name
         inputFile=$OPTARG;;
      r) #enter region
         region=$OPTARG;;
      b) #if not using genome reference files, specify custom input file
         custom_input=$OPTARG;;
      s) #set sample# to sort by
         sortSample=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

#make output name, string for bw file names, and string for bw labels
NUM_FILES=`expr $(wc -l < ${inputFile})`
outputFile=''
labels=''
bigwigInput=''

for i in $(seq 1 ${NUM_FILES}); # loops through all filenames in $FILES
do
    fileLabel=$(sed -n "${i}p" ${inputFile} | cut -f1 -d'.')
    outputFile="$outputFile$fileLabel"
    labels="$labels$fileLabel"

    bigwigName=$(sed -n "${i}p" ${inputFile} | cut -f1)
    bigwigInput="$bigwigInput$bigwigName"

    if [ $i != $NUM_FILES ]
    then
        outputFile="${outputFile}-"
        labels="${labels} "
        bigwigInput="${bigwigInput} "
    fi

done

#variables for custom bed file
refFile="$custom_input"
shortRefFile="${custom_input%.bed}"
lines=$(wc -l $custom_input | cut -f1 -d' ')
geneCount="$lines regions"
start="RegionStartSite"
body="${custom_input%.bed}-Region"
body_start="Region Start"
body_end="Region End"

mkdir $shortRefFile
#making TSS and Gene heatmaps or just one?
if [ "$region" = "start_site" ] || [ "$region" = "both" ];
then
## TSS +/2kb, bin 20bp, sort by row mean ###
echo ''
echo "computeMatrix: $start as Reference Point"
computeMatrix  reference-point  --regionsFileName $refFile  --scoreFileName $bigwigInput --outFileName $shortRefFile/${outputFile}-$start.matrix.gz --referencePoint TSS  --beforeRegionStartLength 2000  --afterRegionStartLength 2000  --binSize 20  --sortRegions keep  --sortUsing mean --averageTypeBins mean  --missingDataAsZero  --scale 1  --numberOfProcessors 1 --samplesLabel $labels

echo "plotHeatmap: $start as Reference Point"
plotHeatmap  --matrixFile $shortRefFile/${outputFile}-$start.matrix.gz  --outFileName $shortRefFile/${outputFile}.$start.sortSample${sortSample}.heatmap.png --sortUsingSamples $sortSample --interpolationMethod  auto  --dpi 150 --averageTypeSummaryPlot mean  --colorList "#306FBA,#FCEC92,#E93323"   --missingDataColor "blue"  --alpha 1.0  --colorNumber 256  --heatmapHeight 20  --heatmapWidth 10  --whatToShow "plot, heatmap and colorbar"  --boxAroundHeatmaps "yes"  --refPointLabel "$body_start"  --labelRotation 0  --regionsLabel "$geneCount" --yAxisLabel "Mean signal (RPKM)"  --legendLocation "best"  --zMax auto --xAxisLabel ""
fi

#making TSS and Gene heatmaps or just one?
if [ "$region" = "region" ] || [ "$region" = "both" ];
then
echo ''
echo "computeMatrix: $body as Reference Point"
computeMatrix scale-regions --regionsFileName $refFile --outFileName $shortRefFile/${outputFile}-$body.matrix.gz --scoreFileName $bigwigInput --beforeRegionStartLength 2000 --afterRegionStartLength 2000 --regionBodyLength 4000 --binSize 20 --sortUsingSamples $sortSample --missingDataAsZero --numberOfProcessors 1 --startLabel "Start" --endLabel "End" --unscaled5prime 0 --unscaled3prime 0 --samplesLabel $labels

echo "plotHeatmap: $body as Reference Point"
plotHeatmap --matrixFile $shortRefFile/${outputFile}-$body.matrix.gz --outFileName $shortRefFile/${outputFile}.$body.sortSample${sortSample}.heatmap.png --interpolationMethod auto  --dpi 150  --sortUsingSamples $sortSample  --averageTypeSummaryPlot mean  --missingDataColor "blue"  --colorList "#306FBA,#FCEC92,#E93323"  --alpha 1.0  --colorNumber 256  --heatmapHeight 20  --heatmapWidth 10  --whatToShow "plot, heatmap and colorbar"  --boxAroundHeatmaps "yes"  --startLabel "${body_start}"  --endLabel "${body_end}"  --labelRotation 0  --regionsLabel "$geneCount"  --yAxisLabel "Mean signal (RPKM)"  --legendLocation "best" --zMax auto --xAxisLabel ""

fi
