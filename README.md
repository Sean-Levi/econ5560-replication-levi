# econ5560-replication-levi



\# ECON 5560 Replication — Sean Levi



This project attempts to reproduce the experimental-auction Tobit portion of Table 6 from:



Wei, Xuan, Hayk Khachatryan, and Alicia Rihn. (2021).

“Estimating willingness-to-pay for neonicotinoid-free plants: Incorporating pro-environmental behavior in hypothetical and non-hypothetical experiments.”

PLOS ONE, 16(5), e0251798.

https://doi.org/10.1371/journal.pone.0251798



The project does not reproduce the paper’s discrete choice analysis or all of its tables and figures.



\## Data



The original second-price auction data were downloaded from Harvard Dataverse on September 16, 2026:

https://doi.org/10.7910/DVN/XCG1N8



The file is stored as data/SPA\_combined\_sample.xls. Its contents are unchanged. Data preparation takes place in R.



\## Software requirements



The pipeline was tested on Windows 11 with R 4.4.2 and readxl 1.4.5. The stats package is included with R. Git is required for cloning the repository.



The run also loaded these namespaces, as recorded by sessionInfo():



\- compiler 4.4.2

\- magrittr 2.0.3

\- cli 3.6.3

\- tools 4.4.2

\- pillar 1.10.0

\- glue 1.8.0

\- tibble 3.2.1

\- cellranger 1.1.0

\- vctrs 0.7.3

\- lifecycle 1.0.5

\- pkgconfig 2.0.3

\- rlang 1.3.0



Installing readxl also installs its required dependencies. The installation command below installs the currently available version; it does not pin the tested versions.



\## How to run



Install R and Git. From a terminal, clone the repository and enter its folder:



```powershell

git clone https://github.com/Sean-Levi/econ5560-replication-levi.git

cd econ5560-replication-levi

```



If you have already cloned the repository, open a terminal inside that folder.



Install readxl once from the R console:



```r

install.packages("readxl", repos = "https://cloud.r-project.org")

```



In Windows PowerShell, create the logs folder and run the pipeline:



```powershell

New-Item -ItemType Directory -Force logs

Rscript run\_all.R \*> logs/run\_log.txt

```



Rscript must be available on your PATH. If PowerShell does not recognize it, find its location by running this in the R console:



```r

file.path(R.home("bin"), "Rscript.exe")

```



Then use the returned path in PowerShell:



```powershell

\& "C:/path/to/Rscript.exe" run\_all.R \*> logs/run\_log.txt

```



Replace the example path with your actual path.



On macOS or Linux, run:



```sh

mkdir -p logs

Rscript run\_all.R > logs/run\_log.txt 2>\&1

```



Run all commands from the repository’s main folder. The script reads the original data, creates plant indicators, estimates the Tobit models, calculates WTP estimates and standard errors, and saves outputs/table6.csv. Its final command prints sessionInfo() to the log.



The LaTeX source is included separately for table formatting. run\_all.R does not compile it or generate a PDF; the automated pipeline’s final table is the CSV file.



\## Files



\- run\_all.R: Master script containing all data preparation, statistical analysis, and CSV export.

\- data/SPA\_combined\_sample.xls: Original second-price auction data.

\- outputs/table6.csv: Generated table of WTP estimates, significance stars, and standard errors.

\- logs/run\_log.txt: Captured run output, including warnings and session information.

\- tobit\_recreation\_table\_092926.tex: Separate LaTeX source used to format the table.

\- README.md: Project description and instructions.



\## Runtime and verification



A full run took approximately 1.65 seconds on my Windows computer. Runtime will vary across computers.



The repository was cloned into a separate folder, its existing outputs were deleted, and the script was run through Rscript. The process returned exit code 0 and regenerated outputs/table6.csv.



\## Limitations and differences from the paper



This implementation uses a pooled Tobit model without individual random effects. It therefore differs from the paper’s random-effects specification and should not be treated as an exact reproduction of its estimates.



Plant controls use the dataset’s numeric plant categories. Specific plant names were not assigned because a dictionary identifying those codes was not available to me.



WTP standard errors use the delta method with numerical gradients and an inverse-Hessian parameter covariance matrix. Significance stars use two-sided normal z-tests: \*\*\* for p < 0.001, \*\* for p < 0.01, and \* for p < 0.05. These calculations are implementation choices rather than verified reproductions of the authors’ procedures.



Observations with missing att\_importance are excluded from the labeling-importance subgroups.



The log includes a warning that readxl was built under R 4.4.3 while the run used R 4.4.2. Windows PowerShell displays this warning with NativeCommandError formatting. The process nevertheless returned exit code 0 and generated the output table.



AI assistance was used to assemble the normal-density likelihood calculation.

