# Compression Algorithms for Ultrasound Imaging on the Xilinx Artix-7 FPGA

## Introduction
This repository contains all the work produced by Alkinoos Sarioglou (asarioglou@student.ethz.ch) during the semester project in FS2021 at the Integrated Systems Laboratory of ETH Zurich.
More, specifically this includes the code for simulations performed on compression algorithms for ultrasound imaging applications and the RTL code of their implementation in SystemVerilog.


It contains:

- Python code to simulate individual algorithms,
- Python code to simulate combinations of 2 algorithms,
- Python code to simulate combinations of 3 algorithms,
- SystemVerilog code for Decimation-Demodulation,
- SystemVerilog code for Re-quantization,
- SystemVerilog code for Decimation-Demodulation -> Re-quantization,
- SystemVerilog code for LAVA


## Structure of the repository
This repository contains:

- `Simulations` folder which contains the source code for the Python implementation of the compression algorithms of Decimation-Demodulation, Re-quantization, LAVA and their combinations of 2 or 3 algorithms. There are also individual folders where the reconstructed images of each algorithm are saved. 

- `FPGA Implementation` folder which contains the files required to run the simulation of the FPGA implementation of the algorithms. It includes:

    - The `HDL_sources` subfolder which contains the RTL code for all the algorithms and their sub-modules
    - The `HDL_testbenches` subfolder which contains the input stimuli to simulate the algorithms


## Installation and usage

### Installation
To install the library we advise using miniconda package manager and create a virtual environment.
To do it:

- Download the repository to your local PC
- Download the `pybf` repository of Sergei Vostrikov in the same directory as in the previous step by running `git clone git@iis-git.ee.ethz.ch:vsergei/pybf.git`
- Install `miniconda`
- Add additional channels for necessary packages by executing the following commands in terminal
`conda config --append channels plotly`
`conda config --append channels conda-forge`
- Move to the library directory
- Execute the command below to create a virtual environment named `pybf_env` and install all necessary libraries listed in requirements.txt
`conda create --name pybf_env python=3.6 --file requirements.txt`

### Usage
To run the simulations:

- Run a terminal and activate conda environment
`conda activate pybf_env`
- Install and open jupyter notebooks
`conda install -c conda-forge notebook`
`jupyter notebook`
- Open the respective notebook of a compression algorithm and follow the instructions in the comments
to run the algorithms and reconstruct images

Please note that for extracting metrics the MATLAB scripts of https://www.creatis.insa-lyon.fr/Challenge/IEEE_IUS_2016/download were used. The datasets from the same web-page were used for simulation. All the required files can also be found in the `Datasets` directory of the `Simulation` folder. In this project the process followed to extract metrics was the following:

- CREATE THE DATASET AS INDICATED IN THE NOTEBOOKS
- PASS THE PRODUCED DATASET `rf_compressed_dataset.hdf5` TO THE MATLAB FUNCTION `script_reconstruct_images_from_das.m` (INCLUDED IN `Datasets/archive/archive_to_download/code/image_reconstruction_das`)

- THEN USE THE PRODUCED `resolution_distorsion_expe_img_from_rf.hdf5` FILE (INCLUDED IN `Datasets/archive/archive_to_download/reconstructed_image/experiments/`) TO PASS IT TO THE MATLAB FUNCTION `script_evaluation_scores.m` (INCLUDED IN `Datasets/archive/archive_to_download/code/evaluation`) TO EXTRACT RESOLUTION AND CONTRAST

To run the FPGA implementation simulations and reconstruct images:

- Open `VIVADO 2019.1.1` with the command `vivado 2019.1.1`
- Load the `AFE_signal_processing_block.tcl` file to build the project in VIVADO
- Add the required sources, testbenches and stimuli and run the simulation
- The output results are then written in `/AFE_signal_processing_block_compression/HDL_testbenches/testbench_vivoutput_I.txt` and in `/AFE_signal_processing_block_compression/HDL_testbenches/testbench_vivoutput_Q.txt` in hexadecimal representation.

- Open `MATLAB 2019b`
- Navigate to the `/AFE_signal_processing_block_compression/HDL_testbenches` directory
- Run the following commands to transform the hexadecimal numbers to floating-point numbers:
```python
fileID = fopen('testbench_vivoutput_I.txt','r');
```
```python
while ~feof(fileID)
    tline = fgetl(fileID);
    acc_I(i,:) = char(tline(3:5)); // e.g. for hexadecimal numbers of 0xfaa (characters 3-5 are the hexadecimal digits) if more digits e.g. 0xfaaaa then char(tline(3:7))
    i = i+1;
end 
```
```python
q = quantizer('fixed','nearest',[10 9]) // for fixed-point arithmetic of 10-bit with 9 bits fractional part, can change this according to the needs of each project
```
```python
for i = 1:1064960 // depends on number of samples in the file
    A(i) = hex2num(q, acc_I(i,:));
end
```
```python
fileID = fopen('./../../../pybf/compr_algorithms/test_I_all.txt','w'); // save location
formatSpec = '%f\n';
```
```python
for i = 1:1064960 // depends on number of samples in the file
    fprintf(fileID,formatSpec,A(i));
end
```

- Repeat this with `fileID = fopen('testbench_vivoutput_Q.txt','r')` as a first command and the others the same. Only change the output file name in the last command to `test_Q_all`.
- In a Python script, open the `test_I_all.txt` and `test_Q_all.txt` files. Then make an array of complex numbers with the same shape as the loaded arrays from the files. For every sample of the new array make the real parts equal to the loaded numbers from `test_I_all.txt` and the imaginary parts equal to the loaded numbers from `test_Q_all.txt`.
- Then, just reverse the compression operation (if you have performed decimation-demodulation on the FPGA then run interpolation-modulation on Python using the corresponding scripts in the Simulations directory; same for the other compression algorithms) and reconstruct the image.

## Requirements

### General:
- Xilinx Vivado 2019.1
- MATLAB 2019b
- `pybf` repository (https://iis-git.ee.ethz.ch/vsergei/pybf)


## License
All source code is released under Apache v2.0 license unless noted otherwise, please refer to the LICENSE file for details.
Example datasets under tests/data provided under a Creative Commons Attribution 4.0 International License

