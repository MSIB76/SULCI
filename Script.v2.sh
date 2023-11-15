#!/bin/bash

# Before you read the template we must say that it is not perfectly Streamlined. It is full of redundancies but it will work.

# For these operations, you need to use the command line from Connectome Workbench software, available at http://www.humanconnectome.org/software/get-connectome-workbench.html
# For resampling Freesurfer native individual data to fs_LR, you will also need to have FreeSurfer installed and have the “wb_shortcuts” bash script, available in Connectome Workbench v1.2.3 and above (also available at https://github.com/Washington-University/wb_shortcuts).
# You will need FreeSurfer CLI.
# You will need to download http://brainvis.wustl.edu/workbench/standard_mesh_atlases.zip, then unzip this file somewhere. The most important files in it are in standard_mesh_atlases/resample_fsaverage. These files are also available in the HCP Pipelines repository (https://github.com/Washington-University/Pipelines) under global/templates/standard_mesh_atlases.
# First, Adjust the list of sulci and the ctab in freesurfer.
# Some files are needed for the average template shall be downloaded from the HCP database. A user account is needed.
# Average brain template surfaces can be downloaded from https://balsa.wustl.edu/reference/pkXDZ
# Prepare the environment. Below is an example. It would be best if you did it according to your preference.
MAIN=path_to_MAIN_folder
FSAVERAGE=path_to_FreeSurfer_fsaverage
WB_PATH=$MAIN/path_to_folder_containg_average_data_from_the_HCP #This is downloaded from the https://balsa.wustl.edu/reference/pkXDZ This will contain average surfaces templates and Myelination map and ROIs.
WORK=$WB_PATH/path_to_folder_where_to_save_files_to_be_used_WORKBENCH_softwares
MESH=$WB_PATH/standard_mesh_atlases/resample_fsaverage #This is downloaded from the HCP.
FS_LR_32K_L=$MESH/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii #This is downloaded from the HCP.
FS_LR_32K_R=$MESH/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii #This is downloaded from the HCP.
SUBJECTS_DIR=path_folder_contating_the_subjects # You need to download the FreeSurfer and the MNI structural data for each subject.
TXT=$MAIN/Path_to_folder_saving_text_files
EXTRA=$MAIN/path_to_folder_savinf_files_for_visualization # Not necessary for the study but might be useful as presentation materials
HCP_S1200=path_to_the_HCP_data/HCP_S1200_Avg_and_Indv #This is downloaded from the https://balsa.wustl.edu/reference/pkXDZ
ATLAS=$WB_PATH/Path_where_you_save_the_atlases # See below where to find them
sulci_names=("sulcus1" "sulcus2" "sulcus3" ... "sulcusN")
Zero=0

# 1. Register the subjects' annot files to the fs_LR space
# 1.1 First, Convert the annot to label.gii
# Start with the left

for sub in $(ls $SUBJECTS_DIR); do
    echo "START: Converting left annotation file of ${sub} to a label file"
    mris_convert \
        --annot \
        $SUBJECTS_DIR/$sub/label/lh.sulci.annot \
        $SUBJECTS_DIR/$sub/surf/lh.white \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii
    
    wb_command \
        -set-structure \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii \
        CORTEX_LEFT
   
    wb_command \
        -set-map-names \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii \
        -map \
        1 \
        ${sub}_LEFT_SULCI
    
    wb_command \
        -gifti-label-add-prefix \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii \
        "L_" \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii
    echo "FINISH: Converting left annotation file of ${sub} to a label file"

# Do for the right side
    echo "START: Converting right annotation file of ${sub} to a label file"
    mris_convert \
        --annot \
        $SUBJECTS_DIR/$sub/label/rh.sulci.annot \
        $SUBJECTS_DIR/$sub/surf/rh.white \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii
    
    wb_command \
        -set-structure \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii \
        CORTEX_RIGHT
   
    wb_command \
        -set-map-names \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii \
        -map \
        1 \
        ${sub}_RIGHT_SULCI
    
    wb_command \
        -gifti-label-add-prefix \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii \
        "R_" \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii
    echo "FINISH: Converting right annotation file of ${sub} to a label file"
done

# 1.2. Resample to the 32K_fs_LR. Details can be found here https://wiki.humanconnectome.org/display/PublicData/HCP+Users+FAQ?preview=%2F63078513%2F91848788%2FResampling-FreeSurfer-HCP_5_8.pdf
# Use the wb_shotcut to prepare prerequisites

for sub in $(ls $SUBJECTS_DIR); do
    cd $SUBJECTS_DIR/${sub}/surf
    mkdir wb
    echo "..... Prepare the Left surfaces for ${sub}"
    wb_shortcuts \
        -freesurfer-resample-prep \
        lh.white \
        lh.pial \
        lh.sphere.reg \
        $FS_LR_32K_L \
        wb/lh.midthickness.surf.gii \
        wb/${sub}.L.midthickness.32k_fs_LR.surf.gii \
        wb/lh.sphere.reg.surf.gii
    
    echo "..... Prepare the Right surfaces for ${sub}"
    wb_shortcuts \
        -freesurfer-resample-prep \
        rh.white \
        rh.pial \
        rh.sphere.reg \
        $FS_LR_32K_R \
        wb/rh.midthickness.surf.gii \
        wb/${sub}.R.midthickness.32k_fs_LR.surf.gii \
        wb/rh.sphere.reg.surf.gii
    cd ~

    echo "..... Resampling the Left SULCI of ${sub}"
    wb_command -label-resample \
        $SUBJECTS_DIR/$sub/label/${sub}.L.sulci.native.label.gii \
        $SUBJECTS_DIR/${sub}/MNINonLinear/Native/${sub}.L.sphere.MSMSulc.native.surf.gii \
        $SUBJECTS_DIR/${sub}/MNINonLinear/fsaverage_LR32k/${sub}.L.sphere.32k_fs_LR.surf.gii \
        BARYCENTRIC \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.L.32k_fs_LR.label.gii

    echo "..... Resampling the Right SULCI of ${sub}"
    wb_command -label-resample \
        $SUBJECTS_DIR/$sub/label/${sub}.R.sulci.native.label.gii \
        $SUBJECTS_DIR/${sub}/MNINonLinear/Native/${sub}.R.sphere.MSMSulc.native.surf.gii \
        $SUBJECTS_DIR/${sub}/MNINonLinear/fsaverage_LR32k/${sub}.R.sphere.32k_fs_LR.surf.gii \
        BARYCENTRIC \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.R.32k_fs_LR.label.gii
done

# 1.3. Create the dense label
for sub in $(ls $SUBJECTS_DIR); do
    echo "..... Creating the dense label of SULCI of ${sub}"
    wb_command \
        -cifti-create-label \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.32k_fs_LR.dlabel.nii \
        -left-label \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.L.32k_fs_LR.label.gii \
        -right-label \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.R.32k_fs_LR.label.gii
    
    echo "..... Setting map name of the dense label of SULCI of ${sub}"
    wb_command \
        -set-map-names \
        $SUBJECTS_DIR/$sub/label/${sub}.SULCI.32k_fs_LR.dlabel.nii \
        -map \
        1 \
        ${sub}_SULCI
done

# 1.4. Merge the dense labels in one file (bash)
for sub in $(ls $SUBJECTS_DIR); do
    MergeSTRING=`echo ${MergeSTRING} -cifti ${SUBJECTS_DIR}/"${sub}"/label/"${sub}".SULCI.32k_fs_LR.dlabel.nii`
    echo ".... adding dlabel file of ${sub}"
    wb_command -cifti-merge \
        $WORK/All.SULCI.32k_fs_LR.dlabel.nii \
        ${MergeSTRING}
done


# 2. Create a probability map and maximum probability map (MPM)
# 2.1. Probability map command
wb_command -cifti-label-probability \
    $WORK/All.SULCI.32k_fs_LR.dlabel.nii \
    $WORK/All.SULCI.probmap.dscalar.nii \
    -exclude-unlabeled

# 2.2. Maximum probability map
# 2.2.1. Set the threshold of MPM to 0.33 (one-third of the sample)
wb_command \
    -metric-math \
    "metric > 0.33" \
    $WORK/All.SULCI.probmap_0.33.L.func.gii \
    -var metric $WORK/All.SULCI.probmap.L.func.gii
wb_command \
    -metric-math \
    "metric > 0.33" \
    $WORK/All.SULCI.probmap_0.33.R.func.gii \
    -var metric $WORK/All.SULCI.probmap.R.func.gii

# 2.2.2. DRAW BORDERS AROUND METRIC ROIS. NEED TO CHECK the border in wb_view and edit if necessary
for i sulcus1 sulcus2 ... sulcusN; do
    for h in L R; do
        wb_command -metric-rois-to-border \
                $MAIN/surf/S1200.${h}.very_inflated_MSMAll.32k_fs_LR.surf.gii \
                $WORK/All.SULCI.probmap_0.33.${h}.func.gii \
                ${h}_${i} \
                $WORK/${h}_${i}.border \
                -column \
                ${h}_${i}
    done
done

# 2.2.3. MERGE BORDER FILES INTO A NEW FILE (run command in bash)
for i sulcus1 sulcus2 ... sulcusN; do
    MergeSTRING_border_L=`echo ${MergeSTRING_border_L} -border $WORK/L_${i}.border`
    MergeSTRING_border_R=`echo ${MergeSTRING_border_R} -border $WORK/R_${i}.border`

    wb_command -border-merge \
        $WORK/L.MPM.border \
        ${MergeSTRING_border_L}
    wb_command -border-merge \
        $WORK/R.MPM.border \
        ${MergeSTRING_border_R}
done

# 2.2.4. MAKE METRIC ROIS FROM BORDERS
for i sulcus1 sulcus2 ... sulcusN; do
    for h in L R; do
        wb_command -border-to-rois \
            $MAIN/surf/S1200.${h}.very_inflated_MSMAll.32k_fs_LR.surf.gii \
            $WORK/$h.MPM.border \
            $WORK/$h.${i}.shape.gii \
            -border ${h}_${i} \
            -include-border
    done
done

# 2.2.5. CREATE DENSE SCALAR FOR EACH BILATERAL ROIS
for i sulcus1 sulcus2 ... sulcusN; do
    wb_command -cifti-create-dense-scalar \
        $WORK/${i}.probmap_0.33.dscalar.nii \
        -left-metric \
        $WORK/L.${i}.shape.gii \
        -roi-left \
        $HCP_S1200/S1200.L.roi_MSMAll.32k_fs_LR.shape.gii \
        -right-metric \
        $WORK/R.${i}.shape.gii \
        -roi-right \
        $HCP_S1200/S1200.R.roi_MSMAll.32k_fs_LR.shape.gii
done

# 2.2.6. MERGE ALL DENSE SCALAR AND SET THEIR MAPS NAMES. Assume your sulci are as below
wb_command -cifti-merge \
    $WORK/probmap_0.33.dscalar.nii \
    -cifti $WORK/sulcus1.probmap_0.33.dscalar.nii \
    -cifti $WORK/sulcus2.probmap_0.33.dscalar.nii \
    -cifti $WORK/sulcus3.probmap_0.33.dscalar.nii \
    -cifti $WORK/sulcus4.probmap_0.33.dscalar.nii # and so on

wb_command -set-map-names \
    $WORK/probmap_0.33.dscalar.nii \
    -map 1 sulcus1 -map 2 sulcus2 -map 3 sulcus3 -map 4 sulcus4 # and so on

# 2.2.7 Create a MPM. Check https://www.mail-archive.com/hcp-users@humanconnectome.org/msg05181.html for more details.

wb_command -cifti-reduce \
    $WORK/probmap_0.33.dscalar.nii \
    MAX \
    $WORK/MAX.dscalar.nii

wb_command -cifti-reduce \
    $WORK/probmap_0.33.dscalar.nii \
    INDEXMAX \
    $WORK/INDEXMAX.dscalar.nii

wb_command -cifti-math \
    "INDEXMAX - (MAX == 0)" \
    $WORK/MPM_0.33.dscalar.nii \
    -var \
    MAX \
    $WORK/MAX.dscalar.nii \
    -var \
    INDEXMAX \
    $WORK/INDEXMAX.dscalar.nii

# Create a txt file with your preference keys and color RGB.
# The label list file must have the
#      following format (2 lines per label):

#      <labelname>
#      <key> <red> <green> <blue> <alpha>
#      ...

wb_command -cifti-label-import \
      $WORK/MPM_0.33.dscalar.nii \
      $WORK/color.txt \
      $WORK/MPM_0.33.dlabel.nii

# 2.2.8. Add prefixes
wb_command -cifti-separate \
        $WORK/MPM_0.33.dlabel.nii \
        COLUMN \
        -label \
        CORTEX_LEFT \
        $WORK/L.MPM_0.33.label.gii \
        -label \
        CORTEX_RIGHT \
        $WORK/R.MPM_0.33.label.gii 
wb_command \
    -gifti-label-add-prefix \
    $WORK/L.MPM_0.33.label.gii \
    "L_" \
    $WORK/L.MPM_0.33.label.gii
wb_command \
    -gifti-label-add-prefix \
    $WORK/R.MPM_0.33.label.gii \
    "R_" \
    $WORK/R.MPM_0.33.label.gii
wb_command -cifti-create-label \
    $WORK/MPM_0.33_new.dlabel.nii \
    -left-label \
    $WORK/L.MPM_0.33.label.gii \
    -roi-left \
    $HCP_S1200/S1200.L.roi_MSMAll.32k_fs_LR.shape.gii \
    -right-label \
    $WORK/R.MPM_0.33.label.gii \
    -roi-right \
    $HCP_S1200/S1200.R.roi_MSMAll.32k_fs_LR.shape.gii

# 3. Create spec file for wb_view
# 3.1 Add surfaces
for surf in flat inflated_MSMAll midthickness_MSMAll pial_MSMAll sphere very_inflated_MSMAll white_MSMAll; do
    wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX_LEFT \
        $WB_PATH/surf/S1200.L.${surf}.32k_fs_LR.surf.gii

    wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX_RIGHT \
        $WB_PATH/surf/S1200.R.${surf}.32k_fs_LR.surf.gii
done

# 3.2 Add the dense labels: SULCI, MPM, and BORDER FILES
wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
        $WORK/All.SULCI.32k_fs_LR.dlabel.nii
wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
       $WORK/All.SULCI.probmap.dscalar.nii
wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
        $WORK/MPM_0.33_new.dlabel.nii
wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
        $WORK/L.MPM.border
wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
        $WORK/R.MPM.border

# 4. Export sulci statistics
# 4.1. Extract the basic statistics from FreeSurfer, e.g., Surface area, GM Volume, Mean Thickness

for subj in $(ls $SUBJECTS_DIR); do
    for hemi in lh rh; do
        echo "Processing $hemi.sulci annotation for $subj"
        mris_anatomical_stats \
        -a \
        $SUBJECTS_DIR/$subj/label/$hemi.sulci.annot \
        -b \
        $subj \
        $hemi >> $TXT/${subj}.${hemi}.sulci.txt
        for label in sulcus1 sulcus2 ... sulcusN; do
            if grep -q "\b$label\b" $TXT/${subj}.${hemi}.sulci.txt; then
                echo ".....Found results for $hemi.$label for $subj"
                grep "\b$label\b" $TXT/${subj}.${hemi}.sulci.txt >> $TXT/$hemi.$label.txt
            else
                echo ".....NO results for $hemi.$label for $subj"
                echo "0    0    0    0    0    0    0    0    0  $label" >> $TXT/$hemi.$label.txt
            fi
        done
    done
done

# 4.2. Extract the mean Myelin index value. For this you need the MyelinMap_BC.native.func.gii file from the MNINonLinear/Native folder
mkdir $TXT/FS_output
for subj in $(ls $SUBJECTS_DIR); do
    L_MYE=$SUBJECTS_DIR/$subj/MNINonLinear/Native/${subj}.L.MyelinMap_BC.native.func.gii
    R_MYE=$SUBJECTS_DIR/$subj/MNINonLinear/Native/${subj}.R.MyelinMap_BC.native.func.gii
    mri_segstats \
        --annot \
        $subj \
        lh \
        sulci \
        --i $L_MYE \
        --sum $TXT/${subj}.lh.MYE.txt
    mri_segstats \
        --annot \
        $subj \
        rh \
        sulci \
        --i $R_MYE \
        --sum $TXT/${subj}.rh.MYE.txt

    for hemi in lh rh; do
        for label in sulcus1 sulcus2 ... sulcusN; do
            if grep -q "\b$label\b" $TXT/${subj}.$hemi.MYE.txt; then
                echo ".....Found MYELIN INDEX results for $hemi.$label for $subj"
                grep "\b$label\b" $TXT/${subj}.$hemi.MYE.txt >> $TXT/FS_output/$hemi.$label.MYE.txt
            else
                echo ".....NO results for MYELIN INDEX results for $hemi.$label for $sub"
                echo "0   0    0    0  $label                            0     0    0    0    0 " >> $TXT/FS_output/$hemi.$label.MYE.txt
            fi
        done
    done
done

# 4.3. Export the results to a single sheet
mkdir $TXT/FS_results
# Directory containing input text files
INPUT_DIR=$TXT/FS_output
# Output directory for extracted columns
OUTPUT_DIR=$TXT/FS_results

# Loop through each text file in the input directory
for hemi in lh rh; do
    for label in sulcus1 sulcus2 ... sulcusN; do

# Extract column 2, 3, and 4 from the mris_annotomical_stats process and group them. Column 2 = Surface area, Column 3 = GM vol, and Column 4 = Mean cortical thickness
        for file in "$INPUT_DIR"/$hemi.$label.txt; do
            echo "Extracting the SA for $hemi.$label"
            awk '{print $2}' "$file" > "$OUTPUT_DIR/$hemi.$label.SA.txt"
            echo "Extracting the GM vol for $hemi.$label"
            awk '{print $3}' "$file" > "$OUTPUT_DIR/$hemi.$label.GM_vol.txt"
            echo "Extracting the CorrThick for $hemi.$label"
            awk '{print $4}' "$file" > "$OUTPUT_DIR/$hemi.$label.CorrThick.txt"
        done

# Extract column 6 from the mri_segstats process and group them. Column 6 = Mean Myelin index
        for file in "$INPUT_DIR"/$hemi.$label.MYE.txt; do
            echo "Extracting the MYE for $hemi.$label"
            awk '{print $6}' "$file" > "$OUTPUT_DIR/$hemi.$label.MYE.txt"
        done
    done 
done


# Create an array to store the file names
touch $OUTPUT_DIR/results.txt
files=()

# Loop through the files and add them to the array
for map in SA GM_vol CorrThick MYE; do
    for label in sulcus1 sulcus2 ... sulcusN; do
        for hemi in lh rh; do
            # Add the file name to the array
            files+=("$OUTPUT_DIR/$hemi.$label.$map.txt")
        done
    done
done

# Add headers to the results file
header=""
for map in SA GM_vol CorrThick MYE; do
    for label in sulcus1 sulcus2 ... sulcusN; do
        for hemi in lh rh; do
            header+="\t${hemi}.${label}.${map}"
        done
    done
done

# Remove "Header" from the header row
header=$(echo -e "$header" | sed 's/Header//')
echo -e "$header" > $OUTPUT_DIR/header.txt

# Loop through the files and paste them to the results file below the headers
for file in "${files[@]}"; do
    # Use paste to concatenate columns horizontally with tabs as delimiter, skipping the first row (header)
    paste -d $'\t' $OUTPUT_DIR/results.txt <(tail -n +1 $file) >> $OUTPUT_DIR/results_tmp.txt
    mv $OUTPUT_DIR/results_tmp.txt $OUTPUT_DIR/results.txt
done

# Store the first line of header.txt in a variable
header=$(head -n 1 $OUTPUT_DIR/header.txt)

# Insert the header line above the first line of results.txt and save the output to a temporary file
sed "1s/^/$header\n/" $OUTPUT_DIR/results.txt > $OUTPUT_DIR/results_tmp.txt

# Move the temporary file back to the original results.txt file
mv $OUTPUT_DIR/results_tmp.txt $OUTPUT_DIR/results.txt

# 4.4. The sulcus depth measure is measured through Matlab. To know how, please refer to https://github.com/cMadan/calcSulc and https://braininformatics.springeropen.com/articles/10.1186/s40708-019-0098-1

# 5. Extra items: For visualization, we can create parcellation and dense scalars for each sulcus in the fsaverage space.

cd $EXTRA
mkdir SmoothedMyelinMap_BC_MSMAll thickness gray_vol dscalar_cuts

for sub in $(ls $SUBJECTS_DIR); do
    cd $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k
    echo "....making directories parcellation ROIs dscalar_roi dscalar_cuts ${sub}"
    mkdir parcellation ROIs dscalar_roi dscalar_cuts
done

# 5.1. Measure the per-vertex cortical volume (gray matter volume)
# Create the metric files
for sub in $(ls $SUBJECTS_DIR); do
    for H in L R; do
        echo "..... START: Creating the ${H}_gray_vol metric file for ${sub}"
        wb_command \
            -surface-wedge-volume \
            $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.${H}.white.32k_fs_LR.surf.gii \
            $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.${H}.pial.32k_fs_LR.surf.gii \
            $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.${H}.gray_vol.32k_fs_LR.shape.gii
        echo "..... FINISH: Creating the ${H}_gray_vol metric file for ${sub}"
    done
done

# Merge both sides metric files to make a dense scalar gray volume dscalar.nii
for sub in $(ls $SUBJECTS_DIR); do
    echo "..... START: Creating the gray_vol dscalar file for ${sub}"
    wb_command \
        -cifti-create-dense-from-template \
        $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.thickness.32k_fs_LR.dscalar.nii \
        $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.gray_vol.32k_fs_LR.dscalar.nii \
        -metric \
        CORTEX_LEFT \
        $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.L.gray_vol.32k_fs_LR.shape.gii \
        -metric \
        CORTEX_RIGHT \
        $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.R.gray_vol.32k_fs_LR.shape.gii
    echo "..... FINISH: Creating the gray_vol dscalar file for ${sub}"
done


# 5.2. Parcellation (The default method is the mean values)
for sub in $(ls $SUBJECTS_DIR); do
    for dense in SmoothedMyelinMap_BC_MSMAll thickness gray_vol; do
        echo "..... START: Parcellating the dense scalar ${dense} of ${sub} using the SULCI dlabel file"
        wb_command \
            -cifti-parcellate \
            $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.${dense}.32k_fs_LR.dscalar.nii \
            $SUBJECTS_DIR/$sub/label/${sub}.SULCI.32k_fs_LR.dlabel.nii \
            COLUMN \
            $EXTRA/${dense}/${sub}.${dense}.ALL_SULCI.32k_fs_LR.pscalar.nii \
            -spatial-weights \
                -left-area-surf $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.L.midthickness.32k_fs_LR.surf.gii \
                -right-area-surf $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.R.midthickness.32k_fs_LR.surf.gii \
                -fill-value 0
        echo "..... FINISH: Parcellating the dense scalar ${dense} of ${sub} using the SULCI dlabel file"

        echo "..... Setting map name for parcellation"
        wb_command \
            -set-map-names \
            $EXTRA/${dense}/${sub}.${dense}.ALL_SULCI.32k_fs_LR.pscalar.nii \
            -map \
            1 \
            ${sub}.${dense}.ALL_SULCI

    done
done

# 5.3. Extract each label from the dense label (dlabel.nii) file.
for sub in $(ls $SUBJECTS_DIR); do
    for roi in sulcus1 sulcus2 ... sulcusN; do
        echo "..... START: Extracting left ${roi} label for ${sub}"
        wb_command \
            -gifti-label-to-roi \
            $SUBJECTS_DIR/$sub/label/${sub}.SULCI.L.32k_fs_LR.label.gii \
            $SUBJECTS_DIR/$sub/label/${sub}.L_${roi}.32k_fs_LR.shape.gii \
            -map \
            1 \
            -name \
            L_$roi
        echo "..... FINISH: Extracting left ${roi} label for ${sub}"

# Do for the right
        echo "..... START: Extracting right ${roi} label for ${sub}"
        wb_command \
            -gifti-label-to-roi \
            $SUBJECTS_DIR/$sub/label/${sub}.SULCI.R.32k_fs_LR.label.gii \
            $SUBJECTS_DIR/$sub/label/${sub}.R_${roi}.32k_fs_LR.shape.gii \
            -map \
            1 \
            -name \
            R_$roi
        echo "..... FINISH: Extracting right ${roi} label for ${sub}"
    done
done

# 5.4. Create scalar for the sulci ROIs
for sub in $(ls $SUBJECTS_DIR); do
    for roi in sulcus1 sulcus2 ... sulcusN; do
# Do for the left
            echo "..... START: Creating ${sub}.L_${roi}.dscalar "
            wb_command \
                -cifti-create-dense-from-template \
                $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.thickness.32k_fs_LR.dscalar.nii \
                $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_roi/${sub}.L_${roi}.dscalar.nii \
                -metric \
                CORTEX_LEFT \
                $SUBJECTS_DIR/$sub/label/${sub}.L_${roi}.32k_fs_LR.shape.gii

# Do for the right
            echo "..... START: Creating ${sub}.R_${roi}.dscalar "
            wb_command \
                -cifti-create-dense-from-template \
                $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.thickness.32k_fs_LR.dscalar.nii \
                $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_roi/${sub}.R_${roi}.dscalar.nii \
                -metric \
                CORTEX_RIGHT \
                $SUBJECTS_DIR/$sub/label/${sub}.R_${roi}.32k_fs_LR.shape.gii
    done
done

# 5.5. Cut the dense in the ROI, good for visualization.
for roi in sulcus1 sulcus2 ... sulcusN; do
    for sub in $(ls $SUBJECTS_DIR); do
        for H in L R; do
            for dense in SmoothedMyelinMap_BC_MSMAll thickness gray_vol; do
                echo "START: Creating a dense parcel for the ${dense} in the ${H}.${roi} for ${sub}"
                wb_command \
                    -cifti-math \
                    "scalar * label" \
                    $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.${H}.${roi}.${dense}.32k_fs_LR.dscalar.nii \
                    -var \
                    scalar \
                    $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/${sub}.${dense}.32k_fs_LR.dscalar.nii \
                    -var \
                    label \
                    $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_roi/${sub}.${H}_${roi}.dscalar.nii 
                echo "FINISH: Creating a dense parcel for the ${dense} in the ${H}.${roi} for ${sub}"
            done
        done
    done
done

# 5.6. Merge the dense of both sides. It would be best if you had a dummy dense map in case one sulcus is absent
# Example of creating a dummy dense scalar file from subject number 1 CS corrThickness file is below
wb_command \
            -cifti-math \
            "left * 0" \
            $MAIN/novalue.L.32k_fs_LR.dscalar.nii \
            -var \
            left \
            $SUBJECTS_DIR/103515/MNINonLinear/fsaverage_LR32k/dscalar_cuts/sub_1.L.CS.corrThickness.32k_fs_LR.dscalar.nii 

wb_command \
            -cifti-math \
            "right * 0" \
            $MAIN/novalue.R.32k_fs_LR.dscalar.nii \
            -var \
            right \
            $SUBJECTS_DIR/103515/MNINonLinear/fsaverage_LR32k/dscalar_cuts/sub_1.R.CS.corrThickness.32k_fs_LR.dscalar.nii 

NOVALUE_L=$MAIN/novalue.L.32k_fs_LR.dscalar.nii
NOVALUE_R=$MAIN/novalue.R.32k_fs_LR.dscalar.nii

# Merge both sides of each dense scalar
for dense in SmoothedMyelinMap_BC_MSMAll thickness gray_vol; do
    for roi in sulcus1 sulcus2 ... sulcusN; do
        for sub in $(ls $SUBJECTS_DIR); do
            echo "START: Merging the left and right ${dense} for ${sub} of the ${roi}"
            
            # Set the variable to the zero-value dscalar file if one side is not present
            if [ ! -f $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.L.${roi}.${dense}.32k_fs_LR.dscalar.nii ]; then
                left="$NOVALUE_L"
            else
                left=$SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.L.${roi}.${dense}.32k_fs_LR.dscalar.nii
            fi
            
            if [ ! -f $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.R.${roi}.${dense}.32k_fs_LR.dscalar.nii ]; then
                right="$NOVALUE_R"
            else
                right=$SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.R.${roi}.${dense}.32k_fs_LR.dscalar.nii
            fi

            wb_command \
                -cifti-math \
                "left + right" \
                $SUBJECTS_DIR/$sub/MNINonLinear/fsaverage_LR32k/dscalar_cuts/${sub}.${roi}.${dense}.32k_fs_LR.dscalar.nii \
                -var \
                left \
                $left \
                -var \
                right \
                $right
                
            echo "FINISH: Merging the left and right ${dense} for ${sub}"
        done
    done
done

# Put each dense scalar of all individuals together in one file. (Bash shell)

for sub in $(ls $SUBJECTS_DIR); do

    if [ -f "${SUBJECTS_DIR}/${sub}/MNINonLinear/fsaverage_LR32k/dscalar_cuts/"${sub}".sulcus1.thickness.32k_fs_LR.dscalar.nii" ]
    then
        echo "START: Merging the rois in the thickness for sulcus1 for ${sub}"
        MergeSTRING1=`echo ${MergeSTRING1} -cifti ${SUBJECTS_DIR}/${sub}/MNINonLinear/fsaverage_LR32k/dscalar_cuts/"${sub}".sulcus1.thickness.32k_fs_LR.dscalar.nii`
        wb_command -cifti-merge $EXTRA/dscalar_cuts/sulcus1.thickness.32k_fs_LR.dscalar.nii ${MergeSTRING1}
    fi

done # Repeat this for each sulcus and then replace the thickness with SmoothedMyelinMap_BC_MSMAll, and gray_vol

# Add the new dense scalars to the spec file
for roi in sulcus1 sulcus2 ... sulcusN; do
    for dense in SmoothedMyelinMap_BC_MSMAll thickness gray_vol; do
    echo "START: Adding ${roi}.${dense} dense parcel to the spec file"
    wb_command -add-to-spec-file \
        $WB_PATH/AVG_dscalar.32k_fs_LR.wb.spec \
        CORTEX \
        $EXTRA/dscalar_cuts/${roi}.${dense}.32k_fs_LR.dscalar.nii
    echo "FINISH: Adding ${roi}.${dense} dense parcel to the spec file"
    done
done
