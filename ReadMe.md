# Job Submission Scripts
The purpose of this repository is to collect scripts useful for submitting jobs at different SNIC clusters using the sbatch. The main submission scripts (\*.sh) are located in the sbatch folder.

## Installation
Clone the script directory to your $SNIC_BACKUP folder (above $HOME on both vera and hebbe)
cd $SNIC_BACKUP
git clone https://github.com/KnutAM/job_submission_scripts.git

## Structure
Apart from the sbatch folder with sbatch scripts, scripts in other scripting languages for more specific job submission tasks are put in the <language> folder. These scripts should be written such that they are independent of the specific cluster used. To facilitate this the environment variable $SNIC_RESOURCE can be used.