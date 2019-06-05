# Job Submission Scripts
The purpose of this repository is to collect scripts useful for submitting jobs at different SNIC clusters using the sbatch. The main submission scripts (\*.sh) are located in the folders <cluster>\_sbatch, where <cluster> is the name of the cluster (e.g. hebbe or vera)

## Structure
Apart from the <cluster>\_sbatch folders with sbatch scripts, scripts in other scripting languages for more specific job submission tasks are put in the <language> folder. Note that these scripts should be written such that they are independent of the specific cluster used. To facilitate this the environment variable $SNIC_RESOURCE can be used.

