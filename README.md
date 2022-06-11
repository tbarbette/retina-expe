# Retina experiments

Note: Before running the experiments, you need to prepare your testbed according to the following guidelines.

## Physical testbed
For the results in the paper, we used our own 100G machines. For most experiments we used a TAP on the Stanford traffic. For the Figure 6 experiment we used 2 machines in a client/server scenario, and a third machine acting as a TAP between those machines.

This repository focus on reproducing that last experiment. We propose to use CloudLab, a publicly available machine provider for reasearch purpose. 

In any cases you need Mellanox NICs (ConnectX 4-7 or BlueField 1-2), hardware support for other NICs is untested.

### CloudLab
The profile used for the machines is available at (https://www.cloudlab.us/p/0a939042304ad84079773db02a1e058e434b7299).

This profile will build a ring of 3 machines. Both client and server use their second interface to mirror packets to the dut running retina. The machine uses Ubuntu 18.04, we recommend doing the same.

## Software

We recommand using Ubuntu 18.04 as this is what we used for all experiments.

### Automatic
We recommand running ./bootstrap.sh on all machines to install all dependencies at once. This will only work with Ubuntu (preferably 18.04).

### Manual

#### Network Performance Framework (NPF) Tool

You can install npf via the following command:

    python3 -m pip install --user npf

Do not forget to add export PATH=$PATH:~/.local/bin to ~/.bashrc or ~/.zshrc. Otherwise, you cannot run npf-compare and npf-run commands.

NPF will look for cluster/ and repo/ in your current working/testie directory. We have included the required repo for our experiments and a sample cluster template, available at experiment/. To setup your cluster, please check the guidelines for our previous paper. Additionally, you can check the NPF documentation at https://npf.readthedocs.io/.

#### Mellanox OFED
#### DPDK
#### Rust
#### Retina

## Running the experiment
Our experiments uses NPF, a tool to manage experiments, run the tests over a cluster and collect results.

### Configuring NPF
NPF needs passwordless sudo access through SSH to all machines.

